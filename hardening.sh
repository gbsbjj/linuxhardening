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