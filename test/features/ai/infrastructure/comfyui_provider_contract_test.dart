import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/comfyui/comfyui_provider.dart';

class _ComfyClient implements ComfyUiClient {
  String? cancelledRequestId;

  @override
  Future<List<AiModelInfo>> listModels({required String baseUrl}) async =>
      const [];

  @override
  Future<AiGenerationResult> generate({
    required String baseUrl,
    required AiGenerationRequest request,
  }) async => const AiGenerationResult(
    providerRequestId: 'image-request',
    outputs: [
      AiGeneratedOutput(
        type: AiOutputType.image,
        remoteUrl: 'https://example.invalid/image.png',
        mimeType: 'image/png',
      ),
    ],
  );

  @override
  Future<void> cancel({
    required String baseUrl,
    required String requestId,
  }) async {
    cancelledRequestId = requestId;
  }
}

void main() {
  test(
    'image provider accepts image requests and returns image output',
    () async {
      final client = _ComfyClient();
      final provider = ComfyUiProvider(client: client);

      expect(provider.validateTarget(PromptTarget.image), isTrue);
      final result = await provider.generate(
        const AiGenerationRequest(
          jobId: 'image-job',
          prompt: 'a void landscape',
          target: PromptTarget.image,
        ),
      );

      expect(result.outputs.single.type, AiOutputType.image);
      expect(result.outputs.single.remoteUrl, contains('image.png'));
    },
  );

  test('image provider supports remote cancellation', () async {
    final client = _ComfyClient();
    final provider = ComfyUiProvider(client: client);

    await provider.cancel('remote-request');

    expect(client.cancelledRequestId, 'remote-request');
  });

  test('image provider rejects text requests', () {
    final provider = ComfyUiProvider(client: _ComfyClient());

    expect(
      () => provider.validateTarget(PromptTarget.story),
      throwsUnsupportedError,
    );
  });
}
