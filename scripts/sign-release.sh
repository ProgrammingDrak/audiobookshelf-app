#!/bin/sh
# Uses an explicitly selected existing key; never creates signing credentials.
set -eu
umask 077
: "${QUIETSHELF_KEYSTORE:?Select the approved permanent release keystore}"
: "${QUIETSHELF_KEY_ALIAS:?Set the approved key alias}"
: "${QUIETSHELF_KEYSTORE_PASSWORD:?Supply the password through the environment}"
: "${QUIETSHELF_CERT_SHA256:?Set the pinned public certificate fingerprint}"
: "${ANDROID_HOME:?Set ANDROID_HOME}"
test "$#" -eq 2 || { echo 'Usage: sign-release.sh unsigned.apk signed.apk' >&2; exit 2; }
test -f "$1"
test ! -e "$2" || { echo 'Refusing to replace an existing artifact' >&2; exit 2; }
BUILD_TOOLS="${ANDROID_BUILD_TOOLS:-$ANDROID_HOME/build-tools/35.0.0}"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
"$BUILD_TOOLS/zipalign" -P 16 -f 4 "$1" "$WORK/aligned.apk"
"$BUILD_TOOLS/apksigner" sign --ks "$QUIETSHELF_KEYSTORE" \
  --ks-key-alias "$QUIETSHELF_KEY_ALIAS" \
  --ks-pass env:QUIETSHELF_KEYSTORE_PASSWORD \
  --key-pass env:QUIETSHELF_KEYSTORE_PASSWORD \
  --out "$WORK/signed.apk" "$WORK/aligned.apk"
"$BUILD_TOOLS/apksigner" verify --verbose --print-certs "$WORK/signed.apk" > "$WORK/verification.txt"
ACTUAL=$(sed -n 's/^Signer #1 certificate SHA-256 digest: //p' "$WORK/verification.txt" | tr '[:upper:]' '[:lower:]' | tr -d ':')
EXPECTED=$(printf '%s' "$QUIETSHELF_CERT_SHA256" | tr '[:upper:]' '[:lower:]' | tr -d ':')
test -n "$ACTUAL" && test "$ACTUAL" = "$EXPECTED" || { echo 'Signer certificate mismatch; artifact withheld' >&2; exit 1; }
"$BUILD_TOOLS/zipalign" -c -P 16 4 "$WORK/signed.apk"
cp "$WORK/signed.apk" "$2"
cat "$WORK/verification.txt"
shasum -a 256 "$2"
