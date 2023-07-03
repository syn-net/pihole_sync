SSH_KEY = ./ssh/id_ed25519-nopassphrase.pub

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
	@echo "Installing cronic.sh script..."
	ssh root@ns2 mkdir -p /usr/local/sbin/
	# IMPORTANT(jeff): Non-embedded installation targets probably want the BASH
	# version of the cronic script at extras/cronic_bash.sh
	scp -O extras/cronic_ash.sh root@ns2:/usr/local/sbin/cronic.sh
	@echo "Installing dnsmasq service scripts..."
	scp -O bin/pihole_sync.sh root@ns2:/root/bin/pihole_sync.sh
	scp -O etc/crontabs/root root@ns2:/etc/crontabs/root
	scp -O etc/init.d/pihole root@ns2:/etc/init.d/pihole
	#scp -O etc/rc.local root@ns2:/etc/rc.local
	@echo "Restarting dnsmasq service at ns2..."
	ssh root@ns2 /etc/init.d/pihole enable
	ssh root@ns2 /etc/init.d/pihole restart
	@echo "Restarting cron service at ns2..."
	ssh root@ns2 /etc/init.d/cron enable
	ssh root@ns2 /etc/init.d/cron restart
	@echo "Checking the dnsmasq service status at ns2..."
	ssh root@ns2 /etc/init.d/pihole status
lint:
	shellcheck --shell=dash bin/pihole_sync.sh
generate_ssh-ed25519:
	@if [ ! -f $(SSH_KEY) ]; then \
		@echo "Creating SSH key..." \
		@ssh-keygen -ted25519 -f ssh/id_ed25519-nopassphrase -C "root@ns2-nopassphrase"; \
	fi;

install: lint generate_ssh-ed25519 sync-to-ns2
