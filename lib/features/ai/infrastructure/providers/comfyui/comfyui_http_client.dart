import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../domain/ai_provider.dart';
import 'comfyui_provider.dart';

class HttpComfyUiClient implements ComfyUiClient {
  HttpComfyUiClient({
    http.Client? client,
    Directory? outputDirectory,
    this.pollInterval = const Duration(milliseconds: 500),
    this.pollTimeout = const Duration(minutes: 5),
  }) : client = client ?? http.Client(),
       _ownsClient = client == null,
       outputDirectory =
           outputDirectory ??
           Directory('${Directory.systemTemp.path}/void_ai_out');

  final http.Client client;
  final bool _ownsClient;
  final Directory outputDirectory;
  final Duration pollInterval;
  final Duration pollTimeout;

  @override
  Future<List<AiModelInfo>> listModels({required String baseUrl}) async =>
      const [];

  @override
  Future<AiGenerationResult> generate({
    required String baseUrl,
    required AiGenerationRequest request,
  }) async {
    final customWorkflow = request.parameters['workflow'];
    final workflow = customWorkflow is Map<String, Object?>
        ? customWorkflow
        : _defaultImageWorkflow(request);
    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final response = await client.post(
      Uri.parse('$root/prompt'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': workflow}),
    );
    _check(response, operation: 'prompt submission');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final promptId = body['prompt_id'] as String?;
    if (promptId == null || promptId.isEmpty) {
      throw StateError('ComfyUI response did not contain prompt_id.');
    }

    final images = await _waitForImages(root, promptId);
    await outputDirectory.create(recursive: true);
    final outputs = <AiGeneratedOutput>[];
    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      final filename = image['filename'] as String?;
      if (filename == null || filename.isEmpty) continue;
      final uri = Uri.parse('$root/view').replace(
        queryParameters: {
          'filename': filename,
          'subfolder': image['subfolder'] as String? ?? '',
          'type': image['type'] as String? ?? 'output',
        },
      );
      final download = await client.get(uri);
      _check(download, operation: 'image download');
      final extension = _extension(filename);
      final file = File(
        '${outputDirectory.path}/${request.jobId}_${index + 1}.$extension',
      );
      await file.writeAsBytes(download.bodyBytes, flush: true);
      outputs.add(
        AiGeneratedOutput(
          type: AiOutputType.image,
          localPath: file.path,
          mimeType: _mimeType(extension),
        ),
      );
    }
    if (outputs.isEmpty) {
      throw StateError('ComfyUI completed without image outputs.');
    }
    return AiGenerationResult(providerRequestId: promptId, outputs: outputs);
  }

  Map<String, Object?> _defaultImageWorkflow(AiGenerationRequest request) {
    final parameters = request.parameters;
    final seed = parameters['seed'] is int
        ? parameters['seed'] as int
        : DateTime.now().microsecondsSinceEpoch % 0x7fffffff;
    final width = parameters['width'] is int
        ? parameters['width'] as int
        : 1024;
    final height = parameters['height'] is int
        ? parameters['height'] as int
        : 1024;
    final steps = parameters['steps'] is int ? parameters['steps'] as int : 20;
    final cfg = parameters['cfg'] is num
        ? (parameters['cfg'] as num).toDouble()
        : 7.0;
    final checkpoint = request.model ?? 'sd_xl_base_1.0.safetensors';
    return <String, Object?>{
      '1': {
        'class_type': 'CheckpointLoaderSimple',
        'inputs': {'ckpt_name': checkpoint},
      },
      '2': {
        'class_type': 'CLIPTextEncode',
        'inputs': {
          'text': request.prompt,
          'clip': ['1', 1],
        },
      },
      '3': {
        'class_type': 'CLIPTextEncode',
        'inputs': {
          'text': request.negativePrompt ?? '',
          'clip': ['1', 1],
        },
      },
      '4': {
        'class_type': 'EmptyLatentImage',
        'inputs': {'width': width, 'height': height, 'batch_size': 1},
      },
      '5': {
        'class_type': 'KSampler',
        'inputs': {
          'seed': seed,
          'steps': steps,
          'cfg': cfg,
          'sampler_name': 'euler',
          'scheduler': 'normal',
          'denoise': 1.0,
          'model': ['1', 0],
          'positive': ['2', 0],
          'negative': ['3', 0],
          'latent_image': ['4', 0],
        },
      },
      '6': {
        'class_type': 'VAEDecode',
        'inputs': {
          'samples': ['5', 0],
          'vae': ['1', 2],
        },
      },
      '7': {
        'class_type': 'SaveImage',
        'inputs': {
          'filename_prefix': 'VoidScriptor',
          'images': ['6', 0],
        },
      },
    };
  }

  Future<List<Map<String, dynamic>>> _waitForImages(
    String root,
    String promptId,
  ) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < pollTimeout) {
      final response = await client.get(Uri.parse('$root/history/$promptId'));
      _check(response, operation: 'history polling');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final history = body[promptId];
      if (history is Map<String, dynamic>) {
        final outputs = history['outputs'];
        if (outputs is Map<String, dynamic>) {
          final images = <Map<String, dynamic>>[];
          for (final node in outputs.values) {
            if (node is! Map<String, dynamic>) continue;
            final nodeImages = node['images'];
            if (nodeImages is! List<dynamic>) continue;
            images.addAll(nodeImages.whereType<Map<String, dynamic>>());
          }
          if (images.isNotEmpty) return images;
        }
      }
      await Future<void>.delayed(pollInterval);
    }
    throw TimeoutException(
      'ComfyUI generation $promptId exceeded $pollTimeout.',
    );
  }

  @override
  Future<void> cancel({
    required String baseUrl,
    required String requestId,
  }) async {
    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final response = await client.post(
      Uri.parse('$root/interrupt'),
      headers: {'Content-Type': 'application/json'},
      body: '{}',
    );
    _check(response, operation: 'cancellation');
  }

  void _check(http.Response response, {required String operation}) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'ComfyUI $operation failed with HTTP ${response.statusCode}.',
      );
    }
  }

  String _extension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot < 0 || dot == filename.length - 1) return 'png';
    return filename.substring(dot + 1).toLowerCase();
  }

  String _mimeType(String extension) => switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    _ => 'image/png',
  };

  void close() {
    if (_ownsClient) client.close();
  }
}
