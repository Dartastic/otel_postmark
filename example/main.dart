// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_postmark/otel_postmark.dart';

/// Traces Postmark calls with OpenTelemetry.
///
/// `otel_postmark` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Postmark call in
/// [tracedPostmarkSend]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'postmark-example');

  // Wraps a Postmark Email/send or Email/sendBatch in a CLIENT span.
  final postmarkSendId = await tracedPostmarkSend<String>(
    from: 'example',
    to: ['example'],
    subject: 'example',
    messageStream: 'example',
    templateAlias: 'example',
    invoke: () async {
      // Make the Postmark call here, then report what it returned.
      const id = 'postmark_8f3a2c';
      return const PostmarkSendResult(value: id, messageId: 'message_8f3a2c');
    },
  );
  OTelLog.info('tracedPostmarkSend returned $postmarkSendId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutPostmarkInstrumentationAsync.
  await runWithoutPostmarkInstrumentationAsync(
    () => tracedPostmarkSend<String>(
      from: 'example',
      to: ['example'],
      subject: 'example',
      messageStream: 'example',
      templateAlias: 'example',
      invoke: () async {
        const id = 'postmark_8f3a2c';
        return const PostmarkSendResult(value: id, messageId: 'message_8f3a2c');
      },
    ),
  );

  await OTel.shutdown();
}
