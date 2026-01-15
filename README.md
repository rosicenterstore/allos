### AKSES ROOT OS Debian
<pre><code>wget -qO set-root "https://github.com/diah082/vip/releases/latest/download/set-root" && chmod +x set-root && sudo ALLOW_ROOT_PASSWORD=1 SET_ROOT_PASSWORD=1 ./set-root
</code></pre> 

```
sudo su
```

```
apt update && apt upgrade -y
```

### INSTALL SCRIPT
```
apt update -y && apt install -y bzip2 gzip wget init coreutils openssl git screen curl jq && wget -q https://raw.githubusercontent.com/rosicenterstore/allos/main/setup.sh && chmod +x setup.sh && screen -S install ./setup.sh
```
### UPDATE SCRIPT
```
wget -q https://raw.githubusercontent.com/rosicenterstore/allos/main/menu/update.sh && chmod +x update.sh && ./update.sh
```
### REBUILD DEBIAN 12
<pre><code>curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && bash reinstall.sh Debian 12 && reboot
</code></pre>

### REBUILD UBUNTU 24
<pre><code>curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && bash reinstall.sh Ubuntu 24.04 && reboot
</code></pre>

### FIX REPOSITORY VPS
```
wget -q filename.web.id/changerepos && chmod 777 changerepos && ./changerepos 3 && sed -i 's/Components: main/Components: main contrib non-free non-free-firmware/g' /etc/apt/sources.list.d/id.sources && apt update -y
```
### REBUILD UBUNTU 22
<pre><code>curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && bash reinstall.sh Ubuntu 22.04 && reboot
</code></pre>

### REBUILD DEBIAN 11
<pre><code>curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && bash reinstall.sh Debian 11 && reboot
</code></pre>
