import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Brand asset paths, centralized.
/// Sumber: D:\Hermes_Storage\void_scriptor_assets (360+ file).
class BrandAssets {
  BrandAssets._();

  // ── Kategori ─────────────────────────────────────────────
  static const String aiTech = 'assets/brands/ai_tech';
  static const String apps = 'assets/brands/apps';
  static const String designTools = 'assets/brands/design_tools';
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
