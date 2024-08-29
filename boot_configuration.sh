#!/bin/bash

# Verifica se o número de argumentos é igual a 3
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <IP_do_roteador> <Nome_da_SSID>"
    exit 1
fi

# Atribui os argumentos a variáveis
IP_ROUTER=$1
SSID_NAME=$2

# Função para realizar um comando via SSH no roteador
function ssh_router() {
    ssh root@$IP_ROUTER "$@"
}

# Instala o openssh-sftp-server e git no roteador
echo "Instalando openssh-sftp-server e git no roteador..."
ssh_router "opkg update && opkg install openssh-sftp-server git git-http ca-bundle"

# Obtém o SSID atual do roteador
CURRENT_SSID=$(ssh_router "uci get wireless.@wifi-iface[0].ssid")

if [ "$CURRENT_SSID" == "$SSID_NAME" ]; then
    echo "SSID já está configurado como '$SSID_NAME'. Pulando a configuração da SSID."
else
    # Define a SSID no roteador
    echo "Definindo o nome da SSID como '$SSID_NAME'..."
    ssh_router "uci set wireless.@wifi-iface[0].ssid='$SSID_NAME'"
    ssh_router "uci commit wireless"
    ssh_router "wifi"

    # Pausa para reconectar ao roteador após a alteração da SSID
    echo "Esperando 10 segundos para reconectar ao roteador após alterar a SSID..."
    sleep 10

    # Verifica a conectividade com o roteador
    ping -c 4 $IP_ROUTER > /dev/null

    if [ $? -ne 0 ]; then 
        echo "Falha ao se reconectar ao roteador. Verifique a conexão Wi-Fi e tente novamente."
        exit 1
    fi
fi

# Clonando projeto
echo "Clonando projeto..."
ssh_router "rm -rf /www"
ssh_router "git clone https://github.com/agnes-it/vanlife-openwrt.git"
ssh_router "ln -sf /root/vanlife-openwrt/www /www"

echo "Configuração concluída com sucesso."

