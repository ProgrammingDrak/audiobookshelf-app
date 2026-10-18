#!/bin/sh
set -eu
cd "$(dirname "$0")/../android"
TASK_ROOT=$(cd ../.. && pwd)
LEGACY_TOOLS=/Users/drakeshadwell/Documents/Codex/2026-10-07/task/toolchain
export JAVA_HOME="${JAVA_HOME:-$TASK_ROOT/.toolchain/jdk-21.0.12.1+1/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-$TASK_ROOT/.toolchain/sdk}"
export ANDROID_USER_HOME="${ANDROID_USER_HOME:-$TASK_ROOT/.toolchain/android-user}"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$TASK_ROOT/.toolchain/gradle-home}"
GRADLE_BIN="${GRADLE_BIN:-$LEGACY_TOOLS/gradle-8.11.1/bin/gradle}"
exec "$GRADLE_BIN" --no-daemon --max-workers=2 \
  "-Porg.gradle.java.installations.paths=$JAVA_HOME,$LEGACY_TOOLS/jdk-17.0.20.1+1/Contents/Home" \
  "$@"
