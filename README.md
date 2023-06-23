# pihole_sync

This is a simple workaround script I have come up with in order to maintain a
secondary DNS server while using Pi-Hole as my primary DNS resolver --
although, ad-blocking functionality is lost when the primary goes down, internal
host resolving remains and therefore the critical functionality I need is
preserved.

It was not feasible for me to maintain a block-list on the RAM-starved router
box I am using this script on -- I've tried! Oh well.

## Target

OpenWrt 22.03.3 r20028-43d71ad93e

## Installation

From within the root directory of this project repository...

```shell
# Install dependencies; we need scp from the package...
opkg install openssh-client-utils
mkdir -p /root/bin
cp -av bin/pihole_sync.sh /root/bin/pihole_sync.sh
cp -av etc/init.d/pihole /etc/init.d/pihole
# rc.d run-level scripts have yet to be written, so no enable syntax like we
# have with other services -- so you must start the daemon manually upon boot
cat etc/rc.local >> /etc/rc.local
# Sync every five minutes is the default
cp -av cron/crontab /var/spool/cron/crontabs/root
/etc/init.d/cron enable
/etc/init.d/cron start
```

You must modify the **sync** function in `/root/bin/pihole_sync.sh` if you
expect this to work on your network; change the path of the source configuration
files.

## usage

```shell
# SSH user and host of the pihole box to sync
/root/bin/pihole_sync.sh user@domain.tld
```

**NOTE:** I have not tested this script with non-superuser accounts. I do not
expect it to work out of the box! It should be simple to add, though, as
the `dnsmasq` daemon is ran under a *user* account, not `root`.
