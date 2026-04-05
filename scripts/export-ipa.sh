#!/bin/bash
#
# Экспорт IPA для App Store.
# Запускайте на Mac, где в Xcode добавлен ваш Apple ID (Accounts) и есть профили для com.servicebooking.app.
#
# Использование:
#   chmod +x scripts/export-ipa.sh
#   ./scripts/export-ipa.sh
#
# Результат: build/ServiceBooking.ipa

set -e
cd "$(dirname "$0")/.."
PROJECT_DIR="$(pwd)"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/ServiceBooking.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
IPA_PATH="$BUILD_DIR/ServiceBooking.ipa"

echo "Проект: $PROJECT_DIR"
echo "Архив:  $ARCHIVE_PATH"
echo "IPA:    $IPA_PATH"
echo ""

# 1. Архивация
mkdir -p "$BUILD_DIR"
echo "Шаг 1/2: создание архива (Release)..."
xcodebuild -scheme ServiceBooking \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  archive 2>&1 | tee "$BUILD_DIR/archive.log"
ARCHIVE_EXIT=${PIPESTATUS[0]}
if [ "$ARCHIVE_EXIT" -ne 0 ]; then
  echo ""
  if grep -q "No Accounts\|No profiles for" "$BUILD_DIR/archive.log" 2>/dev/null; then
    echo "---"
    echo "Подпись не удалась: в среде нет Apple ID или профилей провизионирования."
    echo "Сделайте так:"
    echo "  1. Откройте Xcode → Settings (⌘,) → Accounts → добавьте Apple ID."
    echo "  2. Запустите снова из Терминала: cd \"$PROJECT_DIR\" && make ipa"
    echo "---"
  fi
  exit "$ARCHIVE_EXIT"
fi

# 2. Экспорт в IPA
echo ""
echo "Шаг 2/2: экспорт IPA..."
rm -rf "$EXPORT_PATH"
mkdir -p "$EXPORT_PATH"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$PROJECT_DIR/ExportOptions.plist" \
  -allowProvisioningUpdates

# Переместить IPA в build/ с понятным именем
if [ -f "$EXPORT_PATH/ServiceBooking.ipa" ]; then
  mv "$EXPORT_PATH/ServiceBooking.ipa" "$IPA_PATH"
  echo ""
  echo "Готово. IPA: $IPA_PATH"
  ls -la "$IPA_PATH"
else
  echo "Ошибка: IPA не найден в $EXPORT_PATH"
  ls -la "$EXPORT_PATH" 2>/dev/null || true
  exit 1
fi
