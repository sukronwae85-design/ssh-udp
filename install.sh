# Clone repository Anda
git clone https://github.com/sukronwae85-design/ssh-udp.git
cd ssh-udp

# Buat file install.sh
nano install.sh
# Paste seluruh script di atas
# Save dengan Ctrl+X, Y, Enter

# Berikan permission
chmod +x install.sh

# Upload ke GitHub
git add install.sh
git commit -m "Add complete SSH-UDP-VMESS installation script with domain pointing"
git push origin main