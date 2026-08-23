#!/usr/bin/env bash
set -e

echo "=== Vercel Flutter Web Build Engine ==="
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK stable branch..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
fi

export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor
flutter build web --release

echo "=== Build Web Complete ==="
