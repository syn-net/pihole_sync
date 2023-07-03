# pihole_sync

This is a simple workaround script I have come up with in order to maintain a
secondary DNS server while using Pi-Hole as my primary DNS resolver --
although, ad-blocking functionality is lost when the primary goes down, internal
host resolving remains functional and therefore acceptable to me.

It was not feasible for me to maintain a block-list on the RAM-starved router
box I am using this script on -- I've tried! Oh well.

**NOTE**: What makes this project unique is the fact that the secondary DNS has
nothing to do with Pi-Hole and is only a bare-bones `dnsmasq` setup. It is a
redundant version of Pi-Hole's core functionality.

## Target

OpenWrt 22.03.3 r20028-43d71ad93e

### Dependencies

- ash
  * This is the default shell and is distributed with the base installation
  - busybox
    * `echo`
    * `mkdir`
    * `ping`
    * `sed`
    * `sleep`
    * `touch`
- curl
- scp
  * I believe that this package is distributed with the base installation on most all platforms

### Installation

It is assumed that you have setup SSH access to the system you are bootstrapping
this software on. Also, it is recommended that you setup an unprivileged local
user on the source location that has SSH access to the Pi-Hole configuration files.

```shell
# /root/.ssh/authorized_keys on the Pi-Hole source server
command="/scripts/sshd/scp.sh",FROM="<PRIVATE_IP_HERE>",NO-AGENT-FORWARDING,NO-PORT-FORWARDING,NO-PTY,NO-USER-RC,NO-X11-FORWARDING ssh-ed25519 <YOUR_SSH_KEY_WITHOUT_PASSPHRASE>
```
- [scp.sh](https://gist.github.com/Zoddo/035784d640ecf9156fa471534deb1e1f)

```shell
opkg install curl busybox
mkdir -p /root/bin
cp -av bin/pihole_sync.sh /root/bin/pihole_sync.sh
cp -av etc/init.d/pihole /etc/init.d/pihole
# rc.d run-level scripts have yet to be written, so no enable syntax like we
# have with other services -- so you must start the daemon manually upon boot
cat etc/rc.local >> /etc/rc.local
# Sync every five minutes is the default
cp -av etc/crontabs/root /etc/crontabs/root
/etc/init.d/cron enable
/etc/init.d/cron start
```

**FIXME**: You must modify the **sync** function in `/root/bin/pihole_sync.sh` if you
expect this to work on your network; change the path of the configuration files
to match your setup!

## usage

```shell
# SSH user and host of the pihole box to sync
/root/bin/pihole_sync.sh user@domain.tld
```

## extras

- `extras/cronic_ash.sh` This is nifty little script that you simply append in
front of whatever script you are running from your user's `crontab` entry in order
to receive emails from `crond` *only* when the script exits with a **non-zero** signal
code. ~It is not included in the sample `etc/crontab/root` and must be appended yourself.~
  * [cronic](https://habilis.net/cronic/)

## Alternatives

- [gravity-sync](https://github.com/vmstan/gravity-sync)
