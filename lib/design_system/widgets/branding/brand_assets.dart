import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Brand asset paths, centralized.
/// Sumber: D:\Hermes_Storage\void_scriptor_assets (360+ file).
class BrandAssets {
  BrandAssets._();

  // ── Kategori ─────────────────────────────────────────────
  static const String aiTech = 'assets/brands/ai_tech';
  static const String apps = 'assets/brands/apps';
  static const String brandCanva = 'assets/brands/apps/canva.svg';
  static const String designTools = 'assets/brands/design_tools';
  static const String webPlatforms = 'assets/brands/web_platforms';
  static const String designAutodesk =
      'assets/brands/design_tools/autodesk_logo.webp';

  // -- Web publishing platforms (untuk website Void Scriptor) --
  static const String webWix = 'assets/brands/web_platforms/wix.webp';
  static const String webSquarespace =
      'assets/brands/web_platforms/squarespace.webp';
  static const String webWeebly = 'assets/brands/web_platforms/weebly.webp';
  static const String ecommerce = 'assets/brands/ecommerce';
  static const String fileFormats = 'assets/brands/file_formats';
  static const String flags = 'assets/brands/flags';
  static const String paymentMethods = 'assets/brands/payment_methods';
  static const String platforms = 'assets/brands/platforms';
  static const String socialMedia = 'assets/brands/social_media';
  static const String tech = 'assets/brands/tech';

  // ── Path spesifik (untuk language switcher & integrasi umum) ──
  static const String flagIndonesia = '$flags/indonesia.svg';
  static const String flagEnglish = '$flags/united_states.svg';
  static const String flagBritain = '$flags/united_kingdom.svg';
  static const String flagJapan = '$flags/japan.svg';
  static const String flagKorea = '$flags/south_korea.svg';
  static const String flagChina = '$flags/china.svg';

  // Payment populer
  static const String paymentQris = '$paymentMethods/qris_0.webp';
  static const String paymentDana = '$paymentMethods/dana.webp';
  static const String paymentGoPay = '$paymentMethods/gopay.svg';
  static const String paymentOvo = '$paymentMethods/ovo.svg';
  static const String paymentSeaBank = '$paymentMethods/seabank.webp';
  static const String paymentMandiri = '$paymentMethods/bank_mandiri.webp';
  static const String paymentJago = '$paymentMethods/bank_jago.webp';
  static const String paymentBni = '$paymentMethods/bni.svg';
  static const String paymentVisa = '$paymentMethods/visa.svg';

  // ── Void Scriptor ──
  static const String voidScriptorEmblem =
      'assets/brands/own_brands/void_scriptor/void_scriptor_emblem_transparent.png';
  static const String voidScriptorEmblemPurple =
      'assets/brands/own_brands/void_scriptor/void_scriptor_emblem_purple.png';
  static const String voidScriptorEmblemWhite =
      'assets/brands/own_brands/void_scriptor/void_scriptor_emblem_white.png';
  static const String voidScriptorInk =
      'assets/brands/own_brands/void_scriptor/void_scriptor_emblem_ink.png';
  static const String voidScriptorIcon16 =
      'assets/brands/own_brands/void_scriptor/void_scriptor_icon_16.png';
  static const String voidScriptorIcon32 =
      'assets/brands/own_brands/void_scriptor/void_scriptor_icon_32.png';
  static const String voidScriptorIcon64 =
      'assets/brands/own_brands/void_scriptor/void_scriptor_icon_64.png';
  static const String voidScriptorIcon128 =
      'assets/brands/own_brands/void_scriptor/void_scriptor_icon_128.png';
  static const String voidScriptorIcon256 =
      'assets/brands/own_brands/void_scriptor/void_scriptor_icon_256.png';
  static const String voidScriptorIcon512 =
      'assets/brands/own_brands/void_scriptor/void_scriptor_icon_512.png';
  static const String voidScriptorLockupDark =
      'assets/brands/own_brands/void_scriptor/void_scriptor_lockup_dark.png';
  // ── Void Scriptor SVG ──
  // ── Void Scriptor SVG (vector traces) ──
  static const String voidScriptorLockupLight =
      'assets/brands/own_brands/void_scriptor/void_scriptor_lockup_light.png';
  // -- Void Scriptor SVG (scalable, from vtracer) --
  static const String voidScriptorSvg =
      'assets/brands/own_brands/void_scriptor/void_scriptor_emblem.svg';
  static const String voidScriptorSvgColor =
      'assets/brands/own_brands/void_scriptor/void_scriptor_emblem_color.svg';
  static const String voidScriptorSvgPurple =
      'assets/brands/own_brands/void_scriptor/void_scriptor_emblem_purple.svg';
  static const String voidScriptorSvgWhite =
      'assets/brands/own_brands/void_scriptor/void_scriptor_emblem_white.svg';
  static const String voidScriptorSvgInk =
      'assets/brands/own_brands/void_scriptor/void_scriptor_emblem_ink.svg';
  static const String paymentShopeepay = '$paymentMethods/shopeepay.webp';

  // AI & Teknologi
  static const String aiGemini = '$aiTech/google_gemini.svg';
  static const String aiDeepSeek = '$aiTech/deepseek.svg';
  static const String aiOpenai = '$aiTech/openai.svg';
  static const String aiMidjourney = '$aiTech/midjourney.svg';
  static const String aiClaude = '$aiTech/claude_ai_0.webp';
  static const String techFlutter = '$tech/flutter_0.webp';
  static const String techDart = '$tech/dart_0.webp';
}

/// Widget untuk menampilkan logo brand dari assets.
/// Mendukung SVG, PNG, dan WebP secara otomatis berdasarkan ekstensi.
/// Fallback: ikon [fallbackIcon] jika aset tidak ditemukan/error.
class BrandLogo extends StatelessWidget {
  final String assetPath;
  final double width;
  final double? height;
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final Color? color; // Tint untuk SVG (opsional)
  final BoxFit fit;

  const BrandLogo({
    super.key,
    required this.assetPath,
    this.width = 32,
    this.height,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.fallbackColor,
    this.color,
    this.fit = BoxFit.contain,
  });

  bool get _isSvg => assetPath.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Icon(
      fallbackIcon,
      size: width,
      color: fallbackColor ?? Theme.of(context).colorScheme.outline,
    );

    if (_isSvg) {
      return SvgPicture.asset(
        assetPath,
        width: width,
        height: height ?? width,
        fit: fit,
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        placeholderBuilder: (_) => fallback,
      );
    }

    return Image.asset(
      assetPath,
      width: width,
      height: height ?? width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
