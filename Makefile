all: lint

# NOTE(jeff): This target is not currently used for anything
dist: lint
	mkdir -p build
	cp -av bin etc build
	tar -cvf ./pihole_sync.tar build/bin build/etc
# NOTE(jeff): This target is not currently used for anything
clean:
	rm -rf build/*
	rm -fv pihole_sync.tar
sync-from-ns2:
	scp -O root@ns2:/root/bin/pihole_sync.sh bin/pihole_sync.sh
	scp -O root@ns2:/etc/crontabs/root etc/crontabs/root
	scp -O root@ns2:/etc/init.d/pihole etc/init.d/pihole
	#scp -O root@ns2:/etc/rc.local etc/rc.local
sync-to-ns2:
	ssh root@ns2 mkdir -p /usr/local/sbin/
	# IMPORTANT(jeff): Non-embedded installation targets probably want the BASH
	# version of the cronic script at extras/cronic_bash.sh
	scp -O extras/cronic_ash.sh root@ns2:/usr/local/sbin/cronic.sh
	scp -O bin/pihole_sync.sh root@ns2:/root/bin/pihole_sync.sh
	scp -O etc/crontabs/root root@ns2:/etc/crontabs/root
	scp -O etc/init.d/pihole root@ns2:/etc/init.d/pihole
	#scp -O etc/rc.local root@ns2:/etc/rc.local
	#ssh root@ns2 /etc/init.d/pihole enable
	ssh root@ns2 /etc/init.d/pihole restart
	ssh root@ns2 /etc/init.d/pihole status
	ssh root@ns2 /etc/init.d/cron enable
	ssh root@ns2 /etc/init.d/cron start
lint:
	shellcheck --shell=dash bin/pihole_sync.sh
