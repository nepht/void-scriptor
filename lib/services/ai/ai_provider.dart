// AI Provider — v1.0.0
// LocalAiProvider generates SVG output at %TEMP%/void_ai_out.
// AiPanel aiRefresh uses event bus for live feedback.

import 'dart:io';
import 'package:path/path.dart' as p;

class AiGenerationRequest {
  final String prompt;
  final String mode; // character, world, story, timeline
  final Map<String, dynamic> context;

  AiGenerationRequest({
    required this.prompt,
    required this.mode,
    this.context = const {},
  });
}

class AiGenerationResult {
  final String content;
  final String format; // svg, text, json
  final String outputPath;

  AiGenerationResult({
    required this.content,
    required this.format,
    required this.outputPath,
  });
}

class LocalAiProvider {
  final Directory _outputDir;

  LocalAiProvider() : _outputDir = Directory(p.join(Directory.systemTemp.path, 'void_ai_out'));

  Future<AiGenerationResult> generate(AiGenerationRequest request) async {
    await _outputDir.create(recursive: true);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = p.join(_outputDir.path, 'ai_output_$timestamp.svg');

    // Generate a placeholder SVG (real AI integration in v1.1.0)
    final svgContent = _generatePlaceholderSvg(request.prompt);

    final file = File(outputPath);
    await file.writeAsString(svgContent);

    return AiGenerationResult(
      content: svgContent,
      format: 'svg',
      outputPath: outputPath,
    );
  }

  String _generatePlaceholderSvg(String prompt) {
    return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 400">
  <rect width="800" height="400" fill="#1A1025"/>
  <text x="400" y="200" text-anchor="middle" fill="#9B59B6" font-size="18" font-family="monospace">AI Output: $prompt</text>
  <circle cx="400" cy="250" r="50" fill="none" stroke="#6C3483" stroke-width="2"/>
  <circle cx="400" cy="250" r="80" fill="none" stroke="#D4A017" stroke-width="1" opacity="0.5"/>
</svg>''';
  }
}
