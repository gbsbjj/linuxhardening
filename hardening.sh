#!/bin/bash

# Nome: hardening
# Descrição: Script de automação para aplicação de hardening de servidores linux
# seja para as distribuições da família RHEL ou distribuições baseadas em Debian.
# Referência: CIS Benchmark
# Autor: Gabriel Henrique
# Versão: 1.1

# Função para exibir ASCII art e informações do menu
show_menu() {
  clear
  echo -e "\e[1;34m===================================================\e[0m"
  echo -e "\e[1;32m   Linux Hardening - Script de Automação para Servidores\e[0m"
  echo -e "\e[1;34m===================================================\e[0m"
  echo -e "\e[1;33mUsuário:\e[0m $(whoami)"
  echo -e "\e[1;33mData e Hora de Execução:\e[0m $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "\e[1;34m===================================================\e[0m"
  echo -e "\e[1;36mEscolha a opção:\e[0m"
  echo ""
  echo -e "   \e[1;32m1.\e[0m Hardening no CentOS/RHEL"
  echo -e "   \e[1;32m2.\e[0m Hardening no Ubuntu/Debian"
  echo -e "   \e[1;31m3.\e[0m Sair"
  echo -e "\e[1;34m===================================================\e[0m"
}

# Função para o script de hardening CentOS/RHEL
hdng__rhel() {
  echo "Aplicando o Hardening ao Sistema Linux CentOS/RHEL..."

  # Passo 1
  echo -e "\e[33mDocumentando informações do host...\e[0m"

  info_file="information_host.txt"

  echo "Data e Hora: $(date '+%Y-%m-%d %H:%M:%S')" > "$info_file"

{
  echo "Hostname: $(hostname)"
  echo "Endereço IP: $(hostname -I)"
  echo "Sistema Operacional: $(cat /etc/redhat-release || cat /etc/os-release)"
  echo "Espaço em Disco: $(df -h | grep '^/' | awk '{print $1, $2, $3, $4, $5}')"
  echo "Versão do Kernel: $(uname -r)"
  echo "Status do Firewall: $(sudo systemctl is-active firewalld || echo "firewalld não instalado")"
  echo "Status do SELinux: $(sestatus | awk '{print $3}')"
} >> "$info_file"


  # Passo 2: Atualizar o sistema
  echo -e "\e[33mAtualizando o SO...\e[0m"
  yum update -y
  echo
 
  # Passo 3: Remover serviços desnecessários
  echo -e "\e[33mRemovendo serviços desnecessários...\e[0m"

  servicos=(
  avahi-daemon.service
  cups.service
  dhcpd.service
  slapd.service
  named.service
  xinetd.service
  bluetooth.service
  cups-browsed.service
  proftpd.service
  vsftpd.service
)

for servico in "${servicos[@]}"; do
  if systemctl is-active --quiet "$servico"; then
    echo -e "\e[34mDesabilitando $servico...\e[0m"
    systemctl disable "$servico" && echo -e "\e[32m$servico desabilitado com sucesso.\e[0m" || echo -e "\e[31mFalha ao desabilitar $servico.\e[0m"
  else
    echo -e "\e[36m$servico já está inativo.\e[0m"
  fi
done

echo -e "\e[33mTodos os serviços desnecessários foram processados.\e[0m"

# Passo 4: Segurança do SSH
echo -e "\e[33mFortalecendo o SSH...\e[0m"

# Fazer backup do arquivo de configuração SSH
config_file="/etc/ssh/sshd_config"
backup_file="${config_file}.bak"


if cp "$config_file" "$backup_file"; then
  echo -e "\e[32mBackup do arquivo de configuração SSH criado em $backup_file\e[0m"
else
  echo -e "\e[31mFalha ao criar backup do arquivo de configuração SSH.\e[0m"
  exit 1
fi

echo -e "\e[34mDesabilitando autenticação por senha...\e[0m"
sed -i 's/^#\?PasswordAuthentication yes/PasswordAuthentication no/' "$config_file"

echo -e "\e[34mDesabilitando login de root via SSH...\e[0m"
sed -i 's/^#\?PermitRootLogin yes/PermitRootLogin no/' "$config_file"


# Reiniciar o serviço SSH
if systemctl restart sshd; then
  echo -e "\e[32mServiço SSH reiniciado com sucesso.\e[0m"
else
  echo -e "\e[31mFalha ao reiniciar o serviço SSH.\e[0m"
  exit 1
fi

echo -e "\e[32mConfigurações de segurança do SSH fortalecidas com sucesso!\e[0m"

# Passo 5: Configurar políticas de senha
echo -e "\e[33mConfigurando políticas de senha...\e[0m"
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs
echo -e "\e[32mPolíticas de senha configuradas com sucesso.\e[0m"

# Passo 6: Instalar e habilitar o auditd
echo -e "\e[33mInstalando e habilitando o auditd...\e[0m"
yum install -y audit
systemctl enable auditd
systemctl start auditd
echo -e "\e[32mAuditd instalado e habilitado com sucesso.\e[0m"

# Passo 7: Definir permissões em arquivos críticos
echo -e "\e[33mDefinindo permissões em arquivos críticos...\e[0m"
chmod 644 /etc/passwd
chmod 000 /etc/shadow
chmod 644 /etc/group
chmod 000 /etc/gshadow
echo -e "\e[32mPermissões de arquivos críticos definidas com sucesso.\e[0m"

# Passo 8: Configurar o firewalld
echo -e "\e[33mConfigurando o firewalld...\e[0m"
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --set-default-zone=public
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload
echo -e "\e[32mFirewalld configurado com sucesso.\e[0m"

  set_login_banner
  harden_network
  configure_auditd_rules
}

# Função para o script de hardening Debian/Ubuntu
hdng__debian() {
  echo "Aplicando o Hardening ao Sistema Linux Debian/Ubuntu..."

  # Passo 1
  echo -e "\e[33mDocumentando informações do host...\e[0m"

  info_file="information_host.txt"

  echo "Data e Hora: $(date '+%Y-%m-%d %H:%M:%S')" > "$info_file"

{
  echo "Hostname: $(hostname)"
  echo "Endereço IP: $(hostname -I)"
  echo "Sistema Operacional: $(cat /etc/lsb-release || cat /etc/os-release)"
  echo "Espaço em Disco: $(df -h | grep '^/' | awk '{print $1, $2, $3, $4, $5}')"
  echo "Versão do Kernel: $(uname -r)"
  echo "Status do Firewall: $(sudo ufw status || echo "ufw não instalado")"
} >> "$info_file"


  # Passo 2: Atualizar o sistema
  echo -e "\e[33mAtualizando o SO...\e[0m"
  apt-get update && apt-get upgrade -y
  echo

  # Passo 3: Remover serviços desnecessários
  echo -e "\e[33mRemovendo serviços desnecessários...\e[0m"

  servicos=(
  avahi-daemon
  cups
  isc-dhcp-server
  slapd
  bind9
  xinetd
  bluetooth
  cups-browsed
  proftpd-basic
  vsftpd
)

for servico in "${servicos[@]}"; do
  if systemctl is-active --quiet "$servico"; then
    echo -e "\e[34mDesabilitando $servico...\e[0m"
    systemctl disable "$servico" && echo -e "\e[32m$servico desabilitado com sucesso.\e[0m" || echo -e "\e[31mFalha ao desabilitar $servico.\e[0m"
  else
    echo -e "\e[36m$servico já está inativo.\e[0m"
  fi
done

echo -e "\e[33mTodos os serviços desnecessários foram processados.\e[0m"

# Passo 4: Segurança do SSH
echo -e "\e[33mFortalecendo o SSH...\e[0m"

# Fazer backup do arquivo de configuração SSH
config_file="/etc/ssh/sshd_config"
backup_file="${config_file}.bak"


if cp "$config_file" "$backup_file"; then
  echo -e "\e[32mBackup do arquivo de configuração SSH criado em $backup_file\e[0m"
else
  echo -e "\e[31mFalha ao criar backup do arquivo de configuração SSH.\e[0m"
  exit 1
fi

echo -e "\e[34mDesabilitando autenticação por senha...\e[0m"
sed -i 's/^#\?PasswordAuthentication yes/PasswordAuthentication no/' "$config_file"

echo -e "\e[34mDesabilitando login de root via SSH...\e[0m"
sed -i 's/^#\?PermitRootLogin yes/PermitRootLogin no/' "$config_file"


# Reiniciar o serviço SSH
if systemctl restart sshd; then
  echo -e "\e[32mServiço SSH reiniciado com sucesso.\e[0m"
else
  echo -e "\e[31mFalha ao reiniciar o serviço SSH.\e[0m"
  exit 1
fi

echo -e "\e[32mConfigurações de segurança do SSH fortalecidas com sucesso!\e[0m"

# Passo 5: Configurar políticas de senha
echo -e "\e[33mConfigurando políticas de senha...\e[0m"
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs
echo -e "\e[32mPolíticas de senha configuradas com sucesso.\e[0m"

# Passo 6: Instalar e habilitar o auditd
echo -e "\e[33mInstalando e habilitando o auditd...\e[0m"
apt-get install -y auditd
systemctl enable auditd
systemctl start auditd
echo -e "\e[32mAuditd instalado e habilitado com sucesso.\e[0m"

# Passo 7: Definir permissões em arquivos críticos
echo -e "\e[33mDefinindo permissões em arquivos críticos...\e[0m"
chmod 644 /etc/passwd
chmod 600 /etc/shadow
chmod 644 /etc/group
chmod 600 /etc/gshadow
echo -e "\e[32mPermissões de arquivos críticos definidas com sucesso.\e[0m"

# Passo 8: Configurar o ufw
echo -e "\e[33mConfigurando o ufw...\e[0m"
ufw enable
ufw allow ssh
ufw default deny incoming
ufw default allow outgoing
echo -e "\e[32mUFW configurado com sucesso.\e[0m"

  set_login_banner
  harden_network
  configure_auditd_rules
}

# Função para configurar o banner de login
set_login_banner() {
  echo -e "\e[33mConfigurando o banner de login...\e[0m"
  echo "Acesso restrito. Atividades monitoradas." > /etc/issue.net
  echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
  echo -e "\e[32mBanner de login configurado com sucesso.\e[0m"
}

# Função para fortalecer a configuração de rede
harden_network() {
  echo -e "\e[33mFortalecendo a configuração de rede (sysctl)...\e[0m"
  cat <<EOT > /etc/sysctl.d/99-hardening.conf
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
EOT
  sysctl -p /etc/sysctl.d/99-hardening.conf
  echo -e "\e[32mConfiguração de rede fortalecida com sucesso.\e[0m"
}

# Função para configurar regras do auditd
configure_auditd_rules() {
  echo -e "\e[33mConfigurando regras do auditd...\e[0m"
  cat <<EOT > /etc/audit/rules.d/99-hardening.rules
-w /etc/passwd -p wa -k passwd_changes
-w /etc/group -p wa -k group_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/ssh/sshd_config -p wa -k sshd_config_changes
-a always,exit -F arch=b64 -S execve -k command_executions
-a always,exit -F arch=b32 -S execve -k command_executions
-w /var/log/auth.log -p wa -k auth_log_changes
-w /var/log/secure -p wa -k secure_log_changes
EOT
  auditctl -R /etc/audit/rules.d/99-hardening.rules
  echo -e "\e[32mRegras do auditd configuradas com sucesso.\e[0m"
}

# Loop do menu
while true; do
  show_menu
  read -p "Digite sua opção: " choice
  case $choice in
    1)
      hdng__rhel
      read -p "Pressione Enter para continuar..."
      ;;
    2)
      hdng__debian
      read -p "Pressione Enter para continuar..."
      ;;
    3)
      echo "Saindo..."
      break
      ;;
    *)
      echo "Opção inválida!"
      read -p "Pressione Enter para continuar..."
      ;;
  esac
done