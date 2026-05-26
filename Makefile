DEVICE := Crisi’s iPhone
IPAD  := Cristian’s iPad

run:
	flutter run -d "$(DEVICE)" --release

run-ipad:
	flutter run -d "$(IPAD)" --release

install:
	flutter build ios --release
	flutter install -d "$(DEVICE)"

install-ipad:
	flutter build ios --release
	flutter install -d "$(IPAD)"
