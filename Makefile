all: dist

dist: lint
	mkdir -p build
	cp -av bin etc build
	tar -cvf ./pihole_sync.tar build/bin build/etc
clean:
	rm -rf build/*
	rm -fv pihole_sync.tar
sync-from-ns2:
	scp -O root@ns2:/root/bin/pihole_sync.sh bin/pihole_sync.sh
	scp -O root@ns2:/etc/crontabs/root etc/crontabs/root
	scp -O root@ns2:/etc/init.d/pihole etc/init.d/pihole
sync-to-ns2:
	scp -O bin/pihole_sync.sh root@ns2:/root/bin/pihole_sync.sh
	scp -O etc/crontabs/root root@ns2:/etc/crontabs/root
	scp -O etc/init.d/pihole root@ns2:/etc/init.d/pihole
	ssh root@ns2.lan /etc/init.d/pihole restart
	ssh root@ns2.lan /etc/init.d/pihole status
lint:
	shellcheck --shell=dash bin/pihole_sync.sh
