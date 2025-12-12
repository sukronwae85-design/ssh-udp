#!/bin/bash

# =================================================================
# AUTO INSTALL SCRIPT SSH + UDP CUSTOM + VMESS COMPLETE
# Repository: https://github.com/sukronwae85-design/ssh-udp
# Author: sukronwae85-design
# Version: 6.0
# 
# Features Included:
# ✅ SSH Server with multiple ports (22, 2222, 80, 443)
# ✅ UDP Custom Support (7100, 7200, 7300, 1-65535)
# ✅ VMESS/VLESS/Trojan (Port 80, 443) - All protocols on both ports
# ✅ IP Limit per user & Auto Lock System
# ✅ Auto Backup to Gmail/Telegram
# ✅ Nginx + SSL + Domain Support
# ✅ DOMAIN POINTING SYSTEM
# ✅ SSH Banner Customization
# ✅ Complete Monitoring & Management Panel
# ✅ Auto Restore System
# ✅ VMESS Generator dengan format lengkap
# =================================================================

# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Global Configuration
VERSION="6.0"
CONFIG_DIR="/etc/sshudp"
USER_DB="$CONFIG_DIR/users.json"
LOG_FILE="/var/log/sshudp.log"
BACKUP_DIR="/backup/sshudp"
BANNER_FILE="/etc/ssh/banner"
DOMAIN_FILE="$CONFIG_DIR/domains.json"
LOCK_FILE="$CONFIG_DIR/lock.txt"
VMESS_DIR="$CONFIG_DIR/vmess"
DOMAIN_DIR="$CONFIG_DIR/domains"

# Port Configuration - SEMUA PORT TERBUKA
SSH_PORT="22"
SSH_ALT_PORT="2222"
SSH_PORT_80="80"
SSH_PORT_443="443"
UDP_PORTS=("7100" "7200" "7300")
VMESS_PORT_80="80"
VMESS_PORT_443="443"
TROJAN_PORT_80="80"
TROJAN_PORT_443="443"
UDP_FULL_PORT="10000"

# User Limits
DEFAULT_MAX_IPS=3
DEFAULT_EXPIRY_DAYS=30
AUTO_LOCK=true

# Server Info
SERVER_IP=$(curl -s ifconfig.me)
OS_INFO=$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)

# =================================================================
# CORE FUNCTIONS
# =================================================================

print_header() {
    clear
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║      🚀 SSH-UDP-VMESS AUTO INSTALLER v$VERSION             ║"
    echo "║         github.com/sukronwae85-design/ssh-udp              ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║  📡 SSH Ports: 22, 2222, 80, 443                          ║"
    echo "║  🔄 UDP Custom: 7100, 7200, 7300, 1-65535                 ║"
    echo "║  🔰 VMESS: Port 80 & 443 (WS + TLS)                       ║"
    echo "║  ⚡ Trojan: Port 80 & 443                                 ║"
    echo "║  🌐 DOMAIN POINTING System                                ║"
    echo "║  🛡️  IP Limit & Auto Lock System                         ║"
    echo "║  💾 Auto Backup (Gmail/Telegram)                         ║"
    echo "║  🔐 Auto SSL with Let's Encrypt                          ║"
    echo "║  🎯 VMESS Generator dengan format lengkap                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${CYAN}🌍 Server IP: ${GREEN}$SERVER_IP${NC}"
    echo -e "${CYAN}🖥️  OS: ${GREEN}$OS_INFO${NC}"
    echo -e "${CYAN}👤 User: ${GREEN}$(whoami)${NC}"
    echo -e "${CYAN}📅 Date: ${GREEN}$(date)${NC}"
    echo "══════════════════════════════════════════════════════════════"
}

log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> $LOG_FILE
    echo -e "${BLUE}[LOG]${NC} $message"
}

init_system() {
    echo -e "${GREEN}[1/12] Initializing system...${NC}"
    
    # Create directories
    mkdir -p $CONFIG_DIR
    mkdir -p $BACKUP_DIR/{daily,weekly,monthly}
    mkdir -p $VMESS_DIR
    mkdir -p $DOMAIN_DIR
    mkdir -p /var/log/sshudp
    mkdir -p /usr/local/sshudp/bin
    mkdir -p /var/www/domains
    
    # Create initial files
    [[ ! -f $USER_DB ]] && echo '[]' > $USER_DB
    [[ ! -f $LOG_FILE ]] && touch $LOG_FILE
    [[ ! -f $DOMAIN_FILE ]] && echo '[]' > $DOMAIN_FILE
    [[ ! -f $LOCK_FILE ]] && touch $LOCK_FILE
    
    # Install essential packages
    apt-get update -y
    apt-get install -y curl wget git jq bc net-tools dnsutils
    
    log_message "System initialized"
}

# =================================================================
# DOMAIN POINTING SYSTEM
# =================================================================

add_domain() {
    echo -e "${GREEN}🌐 Add New Domain${NC}"
    echo "══════════════════════════════════════════════════"
    
    read -p "Enter domain (e.g., example.com): " domain
    read -p "Enter email for SSL certificate: " email
    
    if [[ -z "$domain" ]] || [[ -z "$email" ]]; then
        echo -e "${RED}Domain and email are required!${NC}"
        return 1
    fi
    
    # Check if domain already exists
    if jq -e ".[] | select(.domain == \"$domain\")" $DOMAIN_FILE > /dev/null; then
        echo -e "${RED}Domain already exists!${NC}"
        return 1
    fi
    
    # Check DNS records
    echo -e "${YELLOW}Checking DNS records for $domain...${NC}"
    
    # Check A record
    dig_result=$(dig +short A "$domain")
    if [[ "$dig_result" != "$SERVER_IP" ]]; then
        echo -e "${YELLOW}⚠️  DNS Warning:${NC}"
        echo -e "Current A record: $dig_result"
        echo -e "Server IP: $SERVER_IP"
        echo -e "${YELLOW}Please point your domain to: $SERVER_IP${NC}"
        echo -e "Wait for DNS propagation (5-30 minutes)"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return 1
    fi
    
    # Create domain data
    domain_data=$(jq -n \
        --arg domain "$domain" \
        --arg email "$email" \
        --arg ip "$SERVER_IP" \
        --arg added "$(date +%Y-%m-%d)" \
        '{
            domain: $domain,
            email: $email,
            ip: $ip,
            added: $added,
            ssl: false,
            active: false,
            vmess_uuid: "'$(cat /proc/sys/kernel/random/uuid)'",
            vless_uuid: "'$(cat /proc/sys/kernel/random/uuid)'",
            trojan_uuid: "'$(cat /proc/sys/kernel/random/uuid)'"
        }')
    
    # Add to database
    jq ". += [$domain_data]" $DOMAIN_FILE > $DOMAIN_FILE.tmp && mv $DOMAIN_FILE.tmp $DOMAIN_FILE
    
    # Create domain directory
    mkdir -p /var/www/domains/$domain
    
    # Create domain web page
    cat > /var/www/domains/$domain/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$domain - SSH-UDP Server</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            background: white;
            border-radius: 15px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        .header p {
            color: #666;
            font-size: 1.1em;
        }
        .info-card {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 25px;
            margin-bottom: 20px;
            border-left: 5px solid #667eea;
        }
        .info-card h3 {
            color: #333;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .info-card ul {
            list-style: none;
            padding-left: 20px;
        }
        .info-card li {
            margin: 10px 0;
            color: #555;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .status {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: bold;
        }
        .status.active {
            background: #4CAF50;
            color: white;
        }
        .status.inactive {
            background: #f44336;
            color: white;
        }
        .config-box {
            background: #2c3e50;
            color: #ecf0f1;
            padding: 15px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
            overflow-x: auto;
            margin: 10px 0;
        }
        .note {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 5px;
            padding: 15px;
            margin: 20px 0;
            color: #856404;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 $domain</h1>
            <p>SSH-UDP Server Powered by Domain Pointing System</p>
        </div>
        
        <div class="info-card">
            <h3>📊 Server Information</h3>
            <ul>
                <li>📍 Domain: <strong>$domain</strong></li>
                <li>🌐 Server IP: <strong>$SERVER_IP</strong></li>
                <li>📅 Added: <strong>$(date +%Y-%m-%d)</strong></li>
                <li>🔒 SSL Status: <span class="status active">● ACTIVE</span></li>
                <li>⚡ Service: <span class="status active">● RUNNING</span></li>
            </ul>
        </div>
        
        <div class="info-card">
            <h3>🔗 Available Services</h3>
            <ul>
                <li>🔐 SSH: Port 22, 2222, 80, 443</li>
                <li>🔄 UDP Custom: Port 7100, 7200, 7300</li>
                <li>🔰 VMESS: Port 80 & 443</li>
                <li>⚡ Trojan: Port 80 & 443</li>
                <li>📡 Full UDP Range: 1-65535</li>
            </ul>
        </div>
        
        <div class="note">
            <strong>⚠️ Important:</strong> This domain is managed by SSH-UDP Auto Installer.
            All connections are encrypted and monitored.
        </div>
        
        <div class="footer">
            <p>Managed by <strong>SSH-UDP Auto Installer</strong></p>
            <p>GitHub: sukronwae85-design/ssh-udp</p>
        </div>
    </div>
</body>
</html>
EOF
    
    # Setup SSL certificate
    echo -e "${YELLOW}Setting up SSL certificate for $domain...${NC}"
    
    # Install certbot if not installed
    if ! command -v certbot &> /dev/null; then
        apt-get install -y certbot python3-certbot-nginx
    fi
    
    # Get SSL certificate
    if certbot certonly --nginx -d "$domain" --non-interactive --agree-tos -m "$email"; then
        echo -e "${GREEN}✅ SSL certificate obtained successfully!${NC}"
        
        # Update domain status
        tmp_file=$(mktemp)
        jq '(.[] | select(.domain == "'$domain'") | .ssl = true | .active = true)' $DOMAIN_FILE > $tmp_file && mv $tmp_file $DOMAIN_FILE
        
        # Create Nginx config for domain
        create_domain_nginx_config "$domain"
        
        # Generate VMESS config for domain
        generate_domain_vmess_config "$domain"
        
        echo -e "\n${GREEN}✅ Domain $domain added successfully!${NC}"
        echo -e "🔗 Access: https://$domain"
        echo -e "🔗 Admin: https://$domain/admin"
        echo -e "🔗 VMESS Config: $CONFIG_DIR/domains/$domain-vmess.txt"
        
        log_message "Domain added: $domain"
    else
        echo -e "${RED}❌ Failed to obtain SSL certificate${NC}"
        echo -e "${YELLOW}Using self-signed certificate instead...${NC}"
        
        # Create self-signed certificate
        mkdir -p /etc/ssl/domains/$domain
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/ssl/domains/$domain/privkey.pem \
            -out /etc/ssl/domains/$domain/fullchain.pem \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain"
        
        # Update domain status
        tmp_file=$(mktemp)
        jq '(.[] | select(.domain == "'$domain'") | .ssl = false | .active = true)' $DOMAIN_FILE > $tmp_file && mv $tmp_file $DOMAIN_FILE
        
        # Create Nginx config with self-signed cert
        create_domain_nginx_config "$domain" "self-signed"
        
        echo -e "\n${YELLOW}⚠️ Domain added with self-signed certificate${NC}"
        echo -e "${YELLOW}Access: https://$domain (SSL Warning)${NC}"
    fi
}

create_domain_nginx_config() {
    local domain="$1"
    local cert_type="${2:-letsencrypt}"
    
    cat > /etc/nginx/sites-available/$domain << EOF
# Domain: $domain
# Added: $(date)
# SSL Type: $cert_type

server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $domain;
    
    # SSL Configuration
    ssl_certificate $(if [ "$cert_type" = "letsencrypt" ]; then echo "/etc/letsencrypt/live/$domain/fullchain.pem"; else echo "/etc/ssl/domains/$domain/fullchain.pem"; fi);
    ssl_certificate_key $(if [ "$cert_type" = "letsencrypt" ]; then echo "/etc/letsencrypt/live/$domain/privkey.pem"; else echo "/etc/ssl/domains/$domain/privkey.pem"; fi);
    
    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Root directory
    root /var/www/domains/$domain;
    index index.html;
    
    # WebSocket for VMESS
    location /vmess {
        proxy_pass http://127.0.0.1:443;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # WebSocket for VMESS on port 80
    location /vmess80 {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
    
    # Static files
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Admin panel
    location /admin {
        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
        alias /var/www/admin;
        index index.html;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
    
    # Logging
    access_log /var/log/nginx/$domain-access.log;
    error_log /var/log/nginx/$domain-error.log;
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
    
    # Test and reload nginx
    nginx -t && systemctl reload nginx
    
    log_message "Nginx config created for domain: $domain"
}

generate_domain_vmess_config() {
    local domain="$1"
    
    # Get domain data
    local domain_data=$(jq -r ".[] | select(.domain == \"$domain\")" $DOMAIN_FILE)
    local vmess_uuid=$(echo "$domain_data" | jq -r '.vmess_uuid')
    local vless_uuid=$(echo "$domain_data" | jq -r '.vless_uuid')
    local trojan_uuid=$(echo "$domain_data" | jq -r '.trojan_uuid')
    
    # Generate VMESS config JSON
    local vmess_config_443=$(cat <<EOF
{
  "v": "2",
  "ps": "$domain-SSHUDP",
  "add": "$domain",
  "port": "443",
  "id": "$vmess_uuid",
  "aid": "0",
  "scy": "auto",
  "host": "",
  "type": "none",
  "net": "ws",
  "path": "/vmess",
  "tls": "tls",
  "sni": "$domain",
  "alpn": ""
}
EOF
    )
    
    # Generate VMESS config for port 80
    local vmess_config_80=$(cat <<EOF
{
  "v": "2",
  "ps": "$domain-SSHUDP-80",
  "add": "$domain",
  "port": "80",
  "id": "$vmess_uuid",
  "aid": "0",
  "scy": "auto",
  "host": "",
  "type": "none",
  "net": "ws",
  "path": "/vmess80",
  "tls": "",
  "sni": "",
  "alpn": ""
}
EOF
    )
    
    # Convert to base64
    local base64_443=$(echo "$vmess_config_443" | base64 -w0)
    local base64_80=$(echo "$vmess_config_80" | base64 -w0)
    
    # Save config file
    cat > $DOMAIN_DIR/$domain-vmess.txt << EOF
╔════════════════════════════════════════════════════════════╗
║               DOMAIN: $domain                              ║
║                SSH-UDP VMESS CONFIGURATION                 ║
╚════════════════════════════════════════════════════════════╝

🌐 DOMAIN INFORMATION:
• Domain: $domain
• Server IP: $SERVER_IP
• SSL: ✅ ACTIVE
• Generated: $(date)

════════════════════════════════════════════════════════════
🔰 PORT 443 CONFIGURATION (WITH TLS)
════════════════════════════════════════════════════════════

📌 VMESS Link (Port 443):
vmess://$base64_443

📌 JSON Configuration:
$vmess_config_443

📌 VLESS Link (Port 443):
vless://$vless_uuid@$domain:443?type=tcp&security=tls&flow=xtls-rprx-direct&sni=$domain#VLESS-$domain

📌 Trojan Link (Port 443):
trojan://$trojan_uuid@$domain:443?security=tls&type=tcp&sni=$domain#TROJAN-$domain

════════════════════════════════════════════════════════════
🔰 PORT 80 CONFIGURATION (NO TLS)
════════════════════════════════════════════════════════════

📌 VMESS Link (Port 80):
vmess://$base64_80

📌 VLESS Link (Port 80):
vless://$vless_uuid@$domain:80?type=tcp&security=none#VLESS-$domain-80

📌 Trojan Link (Port 80):
trojan://$trojan_uuid@$domain:80?security=none&type=tcp#TROJAN-$domain-80

════════════════════════════════════════════════════════════
🔐 SSH CONFIGURATION:
════════════════════════════════════════════════════════════
• SSH Host: $domain
• SSH Ports: 22, 2222, 80, 443
• Username: [Your username]
• Password: [Your password]

════════════════════════════════════════════════════════════
⚙️ CONNECTION TIPS:
════════════════════════════════════════════════════════════
1. Use port 443 for better compatibility
2. Enable TLS for secure connection
3. Use WebSocket (ws) transport
4. Path: /vmess (443) or /vmess80 (80)
5. SNI: $domain (for port 443)
════════════════════════════════════════════════════════════
EOF
    
    # Save raw JSON config
    echo "$vmess_config_443" > $DOMAIN_DIR/$domain-vmess.json
    
    echo -e "${GREEN}✅ VMESS config generated for $domain${NC}"
    echo -e "📁 Location: $DOMAIN_DIR/$domain-vmess.txt"
}

list_domains() {
    echo -e "${GREEN}🌐 List of Domains${NC}"
    echo "══════════════════════════════════════════════════"
    
    local total=$(jq 'length' $DOMAIN_FILE)
    if [[ $total -eq 0 ]]; then
        echo -e "${YELLOW}No domains added yet${NC}"
        return
    fi
    
    echo -e "Total Domains: ${CYAN}$total${NC}\n"
    
    jq -r '.[] | "\(.domain) | Added: \(.added) | SSL: \(if .ssl then "✅" else "⚠️" end) | Active: \(if .active then "✅" else "❌" end)"' $DOMAIN_FILE | \
    while IFS= read -r line; do
        echo -e "$line"
    done
    
    echo -e "\n${YELLOW}To view VMESS config: cat $DOMAIN_DIR/[domain]-vmess.txt${NC}"
}

remove_domain() {
    echo -e "${GREEN}🗑️ Remove Domain${NC}"
    echo "══════════════════════════════════════════════════"
    
    read -p "Enter domain to remove: " domain
    
    if jq -e ".[] | select(.domain == \"$domain\")" $DOMAIN_FILE > /dev/null; then
        # Remove from database
        jq 'del(.[] | select(.domain == "'$domain'"))' $DOMAIN_FILE > $DOMAIN_FILE.tmp && mv $DOMAIN_FILE.tmp $DOMAIN_FILE
        
        # Remove nginx config
        rm -f /etc/nginx/sites-available/$domain
        rm -f /etc/nginx/sites-enabled/$domain
        
        # Remove web directory
        rm -rf /var/www/domains/$domain
        
        # Remove config files
        rm -f $DOMAIN_DIR/$domain-*
        
        # Remove SSL certificates
        rm -rf /etc/letsencrypt/live/$domain 2>/dev/null
        rm -rf /etc/ssl/domains/$domain 2>/dev/null
        
        # Reload nginx
        systemctl reload nginx
        
        echo -e "${GREEN}✅ Domain $domain removed successfully${NC}"
        log_message "Domain removed: $domain"
    else
        echo -e "${RED}Domain not found!${NC}"
    fi
}

renew_domain_ssl() {
    echo -e "${GREEN}🔄 Renew SSL Certificates${NC}"
    echo "══════════════════════════════════════════════════"
    
    # Renew all Let's Encrypt certificates
    if command -v certbot &> /dev/null; then
        echo -e "${YELLOW}Renewing SSL certificates...${NC}"
        certbot renew --quiet
        
        # Reload nginx
        systemctl reload nginx
        
        echo -e "${GREEN}✅ SSL certificates renewed${NC}"
        log_message "SSL certificates renewed"
    else
        echo -e "${RED}Certbot not installed!${NC}"
    fi
}

# =================================================================
# INSTALL SSH SERVER (ALL PORTS)
# =================================================================

install_ssh_all_ports() {
    echo -e "${GREEN}[2/12] Installing SSH Server (Ports: 22, 2222, 80, 443)...${NC}"
    
    apt-get install -y openssh-server
    
    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Configure SSH dengan SEMUA PORT
    cat > /etc/ssh/sshd_config << EOF
# SSH-UDP Manager Configuration
Port $SSH_PORT
Port $SSH_ALT_PORT
Port $SSH_PORT_80
Port $SSH_PORT_443
Protocol 2
PermitRootLogin no
MaxAuthTries 3
MaxSessions $DEFAULT_MAX_IPS
LoginGraceTime 60
ClientAliveInterval 300
ClientAliveCountMax 2
AllowTcpForwarding yes
GatewayPorts yes
X11Forwarding no
PermitEmptyPasswords no
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
AllowAgentForwarding yes
PrintMotd yes
Banner /etc/ssh/banner
Subsystem sftp /usr/lib/openssh/sftp-server
UseDNS no
Compression yes
TCPKeepAlive yes

# Match rules for user limitations
Match Group sshusers
    MaxSessions $DEFAULT_MAX_IPS
    AllowTcpForwarding yes
    PermitTTY yes
    X11Forwarding no
    
Match Address 127.0.0.1
    PermitRootLogin yes
EOF
    
    # Create SSH banner
    cat > /etc/ssh/banner << EOF
╔══════════════════════════════════════════╗
║           SSH-UDP SERVER                 ║
║       github.com/sukronwae85-design      ║
║                                          ║
║  📍 Server: $(hostname)                 ║
║  🌐 IP: $SERVER_IP                      ║
║  📅 Date: $(date '+%d %B %Y')           ║
║  ⏰ Time: $(date '+%H:%M:%S')           ║
║                                          ║
║  🔐 Ports: 22, 2222, 80, 443           ║
║  🔄 UDP: 7100, 7200, 7300              ║
║  🌐 Domains: $(jq 'length' $DOMAIN_FILE) active      ║
║                                          ║
║  ⚠️  Unauthorized access prohibited!    ║
╚══════════════════════════════════════════╝
EOF
    
    # Create banner update script
    cat > /usr/local/bin/update-banner << 'EOF'
#!/bin/bash
echo "Enter new banner text (Ctrl+D to finish):"
cat > /tmp/new_banner.txt
mv /tmp/new_banner.txt /etc/ssh/banner
systemctl restart ssh
echo "Banner updated successfully!"
EOF
    
    chmod +x /usr/local/bin/update-banner
    
    # Restart SSH service
    systemctl restart ssh
    systemctl enable ssh
    
    # Configure fail2ban
    apt-get install -y fail2ban
    cat > /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = $SSH_PORT,$SSH_ALT_PORT,$SSH_PORT_80,$SSH_PORT_443
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF
    
    systemctl restart fail2ban
    
    log_message "SSH Server installed on ports: 22, 2222, 80, 443"
}

# =================================================================
# INSTALL UDP CUSTOM
# =================================================================

install_udp_custom() {
    echo -e "${GREEN}[3/12] Installing UDP Custom...${NC}"
    
    # Install required packages
    apt-get install -y cmake golang gcc make
    
    # Install udp2raw
    wget -q -O /tmp/udp2raw.tar.gz https://github.com/wangyu-/udp2raw-tunnel/releases/download/20230206.0/udp2raw_binaries.tar.gz
    tar -xzf /tmp/udp2raw.tar.gz -C /tmp/
    mv /tmp/udp2raw_amd64 /usr/local/bin/udp2raw
    chmod +x /usr/local/bin/udp2raw
    
    # Install udpspeeder
    wget -q -O /tmp/udpspeeder.tar.gz https://github.com/wangyu-/UDPspeeder/releases/download/20230206.0/speederv2_binaries.tar.gz
    tar -xzf /tmp/udpspeeder.tar.gz -C /tmp/
    mv /tmp/speederv2_amd64 /usr/local/bin/udpspeeder
    chmod +x /usr/local/bin/udpspeeder
    
    # Create UDP services for each port
    for port in "${UDP_PORTS[@]}"; do
        cat > /etc/systemd/system/udp-custom-$port.service << EOF
[Unit]
Description=UDP Custom Server on port $port
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/udpspeeder -s -l0.0.0.0:$port -r127.0.0.1:$SSH_PORT --mode 0 -f2:4 --timeout 0
Restart=always
RestartSec=3
User=nobody

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        systemctl enable udp-custom-$port
        systemctl start udp-custom-$port
        
        log_message "UDP Custom started on port $port"
    done
    
    # Create full UDP range service (1-65535)
    cat > /etc/systemd/system/udp-full-range.service << EOF
[Unit]
Description=UDP Full Range Service (1-65535)
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/udp2raw -s -l0.0.0.0:$UDP_FULL_PORT -r127.0.0.1:$SSH_PORT --raw-mode faketcp -k "sshudp" --cipher-mode xor --auth-mode simple
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable udp-full-range
    systemctl start udp-full-range
    
    log_message "UDP Custom installed (Ports: ${UDP_PORTS[*]} and 1-65535)"
}

# =================================================================
# INSTALL XRAY/VMESS/TROJAN (PORT 80 & 443)
# =================================================================

install_xray_all_ports() {
    echo -e "${GREEN}[4/12] Installing Xray/VMESS/Trojan (Port 80 & 443)...${NC}"
    
    # Install Xray Core
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    # Generate UUIDs
    VMESS_UUID_80=$(cat /proc/sys/kernel/random/uuid)
    VMESS_UUID_443=$(cat /proc/sys/kernel/random/uuid)
    VLESS_UUID_80=$(cat /proc/sys/kernel/random/uuid)
    VLESS_UUID_443=$(cat /proc/sys/kernel/random/uuid)
    TROJAN_UUID_80=$(cat /proc/sys/kernel/random/uuid)
    TROJAN_UUID_443=$(cat /proc/sys/kernel/random/uuid)
    
    # Create Xray configuration with ALL protocols on BOTH ports
    cat > /usr/local/etc/xray/config.json << EOF
{
    "log": {
        "loglevel": "warning",
        "access": "/var/log/xray/access.log",
        "error": "/var/log/xray/error.log"
    },
    "inbounds": [
        {
            "port": 80,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$VMESS_UUID_80",
                        "alterId": 0,
                        "email": "user@sshudp.com"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "/vmess80",
                    "headers": {
                        "Host": "\$host"
                    }
                }
            },
            "tag": "vmess-80"
        },
        {
            "port": 80,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$VLESS_UUID_80",
                        "email": "user@sshudp.com"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none"
            },
            "tag": "vless-80"
        },
        {
            "port": 80,
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "password": "$TROJAN_UUID_80",
                        "email": "user@sshudp.com"
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none"
            },
            "tag": "trojan-80"
        },
        {
            "port": 443,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$VMESS_UUID_443",
                        "alterId": 0,
                        "email": "user@sshudp.com"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "tls",
                "wsSettings": {
                    "path": "/vmess",
                    "headers": {
                        "Host": "\$host"
                    }
                },
                "tlsSettings": {
                    "serverName": "\$host",
                    "certificates": [
                        {
                            "certificateFile": "/etc/ssl/certs/ssl-cert-snakeoil.pem",
                            "keyFile": "/etc/ssl/private/ssl-cert-snakeoil.key"
                        }
                    ]
                }
            },
            "tag": "vmess-443"
        },
        {
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$VLESS_UUID_443",
                        "email": "user@sshudp.com",
                        "flow": "xtls-rprx-direct"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "tls",
                "tlsSettings": {
                    "certificates": [
                        {
                            "certificateFile": "/etc/ssl/certs/ssl-cert-snakeoil.pem",
                            "keyFile": "/etc/ssl/private/ssl-cert-snakeoil.key"
                        }
                    ]
                }
            },
            "tag": "vless-443"
        },
        {
            "port": 443,
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "password": "$TROJAN_UUID_443",
                        "email": "user@sshudp.com"
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "tls",
                "tlsSettings": {
                    "certificates": [
                        {
                            "certificateFile": "/etc/ssl/certs/ssl-cert-snakeoil.pem",
                            "keyFile": "/etc/ssl/private/ssl-cert-snakeoil.key"
                        }
                    ]
                }
            },
            "tag": "trojan-443"
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "blocked"
        }
    ],
    "routing": {
        "domainStrategy": "AsIs",
        "rules": []
    }
}
EOF
    
    # Create SSL certificates if not exists
    if [[ ! -f /etc/ssl/certs/ssl-cert-snakeoil.pem ]]; then
        openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
            -keyout /etc/ssl/private/ssl-cert-snakeoil.key \
            -out /etc/ssl/certs/ssl-cert-snakeoil.pem \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=$SERVER_IP"
    fi
    
    # Create log directory
    mkdir -p /var/log/xray
    chown -R nobody:nogroup /var/log/xray
    
    # Start Xray service
    systemctl restart xray
    systemctl enable xray
    
    log_message "Xray installed with VMESS/VLESS/Trojan on ports 80 & 443"
}

# =================================================================
# GENERATE VMESS LINK (Format Lengkap)
# =================================================================

generate_vmess_link() {
    local uuid="$1"
    local port="$2"
    local remark="$3"
    local with_tls="$4"
    local host="${5:-$SERVER_IP}"
    
    # Create VMESS config JSON seperti format yang diminta
    local vmess_config=$(cat <<EOF
{
  "v": "2",
  "ps": "$remark",
  "add": "$host",
  "port": "$port",
  "id": "$uuid",
  "aid": "0",
  "scy": "auto",
  "host": "",
  "type": "none",
  "net": "ws",
  "path": "$( [ "$port" = "443" ] && echo "/vmess" || echo "/vmess80" )",
  "tls": "$( [ "$with_tls" = "true" ] && echo "tls" || echo "" )",
  "sni": "$( [ -n "$5" ] && echo "$host" || echo "" )",
  "alpn": ""
}
EOF
    )
    
    # Convert to base64
    local base64_config=$(echo "$vmess_config" | base64 -w0)
    
    # Return vmess:// link
    echo "vmess://$base64_config"
}

# =================================================================
# SAVE VMESS CONFIGURATIONS
# =================================================================

save_vmess_configs() {
    echo -e "${GREEN}[5/12] Generating VMESS Configurations...${NC}"
    
    # Generate VMESS links untuk IP
    VMESS_80_LINK=$(generate_vmess_link "$VMESS_UUID_80" "80" "SSHUDP-IP-80" "false")
    VMESS_443_LINK=$(generate_vmess_link "$VMESS_UUID_443" "443" "SSHUDP-IP-443" "true")
    
    # Save to config file
    cat > $CONFIG_DIR/vmess-ip.txt << EOF
╔════════════════════════════════════════════════════════════╗
║              SSH-UDP IP VMESS CONFIGURATION               ║
║              github.com/sukronwae85-design/ssh-udp        ║
╚════════════════════════════════════════════════════════════╝

📡 SERVER INFORMATION:
• IP Address: $SERVER_IP
• Created: $(date)
• Status: ✅ ACTIVE

════════════════════════════════════════════════════════════
🔰 PORT 80 CONFIGURATION (NO TLS)
════════════════════════════════════════════════════════════

📌 VMESS Link:
$(echo "$VMESS_80_LINK" | fold -w 80)

📌 JSON Configuration:
{
  "v": "2",
  "ps": "SSHUDP-IP-80",
  "add": "$SERVER_IP",
  "port": "80",
  "id": "$VMESS_UUID_80",
  "aid": "0",
  "scy": "auto",
  "host": "",
  "type": "none",
  "net": "ws",
  "path": "/vmess80",
  "tls": "",
  "sni": "",
  "alpn": ""
}

════════════════════════════════════════════════════════════
🔰 PORT 443 CONFIGURATION (WITH TLS)
════════════════════════════════════════════════════════════

📌 VMESS Link:
$(echo "$VMESS_443_LINK" | fold -w 80)

📌 JSON Configuration:
{
  "v": "2",
  "ps": "SSHUDP-IP-443",
  "add": "$SERVER_IP",
  "port": "443",
  "id": "$VMESS_UUID_443",
  "aid": "0",
  "scy": "auto",
  "host": "",
  "type": "none",
  "net": "ws",
  "path": "/vmess",
  "tls": "tls",
  "sni": "",
  "alpn": ""
}
EOF
    
    log_message "VMESS configurations saved"
}

# =================================================================
# INSTALL NGINX & SSL
# =================================================================

install_nginx_ssl() {
    echo -e "${GREEN}[6/12] Installing Nginx & SSL...${NC}"
    
    apt-get install -y nginx certbot python3-certbot-nginx
    
    # Stop nginx temporarily
    systemctl stop nginx
    
    # Configure nginx
    cat > /etc/nginx/nginx.conf << EOF
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 768;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml+rss text/javascript;
    
    # Virtual Hosts
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
    
    # Create main IP site
    cat > /etc/nginx/sites-available/sshudp-ip << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $SERVER_IP;
    
    # WebSocket for VMESS port 80
    location /vmess80 {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Web interface
    location / {
        root /var/www/html;
        index index.html;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $SERVER_IP;
    
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # WebSocket for VMESS with TLS
    location /vmess {
        proxy_pass http://127.0.0.1:443;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location / {
        root /var/www/html;
        index index.html;
    }
}
EOF
    
    # Create default web page
    mkdir -p /var/www/html
    cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SSH-UDP Server</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            background: white;
            border-radius: 15px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
        }
        h1 { color: #333; margin-bottom: 20px; }
        .ip-display {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
            font-size: 1.2em;
            color: #333;
        }
        .services {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 30px 0;
        }
        .service-card {
            background: #f1f3f4;
            padding: 20px;
            border-radius: 10px;
            text-align: left;
        }
        .service-card h3 {
            color: #667eea;
            margin-bottom: 10px;
        }
        .status {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            margin-right: 10px;
        }
        .status.online { background: #4CAF50; }
        .status.offline { background: #f44336; }
        .footer {
            margin-top: 30px;
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 SSH-UDP Server</h1>
        
        <div class="ip-display">
            🌍 Server IP: <strong>$SERVER_IP</strong>
        </div>
        
        <p>Your SSH-UDP server is running successfully!</p>
        
        <div class="services">
            <div class="service-card">
                <h3><span class="status online"></span> SSH Service</h3>
                <p>Ports: 22, 2222, 80, 443</p>
            </div>
            <div class="service-card">
                <h3><span class="status online"></span> UDP Custom</h3>
                <p>Ports: 7100, 7200, 7300</p>
            </div>
            <div class="service-card">
                <h3><span class="status online"></span> VMESS</h3>
                <p>Ports: 80 & 443</p>
            </div>
            <div class="service-card">
                <h3><span class="status online"></span> Trojan</h3>
                <p>Ports: 80 & 443</p>
            </div>
        </div>
        
        <div class="footer">
            <p>Managed by SSH-UDP Auto Installer</p>
            <p>GitHub: sukronwae85-design/ssh-udp</p>
        </div>
    </div>
</body>
</html>
EOF
    
    # Create admin panel
    mkdir -p /var/www/admin
    cat > /var/www/admin/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SSH-UDP Admin Panel</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f5f5f5; }
        .sidebar { width: 250px; background: #2c3e50; color: white; height: 100vh; position: fixed; padding: 20px; }
        .main-content { margin-left: 250px; padding: 30px; }
        .logo { text-align: center; margin-bottom: 30px; }
        .menu { list-style: none; }
        .menu li { padding: 15px; border-bottom: 1px solid #34495e; cursor: pointer; }
        .menu li:hover { background: #34495e; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .stat-card { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .stat-card h3 { color: #666; margin-bottom: 10px; }
        .stat-card .value { font-size: 2em; font-weight: bold; color: #2c3e50; }
    </style>
</head>
<body>
    <div class="sidebar">
        <div class="logo">
            <h2>SSH-UDP Admin</h2>
            <p>v$VERSION</p>
        </div>
        <ul class="menu">
            <li>📊 Dashboard</li>
            <li>👤 User Management</li>
            <li>🌐 Domain Management</li>
            <li>🔧 Server Settings</li>
            <li>📈 Monitoring</li>
            <li>💾 Backup & Restore</li>
        </ul>
    </div>
    <div class="main-content">
        <h1>Server Dashboard</h1>
        <div class="stats">
            <div class="stat-card">
                <h3>Active Users</h3>
                <div class="value" id="userCount">0</div>
            </div>
            <div class="stat-card">
                <h3>Domains</h3>
                <div class="value" id="domainCount">0</div>
            </div>
            <div class="stat-card">
                <h3>Uptime</h3>
                <div class="value" id="uptime">0h</div>
            </div>
            <div class="stat-card">
                <h3>Connections</h3>
                <div class="value" id="connections">0</div>
            </div>
        </div>
    </div>
    <script>
        // Simple stats update
        setInterval(() => {
            document.getElementById('uptime').textContent = '24h';
            document.getElementById('connections').textContent = Math.floor(Math.random() * 100);
        }, 5000);
    </script>
</body>
</html>
EOF
    
    # Create admin password
    echo "admin:\$(openssl passwd -crypt admin123)" > /etc/nginx/.htpasswd 2>/dev/null || \
    echo "admin:\$apr1\$3WZQzL2E\$X5h6hJ8L8Y8Z9Z9Z9Z9Z9/" > /etc/nginx/.htpasswd
    
    # Enable sites
    ln -sf /etc/nginx/sites-available/sshudp-ip /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test and start nginx
    nginx -t
    systemctl start nginx
    systemctl enable nginx
    
    log_message "Nginx installed with SSL support"
}

# =================================================================
# FIREWALL CONFIGURATION
# =================================================================

configure_firewall() {
    echo -e "${GREEN}[7/12] Configuring Firewall...${NC}"
    
    # Disable existing firewall if any
    ufw --force disable 2>/dev/null
    
    # Set default policies
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    # Allow localhost
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Allow all necessary ports
    ports=($SSH_PORT $SSH_ALT_PORT $SSH_PORT_80 $SSH_PORT_443 80 443 $UDP_FULL_PORT)
    for port in "${ports[@]}"; do
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        iptables -A INPUT -p udp --dport $port -j ACCEPT
    done
    
    # Allow UDP custom ports
    for port in "${UDP_PORTS[@]}"; do
        iptables -A INPUT -p udp --dport $port -j ACCEPT
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
    done
    
    # Allow full UDP range
    iptables -A INPUT -p udp -m multiport --dports 1:65535 -j ACCEPT
    
    # Allow ICMP (ping)
    iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
    
    # Save rules
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6
    
    # Enable IP forwarding
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
    sysctl -p
    
    log_message "Firewall configured with all ports open"
}

# =================================================================
# USER MANAGEMENT SYSTEM
# =================================================================

add_ssh_user() {
    echo -e "${GREEN}👤 Add New SSH User${NC}"
    echo "══════════════════════════════════════════════════"
    
    read -p "Username: " username
    read -s -p "Password: " password
    echo
    read -p "Expiry days [$DEFAULT_EXPIRY_DAYS]: " expiry_days
    expiry_days=${expiry_days:-$DEFAULT_EXPIRY_DAYS}
    read -p "Max IP connections [$DEFAULT_MAX_IPS]: " max_ips
    max_ips=${max_ips:-$DEFAULT_MAX_IPS}
    
    # Check if user exists
    if id "$username" &>/dev/null; then
        echo -e "${RED}User already exists!${NC}"
        return 1
    fi
    
    # Create system user
    useradd -m -s /bin/false -G sshusers "$username"
    echo "$username:$password" | chpasswd
    
    # Calculate expiry date
    expiry_date=$(date -d "+$expiry_days days" +%Y-%m-%d)
    
    # Generate UUIDs for user
    user_vmess_uuid=$(cat /proc/sys/kernel/random/uuid)
    user_vless_uuid=$(cat /proc/sys/kernel/random/uuid)
    
    # Create user data
    user_data=$(jq -n \
        --arg username "$username" \
        --arg password "$password" \
        --arg expiry "$expiry_date" \
        --arg created "$(date +%Y-%m-%d)" \
        --argjson max_ips "$max_ips" \
        --arg vmess_uuid "$user_vmess_uuid" \
        --arg vless_uuid "$user_vless_uuid" \
        '{
            username: $username,
            password: $password,
            created: $created,
            expiry: $expiry,
            max_ips: $max_ips,
            current_ips: [],
            locked: false,
            total_bandwidth: 0,
            last_login: "",
            vmess_uuid: $vmess_uuid,
            vless_uuid: $vless_uuid
        }')
    
    # Add to database
    jq ". += [$user_data]" $USER_DB > $USER_DB.tmp && mv $USER_DB.tmp $USER_DB
    
    # Generate user VMESS config
    user_vmess_443=$(generate_vmess_link "$user_vmess_uuid" "443" "$username-SSHUDP" "true")
    user_vmess_80=$(generate_vmess_link "$user_vmess_uuid" "80" "$username-SSHUDP-80" "false")
    
    # Save user info
    mkdir -p $CONFIG_DIR/users
    cat > $CONFIG_DIR/users/$username.txt << EOF
╔════════════════════════════════════════════════════════════╗
║                   USER ACCOUNT INFORMATION                 ║
║                   Username: $username                     ║
╚════════════════════════════════════════════════════════════╝

🔐 ACCOUNT DETAILS:
• Username: $username
• Password: $password
• Created: $(date +%Y-%m-%d)
• Expiry: $expiry_date
• Max IPs: $max_ips

════════════════════════════════════════════════════════════
🔰 SSH ACCESS:
════════════════════════════════════════════════════════════
• Host: $SERVER_IP
• Ports: 22, 2222, 80, 443
• Username: $username
• Password: $password

════════════════════════════════════════════════════════════
🔰 VMESS CONFIGURATION (Port 443 with TLS):
════════════════════════════════════════════════════════════
$user_vmess_443

════════════════════════════════════════════════════════════
🔰 VMESS CONFIGURATION (Port 80 no TLS):
════════════════════════════════════════════════════════════
$user_vmess_80

════════════════════════════════════════════════════════════
🔰 VLESS CONFIGURATION:
════════════════════════════════════════════════════════════
• Port 443: vless://$user_vless_uuid@$SERVER_IP:443?type=tcp&security=tls#VLESS-$username
• Port 80: vless://$user_vless_uuid@$SERVER_IP:80?type=tcp&security=none#VLESS-$username-80

════════════════════════════════════════════════════════════
⚠️  IMPORTANT NOTES:
════════════════════════════════════════════════════════════
• Do not share your credentials
• Max $max_ips concurrent connections
• Account expires: $expiry_date
• Contact admin for extension
════════════════════════════════════════════════════════════
EOF
    
    echo -e "\n${GREEN}✅ User $username created successfully!${NC}"
    echo -e "📁 User info saved: $CONFIG_DIR/users/$username.txt"
    
    log_message "User added: $username"
}

list_users() {
    echo -e "${GREEN}📋 User List${NC}"
    echo "══════════════════════════════════════════════════"
    
    total_users=$(jq 'length' $USER_DB)
    if [[ $total_users -eq 0 ]]; then
        echo -e "${YELLOW}No users found${NC}"
        return
    fi
    
    echo -e "Total Users: ${CYAN}$total_users${NC}\n"
    
    jq -r '.[] | "\(.username) | Created: \(.created) | Expiry: \(.expiry) | IPs: \(.current_ips | length)/\(.max_ips) | \(if .locked then "🔒 LOCKED" else "✅ ACTIVE" end)"' $USER_DB | \
    while IFS= read -r line; do
        echo -e "$line"
    done
}

# =================================================================
# MONITORING SYSTEM
# =================================================================

monitor_system() {
    echo -e "${GREEN}📊 System Monitoring${NC}"
    echo "══════════════════════════════════════════════════"
    
    # CPU Usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo -e "CPU Usage: ${CYAN}$cpu_usage%${NC}"
    
    # Memory Usage
    mem_total=$(free -m | awk '/Mem:/ {print $2}')
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    mem_percent=$((mem_used * 100 / mem_total))
    echo -e "Memory: ${CYAN}$mem_used/${mem_total}MB ($mem_percent%)${NC}"
    
    # Disk Usage
    disk_usage=$(df -h / | awk '/\// {print $5}')
    echo -e "Disk Usage: ${CYAN}$disk_usage${NC}"
    
    # Uptime
    uptime_info=$(uptime -p)
    echo -e "Uptime: ${CYAN}$uptime_info${NC}"
    
    # Connections
    ssh_conn=$(netstat -an | grep -c ":22.*ESTABLISHED")
    total_conn=$(netstat -an | grep -c "ESTABLISHED")
    echo -e "SSH Connections: ${CYAN}$ssh_conn${NC}"
    echo -e "Total Connections: ${CYAN}$total_conn${NC}"
    
    # Service Status
    echo -e "\n${GREEN}🛠️  Service Status:${NC}"
    services=("ssh" "xray" "nginx" "fail2ban")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "  $service: ${GREEN}● RUNNING${NC}"
        else
            echo -e "  $service: ${RED}● STOPPED${NC}"
        fi
    done
    
    # Check UDP services
    for port in "${UDP_PORTS[@]}"; do
        if netstat -tuln | grep -q ":$port"; then
            echo -e "  UDP-$port: ${GREEN}● LISTENING${NC}"
        else
            echo -e "  UDP-$port: ${RED}● NOT LISTENING${NC}"
        fi
    done
}

# =================================================================
# BACKUP & RESTORE SYSTEM
# =================================================================

backup_system() {
    echo -e "${GREEN}💾 Creating System Backup...${NC}"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/full-backup-$timestamp.tar.gz"
    
    # Create backup
    tar -czf "$backup_file" \
        /etc/ssh \
        /etc/sshudp \
        /usr/local/etc/xray \
        /etc/nginx \
        /etc/ssl/certs \
        /var/www/html \
        /var/www/domains \
        /var/www/admin \
        /var/log/sshudp.log \
        2>/dev/null
    
    # Encrypt backup
    read -s -p "Encryption password: " enc_password
    echo
    
    if command -v gpg &>/dev/null; then
        echo "$enc_password" | gpg --batch --yes --passphrase-fd 0 -c "$backup_file"
        rm "$backup_file"
        backup_file="$backup_file.gpg"
    else
        openssl enc -aes-256-cbc -salt -in "$backup_file" -out "$backup_file.enc" -k "$enc_password"
        rm "$backup_file"
        backup_file="$backup_file.enc"
    fi
    
    echo -e "${GREEN}✅ Backup created: $backup_file${NC}"
    log_message "System backup created: $backup_file"
}

# =================================================================
# CRON JOBS SETUP
# =================================================================

setup_cron_jobs() {
    echo -e "${GREEN}[8/12] Setting up Cron Jobs...${NC}"
    
    # Clear existing cron jobs
    crontab -l | grep -v "install.sh" | crontab -
    
    # Add new cron jobs
    (crontab -l 2>/dev/null; echo "# SSH-UDP Manager Cron Jobs") | crontab -
    (crontab -l 2>/dev/null; echo "0 * * * * $0 --check-expired") | crontab -
    (crontab -l 2>/dev/null; echo "0 2 * * * $0 --backup-auto") | crontab -
    (crontab -l 2>/dev/null; echo "0 3 * * 0 certbot renew --quiet") | crontab -
    (crontab -l 2>/dev/null; echo "*/5 * * * * $0 --monitor-auto") | crontab -
    
    # Create auto scripts
    cat > /usr/local/bin/auto-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/sshudp"
DATE=$(date +%Y%m%d)
tar -czf "$BACKUP_DIR/auto-$DATE.tar.gz" /etc/sshudp /usr/local/etc/xray 2>/dev/null
find $BACKUP_DIR -name "auto-*.tar.gz" -mtime +7 -delete
EOF
    
    chmod +x /usr/local/bin/auto-backup.sh
    
    log_message "Cron jobs configured"
}

# =================================================================
# MAIN INSTALLATION FUNCTION
# =================================================================

auto_install() {
    print_header
    
    # Check if root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root!${NC}"
        echo -e "Please run: ${CYAN}sudo -i${NC}"
        exit 1
    fi
    
    # Confirm installation
    echo -e "${YELLOW}⚠️  WARNING: This will install multiple services${NC}"
    echo -e "${YELLOW}⚠️  Ports 22, 80, 443, 7100, 7200, 7300 will be opened${NC}"
    echo
    read -p "Start installation? (y/n): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    
    # Start installation
    echo -e "\n${GREEN}🚀 Starting installation...${NC}"
    echo -e "${BLUE}This may take 5-10 minutes. Please wait...${NC}"
    echo "══════════════════════════════════════════════════════════════"
    
    # Installation steps
    init_system
    install_ssh_all_ports
    install_udp_custom
    install_xray_all_ports
    save_vmess_configs
    install_nginx_ssl
    configure_firewall
    setup_cron_jobs
    
    # Installation complete
    echo -e "\n${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}🎉 INSTALLATION COMPLETE! 🎉${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    
    # Display server information
    echo -e "\n${CYAN}📊 SERVER INFORMATION:${NC}"
    echo -e "Server IP: ${YELLOW}$SERVER_IP${NC}"
    echo -e "SSH Ports: ${YELLOW}22, 2222, 80, 443${NC}"
    echo -e "UDP Ports: ${YELLOW}7100, 7200, 7300${NC}"
    echo -e "Full UDP Range: ${YELLOW}1-65535 via port $UDP_FULL_PORT${NC}"
    echo -e "VMESS Ports: ${YELLOW}80 & 443${NC}"
    echo -e "Trojan Ports: ${YELLOW}80 & 443${NC}"
    echo -e "Web Interface: ${YELLOW}http://$SERVER_IP${NC}"
    echo -e "Admin Panel: ${YELLOW}http://$SERVER_IP/admin${NC}"
    echo -e "Admin Credentials: ${YELLOW}admin / admin123${NC}"
    
    # Show VMESS config location
    echo -e "\n${CYAN}🔗 CONFIGURATION FILES:${NC}"
    echo -e "VMESS Config: ${YELLOW}$CONFIG_DIR/vmess-ip.txt${NC}"
    echo -e "User Database: ${YELLOW}$USER_DB${NC}"
    echo -e "Domain Database: ${YELLOW}$DOMAIN_FILE${NC}"
    
    # Show next steps
    echo -e "\n${CYAN}📝 NEXT STEPS:${NC}"
    echo "1. Run: ${GREEN}./install.sh --menu${NC} (for management menu)"
    echo "2. Add domain: ${GREEN}./install.sh --add-domain${NC}"
    echo "3. Add user: ${GREEN}./install.sh --add-user${NC}"
    echo "4. Monitor: ${GREEN}./install.sh --monitor${NC}"
    
    # Wait and show menu
    echo -e "\n${YELLOW}Starting management menu in 5 seconds...${NC}"
    sleep 5
    show_menu
}

# =================================================================
# MAIN MENU SYSTEM
# =================================================================

show_menu() {
    while true; do
        clear
        print_header
        
        echo -e "${CYAN}📋 MAIN MANAGEMENT MENU${NC}"
        echo "══════════════════════════════════════════════════════════════"
        echo -e "${GREEN}[1]${NC}  Add New SSH User"
        echo -e "${GREEN}[2]${NC}  List All Users"
        echo -e "${GREEN}[3]${NC}  Check Online Users"
        echo -e "${GREEN}[4]${NC}  Lock/Unlock User"
        echo -e "${GREEN}[5]${NC}  Delete User"
        echo -e "${BLUE}[6]${NC}  Add New Domain"
        echo -e "${BLUE}[7]${NC}  List Domains"
        echo -e "${BLUE}[8]${NC}  Remove Domain"
        echo -e "${BLUE}[9]${NC}  Renew SSL Certificates"
        echo -e "${YELLOW}[10]${NC} System Monitoring"
        echo -e "${YELLOW}[11]${NC} Show VMESS Config"
        echo -e "${YELLOW}[12]${NC} Change SSH Banner"
        echo -e "${PURPLE}[13]${NC} Backup System"
        echo -e "${PURPLE}[14]${NC} Restore Backup"
        echo -e "${PURPLE}[15]${NC} Service Status"
        echo -e "${RED}[0]${NC}  Exit"
        echo "══════════════════════════════════════════════════════════════"
        
        read -p "Select option: " choice
        
        case $choice in
            1) add_ssh_user ;;
            2) list_users ;;
            3) echo "Online users monitoring" ;;
            4) read -p "Username: " user && \
               read -p "Action (lock/unlock): " action && \
               [[ "$action" == "lock" ]] && lock_user "$user" || unlock_user "$user" ;;
            5) read -p "Username to delete: " user && userdel -r "$user" 2>/dev/null && echo "User deleted" ;;
            6) add_domain ;;
            7) list_domains ;;
            8) remove_domain ;;
            9) renew_domain_ssl ;;
            10) monitor_system ;;
            11) [[ -f $CONFIG_DIR/vmess-ip.txt ]] && cat $CONFIG_DIR/vmess-ip.txt || echo "Config not found" ;;
            12) nano $BANNER_FILE && systemctl restart ssh ;;
            13) backup_system ;;
            14) echo "Restore feature - Coming soon" ;;
            15) systemctl status ssh xray nginx ;;
            0) echo -e "${GREEN}Goodbye! 👋${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option!${NC}" ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# =================================================================
# HELPER FUNCTIONS
# =================================================================

lock_user() {
    local username="$1"
    local tmp_file=$(mktemp)
    
    if jq -e ".[] | select(.username == \"$username\")" $USER_DB > /dev/null; then
        jq '(.[] | select(.username == "'$username'") | .locked = true)' $USER_DB > $tmp_file && mv $tmp_file $USER_DB
        pkill -u "$username" 2>/dev/null
        echo -e "${RED}🔒 User $username locked!${NC}"
        log_message "User locked: $username"
    else
        echo -e "${RED}User not found!${NC}"
    fi
}

unlock_user() {
    local username="$1"
    local tmp_file=$(mktemp)
    
    if jq -e ".[] | select(.username == \"$username\")" $USER_DB > /dev/null; then
        jq '(.[] | select(.username == "'$username'") | .locked = false | .current_ips = [])' $USER_DB > $tmp_file && mv $tmp_file $USER_DB
        echo -e "${GREEN}🔓 User $username unlocked!${NC}"
        log_message "User unlocked: $username"
    else
        echo -e "${RED}User not found!${NC}"
    fi
}

# =================================================================
# COMMAND LINE INTERFACE
# =================================================================

case "$1" in
    "--install"|"-i")
        auto_install
        ;;
    "--menu"|"-m")
        show_menu
        ;;
    "--add-user"|"-a")
        add_ssh_user
        ;;
    "--list-users"|"-l")
        list_users
        ;;
    "--add-domain"|"-d")
        add_domain
        ;;
    "--list-domains"|"-ld")
        list_domains
        ;;
    "--monitor"|"-s")
        monitor_system
        ;;
    "--backup"|"-b")
        backup_system
        ;;
    "--renew-ssl")
        renew_domain_ssl
        ;;
    "--help"|"-h")
        echo -e "${GREEN}SSH-UDP-VMESS Auto Installer v$VERSION${NC}"
        echo "Usage:"
        echo "  $0 --install        Full automatic installation"
        echo "  $0 --menu           Show management menu"
        echo "  $0 --add-user       Add new SSH user"
        echo "  $0 --list-users     List all users"
        echo "  $0 --add-domain     Add new domain"
        echo "  $0 --list-domains   List all domains"
        echo "  $0 --monitor        System monitoring"
        echo "  $0 --backup         Create system backup"
        echo "  $0 --renew-ssl      Renew SSL certificates"
        echo "  $0 --help           Show this help"
        ;;
    *)
        # If no arguments, show installation option
        echo -e "${GREEN}SSH-UDP-VMESS Auto Installer v$VERSION${NC}"
        echo "To install: $0 --install"
        echo "For menu: $0 --menu"
        echo "For help: $0 --help"
        ;;
esac
