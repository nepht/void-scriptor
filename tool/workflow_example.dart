// Contoh end-to-end Sprint 103: mendefinisikan, memvalidasi, dan menjalankan
// workflow dua langkah di atas BackgroundJobQueue existing.
//
// Jalankan: dart run tool/workflow_example.dart
import 'package:void_scriptor/core/jobs/background_job_queue.dart';
import 'package:void_scriptor/workflow/workflow_audit.dart';
import 'package:void_scriptor/workflow/workflow_definition.dart';
import 'package:void_scriptor/workflow/workflow_execution.dart';
import 'package:void_scriptor/workflow/workflow_limits.dart';
import 'package:void_scriptor/workflow/workflow_runner.dart';
import 'package:void_scriptor/workflow/workflow_validation.dart';

Future<void> main() async {
  final now = DateTime.now().toUtc();
  final workflow = WorkflowDefinition(
    workflowId: 'rename-assets',
    name: 'Rename assets',
    version: 1,
    steps: [
      WorkflowStep(stepId: 'collect', commandType: 'asset.scan'),
      WorkflowStep(
        stepId: 'apply',
        commandType: 'asset.rename',
        dependsOn: ['collect'],
      ),
    ],
    policy: const WorkflowPolicy(allowedCapabilities: {'fs.read', 'fs.write'}),
    createdAt: now,
    updatedAt: now,
  );

  // Validasi sebelum eksekusi (5 rule kanonik + unknown command/dependency).
  final issues = WorkflowValidationService(
    knownCommands: const {'asset.scan', 'asset.rename'},
    commandCapabilities: const {
      'asset.scan': {'fs.read'},
      'asset.rename': {'fs.read', 'fs.write'},
    },
  ).validate(workflow);
  if (issues.isNotEmpty) {
    for (final issue in issues) {
      // ignore: avoid_print
      print('INVALID: ${issue.code}');
    }
    return;
  }

  // Batas sumber daya (103.28).
  const limits = WorkflowResourceLimits();
  limits.assertWorkflowAllowed(workflow.steps.length);

  // Audit trail identifier-only (103.27).
  final audit = WorkflowAuditTrail();

  // Eksekusi di ATAS queue Sprint 26 — tanpa engine kedua (103.8).
  final queue = BackgroundJobQueue(maxConcurrentJobs: 2);
  final runner = WorkflowRunner(queue: queue);
  final plan = WorkflowDependencyResolver().plan(workflow);

  audit.record(
    kind: WorkflowAuditEventKind.started,
    executionId: 'contoh-1',
    workflowId: workflow.workflowId,
  );

  final handle = runner.start(
    workflow: workflow,
    plan: plan,
    work: (step, context, attempt) async {
      // Unit kerja nyata memanggil AppCommand di sini; konteks menyediakan
      // isCancelled untuk pembatalan kooperatif.
      return '${step.stepId}-ok';
    },
  );

  final result = await handle.result;
  audit.record(
    kind: result.state == WorkflowExecutionState.succeeded
        ? WorkflowAuditEventKind.completed
        : WorkflowAuditEventKind.failed,
    executionId: result.executionId,
    workflowId: workflow.workflowId,
  );

  // ignore: avoid_print
  print('${result.state} steps=${result.completedSteps} '
      'audit=${audit.entries.length}');
}
