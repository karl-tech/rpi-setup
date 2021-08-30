#!/usr/bin/env bash
# shellcheck disable=SC2268


identify_the_operating_system_and_architecture() {
  PACKAGE_MANAGEMENT_INSTALL='apt -y --no-install-recommends install'
  PACKAGE_MANAGEMENT_REMOVE='apt purge'
}

install_software() {
  package_name="$1"
  file_to_detect="$2"
  type -P "$file_to_detect" > /dev/null 2>&1 && return
  if ${PACKAGE_MANAGEMENT_INSTALL} "$package_name"; then
    echo "info: $package_name is installed."
  else
    echo "error: Installation of $package_name failed, please check your network."
    exit 1
  fi
}


main() {
  identify_the_operating_system_and_architecture

  install_software 'bridge-utils' 'brctl'
  install_software 'dnsmasq' 'dnsmasq'

  touch /etc/dnsmasq.conf
  echo 'dhcp-range=192.168.3.50,192.168.3.150,255.255.255.0,12h' >> /etc/dnsmasq.conf

  mkdir -p /usr/local/etc/rpi-setup
  touch /usr/local/etc/rpi-setup/setup.sh
  echo "#!/bin/bash
  brctl addbr br-lan
  brctl addif br-lan eth0
  ifconfig br-lan 192.168.3.1 up
  ifconfig eth0 0.0.0.0 up
  sysctl net.ipv4.ip_forward=1
  iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE" > \
        '/usr/local/etc/rpi-setup/setup.sh'

  chmod a+x /usr/local/etc/rpi-setup/setup.sh

  touch /etc/systemd/system/rpi-setup.service
  echo "[Unit]
  Description=autostart
  [Service]
  Type=oneshot
  ExecStart=/home/pi/start.sh
  [Install]
  WantedBy=multi-user.target" > \
    '/etc/systemd/system/rpi-setup.service'

  systemctl daemon-reload
  systemctl enable rpi-setup.service

}

main "$@"
