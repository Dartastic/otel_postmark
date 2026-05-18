// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_postmark_suppression.dart';

const _tracerName = 'dartastic_otel_libs_postmark';
const _systemValue = 'postmark';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Pair returned from `tracedPostmarkSend` callback.
class PostmarkSendResult<T> {
  const PostmarkSendResult({required this.value, this.messageId});
  final T value;
  final String? messageId;
}

/// Wraps a Postmark `Email/send` or `Email/sendBatch` in a CLIENT span.
Future<T> tracedPostmarkSend<T>({
  required String from,
  required List<String> to,
  required Future<PostmarkSendResult<T>> Function() invoke,
  String? subject,
  String? messageStream,
  String? templateAlias,
}) async {
  if (postmarkInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'messaging.system': _systemValue,
    'messaging.operation': 'publish',
    'messaging.destination.name': 'email',
    'email.from': from,
    'email.to.count': to.length,
    if (subject != null) 'email.subject': subject,
    if (messageStream != null) 'postmark.message_stream': messageStream,
    if (templateAlias != null) 'postmark.template.alias': templateAlias,
  };

  final span = _tracer().startSpan(
    'postmark send',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.messageId != null) {
      span.addAttributes(OTel.attributes([
        OTel.attributeString('messaging.message.id', r.messageId!),
        OTel.attributeString('postmark.message_id', r.messageId!),
      ]));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
