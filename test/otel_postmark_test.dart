// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_postmark/otel_postmark.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_postmark-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('send records CLIENT span', () async {
    await tracedPostmarkSend<String>(
      from: 'noreply@dartastic.io',
      to: ['x@y.com'],
      subject: 'Welcome',
      messageStream: 'outbound',
      templateAlias: 'welcome-en',
      invoke: () async => const PostmarkSendResult(
        value: 'ok',
        messageId: 'pm-1',
      ),
    );
    final a = attrsOf(spans.findSpanByName('postmark send')!);
    expect(a['messaging.system'], 'postmark');
    expect(a['email.from'], 'noreply@dartastic.io');
    expect(a['email.to.count'], 1);
    expect(a['email.subject'], 'Welcome');
    expect(a['postmark.message_stream'], 'outbound');
    expect(a['postmark.template.alias'], 'welcome-en');
    expect(a['messaging.message.id'], 'pm-1');
    expect(a['postmark.message_id'], 'pm-1');
  });

  test('suppression skips spans', () async {
    await runWithoutPostmarkInstrumentationAsync(() async {
      await tracedPostmarkSend<String>(
        from: 'a@x',
        to: ['b@x'],
        invoke: () async => const PostmarkSendResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('postmark '), isEmpty);
  });
}
