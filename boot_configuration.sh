#!/bin/bash

# Verifica se o número de argumentos é igual a 2
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

# Função para verificar o SSID atual e alterá-lo se necessário
alterar_ssid() {
    local INTERFACE=$1
    local SSID_SUFFIX=$2

    local SSID_NAME_TEMP="$SSID_NAME $SSID_SUFFIX"

    local SSID_ATUAL=$(ssh root@$IP_ROUTER "uci get wireless.$INTERFACE.ssid")

    if [ "$SSID_ATUAL" != "$SSID_NAME_TEMP" ]; then
        echo "Alterando SSID da interface $INTERFACE de '$SSID_ATUAL' para '$SSID_NAME_TEMP'"
        ssh root@$IP_ROUTER "uci set wireless.$INTERFACE.ssid='$SSID_NAME_TEMP'"
        ssh root@$IP_ROUTER "uci commit wireless"
        ssh root@$IP_ROUTER "wifi"

        # Pausa para reconectar ao roteador após a alteração da SSID
        echo "Esperando 10 segundos para reconectar ao roteador após alterar a SSID..."
        sleep 10

        # Verifica a conectividade com o roteador
        ping -c 4 $IP_ROUTER > /dev/null

        if [ $? -ne 0 ]; then
            echo "Falha ao se reconectar ao roteador. Verifique a conexão Wi-Fi e tente novamente."
            exit 1
        fi
    else
        echo "SSID da interface $INTERFACE já está configurado como '$SSID_NAME_TEMP'"
    fi
}

# Altera o SSID para as redes 2.4Ghz e 5Ghz
alterar_ssid "@wifi-iface[0]"  "5G" # Geralmente 5GHz
alterar_ssid "@wifi-iface[1]" "2.4G" # Geralmente 2.4GHz

# Clonando projeto
echo "Clonando projeto..."
ssh_router "rm -rf /root/vanlife-openwrt"
ssh_router "rm -rf /www"
ssh_router "git clone https://github.com/agnes-it/vanlife-openwrt.git"
ssh_router "ln -sf /root/vanlife-openwrt/www /www"

echo "Configuração concluída com sucesso."

