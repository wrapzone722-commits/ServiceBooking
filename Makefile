# Service Booking — сборка и экспорт IPA
# Требуется: Xcode, Apple ID в Xcode (Settings → Accounts)

.PHONY: ipa clean

ipa:
	@chmod +x scripts/export-ipa.sh
	@./scripts/export-ipa.sh

clean:
	rm -rf build/
