[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$ArtifactDirectory,

  [Parameter(Mandatory = $true)]
  [string]$CertificateThumbprint,

  [Parameter(Mandatory = $true)]
  [string]$ExpectedSubject,

  [Parameter(Mandatory = $true)]
  [string]$SourceRevision,

  [string]$Version = '1.2.0-rc.1',
  [string]$OutputManifest = 'build/release-metadata/windows-signed-rc-manifest.json',
  [string]$SignToolPath,
  [string]$TimestampUrl,
  [switch]$AllowSelfSignedLocal
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-Sha256([string]$Path) {
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

$thumbprint = $CertificateThumbprint.Replace(' ', '').ToUpperInvariant()
if ($thumbprint -notmatch '^[A-F0-9]{40}$') {
  throw 'CertificateThumbprint must contain exactly 40 hexadecimal characters.'
}
if ([string]::IsNullOrWhiteSpace($ExpectedSubject)) {
  throw 'ExpectedSubject is required so a different certificate cannot be selected silently.'
}
if ([string]::IsNullOrWhiteSpace($SourceRevision)) {
  throw 'SourceRevision is required for signed artifact provenance.'
}
if (-not $AllowSelfSignedLocal -and [string]::IsNullOrWhiteSpace($TimestampUrl)) {
  throw 'A trusted release run requires TimestampUrl. Use -AllowSelfSignedLocal only for local verification.'
}

$certificatePath = "Cert:\CurrentUser\My\$thumbprint"
$certificate = Get-Item -LiteralPath $certificatePath -ErrorAction SilentlyContinue
if ($null -eq $certificate) {
  throw "Certificate $thumbprint was not found in Cert:\CurrentUser\My."
}
if (-not $certificate.HasPrivateKey) {
  throw "Certificate $thumbprint has no accessible private key."
}
if ($certificate.Subject -ne $ExpectedSubject) {
  throw "Certificate subject mismatch. Expected '$ExpectedSubject', found '$($certificate.Subject)'."
}
$now = Get-Date
if ($now -lt $certificate.NotBefore -or $now -gt $certificate.NotAfter) {
  throw "Certificate $thumbprint is outside its validity period."
}
$eku = @($certificate.EnhancedKeyUsageList | ForEach-Object { $_.ObjectId.Value })
if ($eku.Count -gt 0 -and $eku -notcontains '1.3.6.1.5.5.7.3.3') {
  throw "Certificate $thumbprint is not valid for code signing."
}

$artifactRoot = (Resolve-Path -LiteralPath $ArtifactDirectory).Path
$files = @(
  Get-ChildItem -LiteralPath $artifactRoot -File -Recurse |
    Where-Object { $_.Extension -in @('.exe', '.dll') } |
    Sort-Object FullName
)
if ($files.Count -eq 0) {
  throw "No executable or DLL artifacts were found under $artifactRoot."
}

if ([string]::IsNullOrWhiteSpace($SignToolPath)) {
  $kitsRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
  $resolvedSignTool = Get-ChildItem -LiteralPath $kitsRoot -Filter signtool.exe -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match '\\x64\\signtool\.exe$' } |
    Sort-Object FullName -Descending |
    Select-Object -First 1
  if ($null -eq $resolvedSignTool) {
    throw 'signtool.exe was not found in the Windows SDK.'
  }
  $SignToolPath = $resolvedSignTool.FullName
}
if (-not (Test-Path -LiteralPath $SignToolPath -PathType Leaf)) {
  throw "SignToolPath does not exist: $SignToolPath"
}

foreach ($file in $files) {
  $arguments = @(
    'sign', '/fd', 'SHA256', '/sha1', $thumbprint, '/s', 'My',
    '/d', "Void Scriptor $Version", $file.FullName
  )
  if (-not [string]::IsNullOrWhiteSpace($TimestampUrl)) {
    $arguments = @(
      'sign', '/fd', 'SHA256', '/sha1', $thumbprint, '/s', 'My',
      '/d', "Void Scriptor $Version", '/tr', $TimestampUrl, '/td', 'SHA256',
      $file.FullName
    )
  }
  & $SignToolPath @arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Signing failed for $($file.FullName) with exit code $LASTEXITCODE."
  }
  & $SignToolPath verify /pa /all $file.FullName
  if ($LASTEXITCODE -ne 0) {
    throw "Signature verification failed for $($file.FullName) with exit code $LASTEXITCODE."
  }
}

$artifactEvidence = @(
  foreach ($file in $files) {
    $signature = Get-AuthenticodeSignature -LiteralPath $file.FullName
    if ($signature.Status -ne 'Valid') {
      throw "Authenticode status for $($file.FullName) is $($signature.Status), expected Valid."
    }
    $relativePath = $file.FullName.Substring($artifactRoot.TrimEnd('\').Length).TrimStart('\')
    [ordered]@{
      path = $relativePath.Replace('\', '/')
      size = $file.Length
      sha256 = Get-Sha256 $file.FullName
      authenticode_status = $signature.Status.ToString()
      signer_thumbprint = $signature.SignerCertificate.Thumbprint
    }
  }
)

$trustScope = if ($AllowSelfSignedLocal) {
  'CurrentUser Root store only'
} else {
  'Public trust chain; verified locally'
}
$status = if ($AllowSelfSignedLocal) {
  'SELF_SIGNED_LOCAL_VERIFIED'
} else {
  'SIGNED_AND_VERIFIED'
}
$timestampStatus = if ([string]::IsNullOrWhiteSpace($TimestampUrl)) {
  'NOT_TIMESTAMPED_LOCAL_ONLY'
} else {
  'RFC3161_TIMESTAMP_REQUESTED_AND_VERIFIED'
}
$manifest = [ordered]@{
  format = 'void-scriptor-windows-signed-rc-v1'
  version = $Version
  source_revision = $SourceRevision
  artifact_directory = $ArtifactDirectory.Replace('\', '/')
  signing = [ordered]@{
    status = $status
    algorithm = 'Authenticode-SHA256'
    certificate_subject = $certificate.Subject
    certificate_thumbprint = $thumbprint
    certificate_not_before = $certificate.NotBefore.ToUniversalTime().ToString('o')
    certificate_not_after = $certificate.NotAfter.ToUniversalTime().ToString('o')
    trust_scope = $trustScope
    timestamp_status = $timestampStatus
    verification_exit_code = 0
    key_material = 'NOT_PRESENT_IN_REPOSITORY'
  }
  artifacts = $artifactEvidence
}

$manifestPath = [IO.Path]::GetFullPath($OutputManifest, (Get-Location).Path)
$manifestDirectory = Split-Path -Parent $manifestPath
New-Item -ItemType Directory -Path $manifestDirectory -Force | Out-Null
$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
$manifestJson = ($manifest | ConvertTo-Json -Depth 8) + "`n"
[IO.File]::WriteAllText($manifestPath, $manifestJson, $utf8WithoutBom)
Write-Output "SIGNED_RC_MANIFEST=$manifestPath"
