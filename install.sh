# Clone repository Anda
git clone https://github.com/sukronwae85-design/installssh.git
cd installssh

# Buat file install.sh (copy script di atas ke file ini)
nano install.sh
# Paste seluruh script di atas
# Ctrl+X, Y, Enter untuk save

# Berikan permission
chmod +x install.sh

# Commit dan push
git add install.sh
git commit -m "Add complete SSH+VMESS+UDP installation script"
git push origin main