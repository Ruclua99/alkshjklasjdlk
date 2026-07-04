#!/bin/bash
# ==============================================================================
# COPY VA CHAY DONG LENH DUOI DAY DE CAI DAT TU DONG:
# apt update -y && apt install -y curl wget && curl -sL https://url.vth.app/vps | bash
# ==============================================================================
# Dinh nghia mau sac (ANSI Colors)
C_GREEN='\e[32m'
C_BLUE='\e[34m'
C_YELLOW='\e[33m'
C_CYAN='\e[36m'
C_RESET='\e[0m'
C_BOLD='\e[1m'

# 1. Kiem tra quyen root
if [ "$EUID" -ne 0 ]; then
  echo -e "${C_YELLOW}Loi: Ban can chay script nay duoi quyen root (su).${C_RESET}"
  exit 1
fi

# 2. Hien thi Menu chon tinh nang bang whiptail
CHOICES=$(whiptail --title " CONG CU CAI DAT SERVER TU DONG (ALL-IN-ONE) " --checklist \
"Huong dan su dung:\n [v] Phim LEN/XUONG de di chuyen.\n [v] Phim SPACE (Dau cach) de Chon/Bo chon.\n [v] Phim ENTER de bat dau cai dat.\n\nChon cac tinh nang va ung dung mong muon:" 24 75 14 \
"Fix_Network" "Sua loi mang & Fix DNS (Khuyen dung)" ON \
"Basic_Tools" "Cap nhat OS & Cai tools (htop, unzip...)" ON \
"Enable_SSH" "Cho phep dang nhap SSH Root bang mat khau" ON \
"Setup_MOTD" "Hien thong bao OS, IP giong Proxmox luc login" ON \
"Nginx" "Cai dat may chu Nginx" OFF \
"NodeJS" "Cai dat Node.js 20.x LTS & NPM" OFF \
"PM2" "Cai dat PM2 (Yeu cau phai chon NodeJS)" OFF \
"Docker" "Cai dat Docker & Docker Compose" OFF \
"Python3" "Cai dat Python 3 & PIP" OFF \
"MariaDB" "Cai dat Database MariaDB (Tuong tu MySQL)" OFF \
"Config_UFW" "Bat tuong lua (Tu dong mo port 22, 80, 443)" OFF \
"Add_Swap" "Tao 2GB RAM ao (Swap) chong treo may" OFF \
3>&1 1>&2 2>&3)

if [ -z "$CHOICES" ]; then
  echo -e "\n${C_YELLOW}>> DA HUY BO. KHONG CO THAY DOI NAO DUOC THUC HIEN.${C_RESET}\n"
  exit 0
fi

CHOICES=$(echo $CHOICES | sed 's/"//g')
export DEBIAN_FRONTEND=noninteractive

clear
echo -e "${C_CYAN}${C_BOLD}"
echo "   _____ _________________    __________________ "
echo "  / ___// ____/ __ \ | / /   / ___/ ____/_  __/ "
echo "  \__ \/ __/ / /_/ / |/ /    \__ \/ __/   / /    "
echo " ___/ / /___/ _, _/|   /    ___/ / /___  / /     "
echo "/____/_____/_/ |_| |__/____/____/_____/ /_/      "
echo "                     /_____/                     "
echo -e "${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}>>> BAT DAU QUA TRINH CAI DAT TUDONG <<<${C_RESET}\n"

for APP in $CHOICES; do
  echo -e "${C_BLUE}--------------------------------------------------${C_RESET}"
  echo -e "${C_YELLOW}[+] DANG XU LY: ${APP}...${C_RESET}"
  echo -e "${C_BLUE}--------------------------------------------------${C_RESET}"
  
  case $APP in
    Fix_Network)
      rm -f /etc/resolv.conf
      echo "nameserver 8.8.8.8" > /etc/resolv.conf
      echo "nameserver 1.1.1.1" >> /etc/resolv.conf
      systemctl restart systemd-resolved || true
      sed -i 's/vn.vn.archive.ubuntu.com/archive.ubuntu.com/g' /etc/apt/sources.list
      sed -i 's/vn.archive.ubuntu.com/archive.ubuntu.com/g' /etc/apt/sources.list
      apt clean
      rm -rf /var/lib/apt/lists/*
      ;;
      
    Basic_Tools)
      apt update -y && apt upgrade -y
      apt install -y curl wget git vim nano htop tmux tree jq net-tools build-essential unzip zip rsync tar software-properties-common apt-transport-https ca-certificates fail2ban sysstat dnsutils
      ;;
      
    Enable_SSH)
      cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
      sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
      sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
      systemctl restart ssh
      ;;
      
    Setup_MOTD)
      cat << 'MOTD_EOF' > /etc/profile.d/custom_motd.sh
#!/bin/bash
OS_NAME=$(grep '^NAME=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
OS_VER=$(grep '^VERSION_ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
HOST_NAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')
C_CYAN='\e[36m'
C_YELLOW='\e[33m'
C_GREEN='\e[32m'
C_RESET='\e[0m'
C_BOLD='\e[1m'
echo -e "\n   🖥️   ${C_BOLD}${C_CYAN}OS:${C_RESET} $OS_NAME - ${C_BOLD}${C_CYAN}Version:${C_RESET} $OS_VER"
echo -e "   🏠   ${C_BOLD}${C_YELLOW}Hostname:${C_RESET} $HOST_NAME"
echo -e "   💡   ${C_BOLD}${C_GREEN}IP Address:${C_RESET} $IP_ADDRESS\n"
MOTD_EOF
      chmod +x /etc/profile.d/custom_motd.sh
      ;;
      
    Nginx)
      apt install -y nginx
      systemctl enable nginx
      systemctl start nginx
      ;;
      
    NodeJS)
      curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
      apt install -y nodejs
      npm install -g yarn
      ;;
      
    PM2)
      if command -v npm > /dev/null; then
        npm install -g pm2
      else
        echo -e "${C_YELLOW}[!] LOI: Chua co NPM. Vui long chon cai dat NodeJS.${C_RESET}"
      fi
      ;;
      
    Docker)
      curl -fsSL https://get.docker.com -o get-docker.sh
      sh get-docker.sh
      rm get-docker.sh
      systemctl enable docker
      ;;
      
    Python3)
      apt install -y python3 python3-pip
      ;;
      
    MariaDB)
      apt install -y mariadb-server
      systemctl enable mariadb
      systemctl start mariadb
      ;;
      
    Config_UFW)
      apt install -y ufw
      ufw allow 22/tcp
      ufw allow 80/tcp
      ufw allow 443/tcp
      ufw --force enable
      ;;
      
    Add_Swap)
      if [ -f /swapfile ]; then
        echo -e "${C_GREEN}[+] Swap file da ton tai! Bo qua...${C_RESET}"
      else
        fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
      fi
      ;;
      
    *)
      echo "Khong nhan dien duoc lua chon: $APP"
      ;;
  esac
done

echo -e "\n${C_GREEN}${C_BOLD}==================================================${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}   HOAN TAT TOAN BO QUA TRINH CAI DAT !${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}==================================================${C_RESET}"
LOCAL_IP=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(curl -s ifconfig.me)

echo -e "${C_CYAN}THONG TIN KET NOI CUA BAN:${C_RESET}"
echo -e "- IP Local (LAN)  : ${C_YELLOW}$LOCAL_IP${C_RESET}"
echo -e "- IP Public (WAN) : ${C_YELLOW}$PUBLIC_IP${C_RESET}\n"
echo -e "=> ${C_BOLD}Vui long tat terminal hien tai va SSH lai de xem nhung thay doi!${C_RESET}\n"
