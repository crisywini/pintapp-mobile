DEVICE := Crisi’s iPhone

run:
	flutter run -d "$(DEVICE)" --release

install:
	flutter build ios --release
	flutter install -d "$(DEVICE)"
