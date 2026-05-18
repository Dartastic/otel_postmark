// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #dartastic_otel_libs_postmark_suppress;

bool postmarkInstrumentationSuppressed() {
  return Zone.current[_suppressKey] == true;
}

T runWithoutPostmarkInstrumentation<T>(T Function() body) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

Future<T> runWithoutPostmarkInstrumentationAsync<T>(
  Future<T> Function() body,
) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}
