all: dist

dist:
		mkdir -p build
		cp -av bin etc build
		tar -cvf ./pihole_sync.tar build/bin build/etc
clean:
	rm -rf build/*
