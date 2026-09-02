#!/usr/bin/env bash
# Regenerates all Pigeon platform-channel code from pigeons/messages.dart.
# Run after editing the schema, then commit the generated output.
set -euo pipefail
cd "$(dirname "$0")/.."

dart run pigeon --input pigeons/messages.dart \
  --swift_out darwin/video_thumb_kit/Sources/video_thumb_kit/Messages.g.swift
