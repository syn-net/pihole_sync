#!/usr/bin/env ash
#
# /root/dns_sync.sh:jeff
#
# Sync ns1.lan dnsmasq configuration and suit it for running a backup NS on this box
# for redundancy sake. We lose adblocking in doing so like this, but we maintain the
# crucial internal LAN hostname mappings.
#
# TODO(jeff): Consider using a dedicated user account for sync?
#

#set -o errexit
#set -o xtrace
#set -o nounset

PATH="/bin:/sbin:/usr/bin:/usr/sbin"

SLEEP_BIN=$(command -v sleep)
PING_BIN="$(command -v ping)"
# Internal variables used in the sync function.
SCP_BIN="$(command -v scp)"

# Sanity check of the existence of a given path (executable).
check_app_path() {
  APP="$1"
  if [ ! -x "$APP" ]; then
    echo "CRITICAL: Could not find ${APP} or it is non-executable."
    echo
    exit 2
  fi
}

# Sanity check of the existence of a host.
#
# check_ip4_host(addr)
# ...where addr is an IPv4 address or a hostname that is
# resolvable by DNS.
#check_ip4_host() {
  #ADDR="$1"
  #if [ ! $("$PING_BIN" -4 -w5 "$ADDR") ]; then
    #echo "CRITICAL: Could not reach the host at ${ADDR}."
    #echo
    #exit 254
  #fi
#}

# Perform allocation duties of target directory paths and
# logging files.
setup() {
  mkdir -p "/etc/pihole"
  mkdir -p "/etc/dnsmasq.d"
  mkdir -p "/var/log/pihole"
  touch "/var/log/pihole/pihole.log"
  touch "/etc/pihole/dnsmasq.conf"

  # IMPORTANT(jeff): This matches /etc/dnsmasq.conf on the virtual Pihole box that
  # we do not have SSH access to, less and except the username swap from pihole
  # to dnsmasq.
  # shellcheck disable=SC3036
  # shellcheck disable=SC2046
  # shellcheck disable=SC2143
  if [ ! $(grep -i -e "conf-dir=/etc/dnsmasq.d" /etc/pihole/dnsmasq.conf) ]; then
    echo -e "conf-dir=/etc/dnsmasq.d" >> "/etc/pihole/dnsmasq.conf"
  fi
  # shellcheck disable=SC3036
  # shellcheck disable=SC2046
  # shellcheck disable=SC2143
  if [ ! $(grep -i -e "user=dnsmasq" /etc/pihole/dnsmasq.conf) ]; then
    echo -e "user=dnsmasq\n" >> "/etc/pihole/dnsmasq.conf"
  fi
}

# Synchronize the local authoritative nameserver to then host as a backup
# nameserver for the host resolution of local hosts.
#
# sync_pull(ssh_source_host)
# ...where ssh_source_host is a string containing the username and host of the
# SSH target whose files we are copying from.
sync_pull() {
  SCP_ARGS="-O" # openwrt compat
  SOURCE="$1"
  SOURCE_CONFIG_PATH="/mnt/npool0/software/Applications/pihole-1/mounts/config"
  SOURCE_DNSMASQ_PATH="/mnt/npool0/software/Applications/pihole-1/mounts/dnsmasq"
  TARGET_CONFIG_PATH="/etc/pihole"
  TARGET_DNSMASQ_PATH="/etc/dnsmasq.d"

  if [ -z "${SOURCE}" ]; then
    echo "CRITICAL: Missing function parameter in sync function -- ssh source host."
    echo
    exit 253
  fi

  # TO /etc/pihole
  "${SCP_BIN}" "${SCP_ARGS}" "${SOURCE}:${SOURCE_CONFIG_PATH}/local.list" "${TARGET_CONFIG_PATH}/local.list"
  "${SCP_BIN}" "${SCP_ARGS}" "${SOURCE}:${SOURCE_CONFIG_PATH}/custom.list" "${TARGET_CONFIG_PATH}/custom.list"
  #"${SCP_BIN}" "${SCP_ARGS}" "${SOURCE}:${SOURCE_CONFIG_PATH}/hosts" "${TARGET_CONFIG_PATH}/hosts"

  # TO /etc/dnsmasq.d
  "$SCP_BIN" "$SCP_ARGS" "${SOURCE}:${SOURCE_DNSMASQ_PATH}/01-pihole.conf" "${TARGET_DNSMASQ_PATH}/01-pihole.conf"
  "$SCP_BIN" "$SCP_ARGS" "${SOURCE}:${SOURCE_DNSMASQ_PATH}/05-pihole-custom-cname.conf" "${TARGET_DNSMASQ_PATH}/05-pihole-custom-cname.conf"
  "$SCP_BIN" "$SCP_ARGS" "${SOURCE}:${SOURCE_DNSMASQ_PATH}/06-rfc6761.conf" "${TARGET_DNSMASQ_PATH}/06-rfc6761.conf"
  "$SCP_BIN" "$SCP_ARGS" "${SOURCE}:${SOURCE_DNSMASQ_PATH}/99-extra.conf" "${TARGET_DNSMASQ_PATH}/99-extra.conf"
}

# TODO(jeff): We can **almost** call sync_push with the right SSH hostname
# from within this function and call it quits. Refactor the code to make
# this so!
# shellcheck disable=SC2317
sync_push() {
  echo "STUB: This function is not yet implemented."
  exit 2
}

# The source configuration files must be modified before usage on another host.
# This function strives to perform the most minimal changes necessary for working
# functionality as a backup nameserver.
#
# adjust_pull_config(source_file, boolean)
# ...where boolean is an optional parameter whose non-nil value will abort performing
# any adjustments, giving one the raw configuration as was seen on the source.
adjust_pull_config() {
  CONFIG_SOURCE_FILE="$1"
  if [ "$CONFIG_SOURCE_FILE" = "" ]; then
    echo "CRITICAL: Missing function parameter in adjust_pull_config -- config source file."
    echo
    exit 255
  fi

  if [ ! (-f "$CONFIG_SOURCE_FILE") ]; then
    echo "CRITICAL: Configuration source file not found at ${CONFIG_SOURCE_FILE}."
    echo
    exit 2
  fi

  NOM_FIX_CONFIG="$2"
  if [ "$NOM_FIX_CONFIG" = "true" ] || [ "$NOM_FIX_CONFIG" = "1" ]; then
    echo "Adjusting configuration entry at ${CONFIG_SOURCE_FILE}..."
    #echo "addn-hosts=/etc/pihole/hosts\n" >> "${CONFIG_SOURCE_FILE}"

    # ...reductions first...

    # NOTE(jeff): Our variant of dnsmasq does not seem to
    # understand the syntax Pihole employs.
    # shellcheck disable=SC2046
    # shellcheck disable=SC2143
    if [ ! $(grep -e "#rev-server" "${CONFIG_SOURCE_FILE}") ]; then
      sed -i 's/^rev-server=/#&/' "${CONFIG_SOURCE_FILE}"
    fi

    # NOTE(jeff): This is entirely optional and needs not
    # be done.
    # shellcheck disable=SC2046
    # shellcheck disable=SC2143
    # if [ ! $(grep -e "#log-facility" /etc/dnsmasq.d/01-pihole.conf) ]; then
      # sed -i 's/^log-facility/#&/' /etc/dnsmasq.d/01-pihole.conf
    # fi

    # ...additions, last....

    # shellcheck disable=SC2046
    # shellcheck disable=SC2143
    if [ ! $(grep -i -e "interface=br-lan" "${CONFIG_SOURCE_FILE}") ]; then
      echo "interface=br-lan" >> "${CONFIG_SOURCE_FILE}"
    fi

    # NOTE(jeff): This is entirely optional and needs not
    # be done.
    # shellcheck disable=SC2046
    # shellcheck disable=SC2143
    if [ ! $(grep -e "no-hosts" "${CONFIG_SOURCE_FILE}") ]; then
      echo "no-hosts" >> "${CONFIG_SOURCE_FILE}"
    fi

    # IMPORTANT(jeff): Disabling DNS query logging is done
    # to prevent filling up the disk on this box -- we have
    # no logrotate or such!
    # shellcheck disable=SC2046
    # shellcheck disable=SC2143
    if [ ! $(grep -e "#log-queries" "${CONFIG_SOURCE_FILE}") ]; then
      sed -i 's/^log-queries/#&/' "${CONFIG_SOURCE_FILE}"
    fi

    # FIXME(jeff): Add secondary config file source
    if [ ! $(grep -e "auth-server=ns1.lan,192.168.12.1,br-lan" /etc/dnsmasq.d/99-extra.conf) ]; then
      sed -i 's/^auth-server=ns1.lan,192.168.12.1,br0/auth-server=ns1.lan,192.168.12.1,br-lan/' /etc/dnsmasq.d/99-extra.conf
    fi
  else
    if [ -n "$NOM_DEBUG" ]; then
      echo "DEBUG: Not adjusting the source configuration -- this is likely to"
      echo "break things!"
    fi
  fi
}

# TODO(jeff): Prepare the configuration in reverse of how we have done so
# in adjust_pull_config
# shellcheck disable=SC2317
adjust_push_config() {
  echo "STUB: This function is not implemented yet."
  exit 2
}

# Final function call; wrap things up before this is called!
on_pull_finish() {
  /etc/init.d/pihole stop
  "$SLEEP_BIN" 5
  /etc/init.d/pihole start
}

# shellcheck disable=SC2317
on_push_finish() {
  /etc/init.d/pihole stop
  "$SLEEP_BIN" 5
  /etc/init.d/pihole start
}

# Begin main execution...

SOURCE_SSH="$1"

if [ -z "$SOURCE_SSH" ]; then
  echo "CRITICAL: Missing function argument -- a SSH host we may obtain the "
  echo "primary configuration files from."
  echo
  exit 2
fi

check_app_path "${SCP_BIN}"
check_app_path "${PING_BIN}"
#check_ip4_host "${SOURCE_SSH_HOST}"
setup

echo "Opening a connection to... ${SOURCE_SSH}"
sync_pull "$SOURCE_SSH"

adjust_pull_config /etc/dnsmasq.d/01-pihole.conf "true"
# TODO(jeff):
# adjust_pull_config ("/etc/dnsmasq.d/01-pihole.conf" "/etc/dnsmasq.d/99-extra.conf") "true"
on_pull_finish

#adjust_push_config "true"
#sync_push "$TARGET_SSH"
#on_push_finish

exit 0

# End main execution...
