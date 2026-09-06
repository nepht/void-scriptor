import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/comfyui/comfyui_http_client.dart';

void main() {
  test(
    'ComfyUI client waits for history and downloads generated image',
    () async {
      final outputDirectory = await Directory.systemTemp.createTemp(
        'comfyui-output-',
      );
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var historyCalls = 0;
      const pngBytes = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
      server.listen((request) async {
        if (request.method == 'POST' && request.uri.path == '/prompt') {
          final payload =
              jsonDecode(await utf8.decoder.bind(request).join())
                  as Map<String, dynamic>;
          final workflow = payload['prompt'] as Map<String, dynamic>;
          expect(workflow.values, hasLength(7));
          expect(
            workflow.values.whereType<Map<String, dynamic>>().any(
              (node) =>
                  node['class_type'] == 'CLIPTextEncode' &&
                  (node['inputs'] as Map<String, dynamic>)['text'] ==
                      'A void city',
            ),
            isTrue,
          );
          expect(
            workflow.values.whereType<Map<String, dynamic>>().map(
              (node) => node['class_type'],
            ),
            containsAll([
              'CheckpointLoaderSimple',
              'KSampler',
              'VAEDecode',
              'SaveImage',
            ]),
          );
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({'prompt_id': 'prompt-1'}));
        } else if (request.method == 'GET' &&
            request.uri.path == '/history/prompt-1') {
          historyCalls++;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            historyCalls == 1
                ? '{}'
                : jsonEncode({
                    'prompt-1': {
                      'outputs': {
                        '9': {
                          'images': [
                            {
                              'filename': 'result.png',
                              'subfolder': 'final',
                              'type': 'output',
                            },
                          ],
                        },
                      },
                    },
                  }),
          );
        } else if (request.method == 'GET' && request.uri.path == '/view') {
          expect(request.uri.queryParameters['filename'], 'result.png');
          expect(request.uri.queryParameters['subfolder'], 'final');
          request.response.headers.contentType = ContentType('image', 'png');
          request.response.add(pngBytes);
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });
      addTearDown(() async {
        await server.close(force: true);
        if (await outputDirectory.exists()) {
          await outputDirectory.delete(recursive: true);
        }
      });
      final client = HttpComfyUiClient(
        outputDirectory: outputDirectory,
        pollInterval: const Duration(milliseconds: 10),
        pollTimeout: const Duration(seconds: 2),
      );
      addTearDown(client.close);

      final result = await client.generate(
        baseUrl: 'http://${server.address.host}:${server.port}',
        request: const AiGenerationRequest(
          jobId: 'job-1',
          prompt: 'A void city',
          target: PromptTarget.image,
        ),
      );

      expect(result.outputs, hasLength(1));
      expect(result.outputs.single.type, AiOutputType.image);
      final localPath = result.outputs.single.localPath;
      expect(localPath, isNotNull);
      expect(await File(localPath!).readAsBytes(), pngBytes);
      expect(historyCalls, 2);
    },
  );
}
