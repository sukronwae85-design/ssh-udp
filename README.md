🚀 CAR AUTO INSTALL DENGAN SATU PERINTAH SAJA
📦 PERSIAPAN FILE DI GITHUB:
1. File Utama: install.sh (Script lengkap yang sudah saya buat)

Upload ke: https://github.com/sukronwae85-design/ssh-udp
2. File README.md (Instruksi)
markdown

# 🚀 SSH-UDP-VMESS Auto Installer

## **📥 INSTALASI 1 PERINTAH:**
```bash
bash <(wget -qO- https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/install.sh) --install

text


### **3. File `auto-install.sh`** (File khusus untuk instal 1 perintah)
Buat file baru di GitHub:

```bash
#!/bin/bash
# File: auto-install.sh
# GitHub: https://github.com/sukronwae85-design/ssh-udp
# PERINTAH INSTAL 1 BARIS:
# curl -s https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/auto-install.sh | bash

echo -e "\033[1;36m"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║      🚀 SSH-UDP-VMESS AUTO INSTALLER                     ║"
echo "║         github.com/sukronwae85-design/ssh-udp            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "\033[0m"

# Cek root
if [[ $EUID -ne 0 ]]; then
    echo -e "\033[1;31m✗ Script harus dijalankan sebagai root!\033[0m"
    echo -e "\033[1;33m✓ Jalankan: sudo -i\033[0m"
    echo -e "\033[1;33m✓ Atau: su root\033[0m"
    exit 1
fi

# Download script utama
echo -e "\033[1;33m📥 Mendownload script instalasi...\033[0m"
wget -q -O /tmp/ssh-udp-install.sh https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/install.sh

if [[ $? -ne 0 ]]; then
    echo -e "\033[1;31m✗ Gagal mendownload script!\033[0m"
    exit 1
fi

# Beri permission
chmod +x /tmp/ssh-udp-install.sh

# Jalankan instalasi
echo -e "\033[1;32m✅ Script berhasil didownload!\033[0m"
echo -e "\033[1;33m🚀 Memulai instalasi...\033[0m"
echo -e "\033[1;36m══════════════════════════════════════════════════════════\033[0m"

# Jalankan instalasi
bash /tmp/ssh-udp-install.sh --install

# Cleanup
rm -f /tmp/ssh-udp-install.sh

🎯 PERINTAH AUTO INSTALL 1 BARIS:
PILIHAN 1: Menggunakan curl (TERBAIK)
bash

curl -s https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/auto-install.sh | bash

PILIHAN 2: Menggunakan wget
bash

bash <(wget -qO- https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/auto-install.sh)

PILIHAN 3: Langsung dari script utama
bash

bash <(wget -qO- https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/install.sh) --install

📁 STRUKTUR REPOSITORY GITHUB:
text

ssh-udp/
├── install.sh          # Script utama lengkap
├── auto-install.sh     # Script 1 perintah
├── README.md          # Dokumentasi
└── LICENSE           # Lisensi (opsional)

🔧 CARA SETUP DI GITHUB ANDA:
Step 1: Buat semua file di GitHub

    Login ke GitHub

    Buka: https://github.com/sukronwae85-design/ssh-udp

    Klik "Add file" → "Create new file"

Step 2: Upload install.sh

Nama file: install.sh
Konten: Script lengkap yang sudah saya buat
Step 3: Upload auto-install.sh

Nama file: auto-install.sh
Konten: Script di atas
Step 4: Upload README.md

Nama file: README.md
Konten:
markdown

# 🚀 SSH-UDP-VMESS Auto Installer

## 📦 Features
- ✅ SSH Server (Port 22, 2222, 80, 443)
- ✅ UDP Custom (7100, 7200, 7300, 1-65535)
- ✅ VMESS/VLESS/Trojan (Port 80 & 443)
- ✅ Domain Pointing System
- ✅ Auto Backup & Monitoring

## 🚀 Quick Install (ONE COMMAND)

```bash
# PILIH SALAH SATU:
# 1. Menggunakan curl:
curl -s https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/auto-install.sh | bash

# 2. Menggunakan wget:
bash <(wget -qO- https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/auto-install.sh)

# 3. Langsung dari script utama:
bash <(wget -qO- https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/install.sh) --install

📖 Manual Installation
bash

# Login sebagai root
sudo -i

# Download script
wget https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/install.sh

# Beri permission
chmod +x install.sh

# Jalankan instalasi
./install.sh --install

🛠️ Management Commands
bash

# Setelah instalasi:
./install.sh --menu          # Menu utama
./install.sh --add-user      # Tambah user
./install.sh --add-domain    # Tambah domain
./install.sh --monitor       # Monitoring

📞 Support

GitHub: https://github.com/sukronwae85-design/ssh-udp
text


## **🎯 PERINTAH YANG HARUS DISEBARKAN:**

### **UNTUK USER (Copy paste ini saja):**
```bash
# ✅ PERINTAH AUTO INSTALL 1 BARIS:
sudo -i && curl -s https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/auto-install.sh | bash

ATAU versi lebih singkat:
bash

# 📦 Install dengan satu baris:
bash <(curl -s https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/install.sh) --install

🔍 TEST INSTALASI:
Di VPS baru, jalankan:
bash

# Test dari VPS fresh
ssh root@your-vps-ip

# Kemudian jalankan:
curl -s https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/auto-install.sh | bash

⚠️ TROUBLESHOOTING:

Jika ada masalah dengan GitHub raw URL, gunakan:
Alternative URL:
bash

# Gunakan raw.githack.com
bash <(curl -s https://raw.githack.com/sukronwae85-design/ssh-udp/main/install.sh) --install

# Atau raw.githubusercontent.com langsung
bash <(wget -qO- https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/install.sh) --install

📊 CONTOH HASIL INSTALASI:

Setelah menjalankan 1 perintah, akan muncul:
text

╔══════════════════════════════════════════════════════════╗
║      🚀 SSH-UDP-VMESS AUTO INSTALLER                     ║
║         github.com/sukronwae85-design/ssh-udp            ║
╚══════════════════════════════════════════════════════════╝

📥 Mendownload script instalasi...
✅ Script berhasil didownload!
🚀 Memulai instalasi...
══════════════════════════════════════════════════════════

[1/12] Initializing system...
[2/12] Installing SSH Server...
[3/12] Installing UDP Custom...
... dan seterusnya ...

✅ KEUNTUNGAN METODE INI:

    User hanya perlu ingat 1 perintah

    Auto detect root privileges

    Auto download script terbaru

    Auto cleanup setelah instalasi

    Error handling yang baik

🎯 PERINTAH FINAL YANG PALING SIMPLE:
bash

# UNTUK SEMUA USER - COPY PASTE INI SAJA:
sudo -i && bash <(curl -s https://raw.githubusercontent.com/sukronwae85-design/ssh-udp/main/install.sh) --install

Dengan cara ini, user cukup copy 1 baris perintah, paste di terminal VPS mereka, dan semuanya akan terinstall otomatis! 🚀
s
