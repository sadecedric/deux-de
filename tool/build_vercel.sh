#!/usr/bin/env bash
set -euo pipefail

# Version identique au SDK utilisé pour vérifier cette application.
flutter_version="${FLUTTER_VERSION:-3.47.1}"
sdk_dir="$PWD/.vercel-flutter-sdk"
if ! command -v flutter >/dev/null 2>&1; then
  if [[ ! -x "$sdk_dir/bin/flutter" ]]; then
    git clone --depth 1 --branch "$flutter_version" https://github.com/flutter/flutter.git "$sdk_dir"
  fi
  export PATH="$sdk_dir/bin:$PATH"
fi

flutter --version
flutter pub get
flutter build web --release --dart-define=PREDICTOR_ONLY=true --no-pub
