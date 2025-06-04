### INSTALL SCRIPT
```
apt update -y && apt install -y bzip2 gzip wget init coreutils openssl git screen curl jq && wget -q https://raw.githubusercontent.com/rosicenterstore/allos/main/setup.sh && chmod +x setup.sh && screen -S install ./setup.sh
```
### UPDATE SCRIPT
```
wget -q https://raw.githubusercontent.com/rosicenterstore/allos/main/menu/update.sh && chmod +x update.sh && ./update.sh
```
