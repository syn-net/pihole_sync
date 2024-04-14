# pihole_sync

## TODO

- [ ] `Makefile`: Write local **install** target
- [ ] Write rc.d init scripts for `bin/pihole_sync.sh`
  * Base off of `/etc/rc.d/S19dnsmasq`
  * **OpenWrt v22.03.3** *r20028-43d71ad93e*
- [ ] Install script
- [ ] Implement `sync_pull`, `adjust_outgoing_config`, `on_pull_finish`
- [ ] Implement `.env` app configuration
  * See `./.env.dist`
- [ ] Create a ~Debian~ [opkg](https://github.com/Optware/Optware-ng/wiki/Adding-a-package-to-Optware-ng) package?
