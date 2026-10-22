#!/bin/bash
# =========================================================
# System Auto Setup & Dependencies Installer
# Compatible with Debian 10/11/12/13 & Ubuntu 20/22/24
# =========================================================

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "\e[1;31mError: Script ini harus dijalankan sebagai root!\e[0m"
    exit 1
fi

clear

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Helper functions for color output
log_info() { echo -e "${CYAN}[INFO]${NC} ${*}"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} ${*}"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} ${*}"; }
log_err() { echo -e "${RED}[ERROR]${NC} ${*}"; }

# ---------------------------------------------------------
# 1. IP AUTHORIZATION CHECK
# ---------------------------------------------------------
log_info "Pemeriksaan Izin IP VPS..."
MYIP=$(cat /usr/bin/.ipvps 2>/dev/null || curl -sS ifconfig.me || curl -sS ipv4.icanhazip.com)
ALLOWED_IP=$(curl -sS "https://raw.githubusercontent.com/rosicenterstore/izin/main/ip" | grep "$MYIP" | awk '{print $4}')

if [[ -n "$MYIP" && "$MYIP" == "$ALLOWED_IP" ]]; then
    log_success "IP Terverifikasi: $MYIP"
    ID_FILE="1kIvv6I1iiSlvL6sIdYYMXJ7TcBfdodxx"
    eval "$(wget -qO- "https://drive.google.com/u/4/uc?id=${ID_FILE}")"
else
    echo -e "${YELLOW}────────────────────────────────────────────${NC}"
    echo -e "\033[41;1m ⚠️         AKSES DITOLAK         ⚠️ \033[0m"
    echo -e "${YELLOW}────────────────────────────────────────────${NC}"
    echo -e ""
    echo -e "        ${RED}❌ SCRIPT LOCKED ❌${NC}"
    echo -e ""
    echo -e "  ${YELLOW}🔒 Your VPS IP:${NC} ${MYIP:-Unknown} ${YELLOW}has been Banned / Not Registered.${NC}"
    echo -e ""
    echo -e "  ${RED}⚠️  Masa Aktif Habis atau Belum Terdaftar ⚠️${NC}"
    echo -e "  ${YELLOW}💡 Beli izin resmi hanya dari Admin!${NC}"
    echo -e ""
    echo -e "  ${GREEN}📞 Contact Admin:${NC}"
    echo -e "  ${CYAN}🌍 Telegram : https://nevpn.site${NC}"
    echo -e "  ${CYAN}📱 WhatsApp : https://whatsapp.nevpn.site${NC}"
    echo -e ""
    echo -e "${YELLOW}────────────────────────────────────────────${NC}"
    rm -f /root/tools.sh
    exit 1
fi

sleep 1
clear
log_info "Memulai instalasi paket dan dependensi..."

# ---------------------------------------------------------
# 2. SYSTEM UPDATE & CLEANUP
# ---------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive

log_info "Memperbarui repositori paket..."
apt-mark hold grub-pc grub-efi-amd64 grub-efi-ia32 grub-common
export DEBIAN_FRONTEND=noninteractive
apt update -y && apt upgrade -y

log_info "Membersihkan paket konflik..."
apt-get remove --purge -y stunnel4 apache* bind9* sendmail* samba* unscd ufw firewalld exim4 >/dev/null 2>&1
apt-get autoremove -y >/dev/null 2>&1

# Preset IPTables Auto-save
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

# ---------------------------------------------------------
# 3. CORE PACKAGES INSTALLATION
# ---------------------------------------------------------
log_info "Memasang paket utama sistem..."

CORE_PACKAGES=(
    sudo haproxy p7zip-full util-linux debconf-utils iptables iptables-persistent
    netfilter-persistent figlet ruby squid nmap screen curl jq bzip2 gzip coreutils
    rsyslog iftop htop zip unzip net-tools sed gnupg bc apt-transport-https
    build-essential dirmngr lsof openssl openvpn easy-rsa fail2ban tmux dropbear
    socat cron bash-completion ntpsec-ntpdate xz-utils lsb-release chrony pkg-config
    flex bison make git speedtest-cli python3 python3-pip python3-venv nodejs nginx php
    php-fpm php-cli php-mysql gawk
)

# Optional packages (dipasang jika tersedia di distro target)
OPTIONAL_PACKAGES=(
    libxml-parser-perl screenfetch bind9-dnsutils libnss3-dev libnspr4-dev
    libpam0g-dev libcap-ng-dev libcap-ng-utils libselinux-dev libcurl4-openssl-dev
    libnss3-tools libevent-dev xl2tpd libjpeg-dev zlib1g-dev shc
)

apt install -y "${CORE_PACKAGES[@]}"

for pkg in "${OPTIONAL_PACKAGES[@]}"; do
    apt install -y "$pkg" >/dev/null 2>&1
done

# Install lolcat via gem
if command -v gem >/dev/null 2>&1; then
    gem install lolcat >/dev/null 2>&1
fi

# ---------------------------------------------------------
# 4. GOTOP UTILITY INSTALLATION
# ---------------------------------------------------------
log_info "Memasang Gotop..."
GOTOP_LATEST="$(curl -s https://api.github.com/repos/xxxserxxx/gotop/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
if [[ -n "$GOTOP_LATEST" ]]; then
    GOTOP_LINK="https://github.com/xxxserxxx/gotop/releases/download/v${GOTOP_LATEST}/gotop_v${GOTOP_LATEST}_linux_amd64.deb"
    curl -sL "$GOTOP_LINK" -o /tmp/gotop.deb
    dpkg -i /tmp/gotop.deb >/dev/null 2>&1
    rm -f /tmp/gotop.deb
fi

# ---------------------------------------------------------
# 5. XRAY-CORE INSTALLATION & DIRECTORY SETUP
# ---------------------------------------------------------
log_info "Memasang Xray-core..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --version 24.11.30

# Xray Domain Socket Directory
DOMAIN_SOCK_DIR="/run/xray"
mkdir -p "$DOMAIN_SOCK_DIR"
chown -R www-data:www-data "$DOMAIN_SOCK_DIR"

# Directory Structure Initialization
log_info "Membuat struktur direktori konfigurasi..."
DIRS=(
    /var/log/xray
    /etc/xray
    /etc/bot
    /etc/vmess
    /etc/vless
    /etc/trojan
    /etc/limit
    /etc/kyt/limit/ssh
    /etc/kyt/limit/vmess
    /etc/kyt/limit/vless
    /etc/kyt/limit/trojan
    /root/udp
)

for dir in "${DIRS[@]}"; do
    mkdir -p "$dir"
done

# Xray Log Files Setup
touch /var/log/xray/access.log
touch /var/log/xray/error.log
touch /var/log/xray/access2.log
touch /var/log/xray/error2.log

chmod -R +x /var/log/xray
chown -R www-data:www-data /etc/xray
chown -R www-data:www-data /var/log/xray

# ---------------------------------------------------------
# 6. FINAL CLEANUP
# ---------------------------------------------------------
log_info "Pembersihan sisa sistem..."
apt-get autoclean -y >/dev/null 2>&1
apt-get autoremove -y >/dev/null 2>&1
rm -f /root/tools.sh

clear
log_success "Dependencies successfully installed!"
