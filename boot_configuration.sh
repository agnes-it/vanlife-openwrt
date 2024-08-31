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
	return 0
    else
        echo "SSID da interface $INTERFACE já está configurado como '$SSID_NAME_TEMP'"
	return 1
    fi
}

# Altera o SSID para as redes 2.4Ghz e 5Ghz
alterar_ssid "@wifi-iface[0]"  "5G" # Geralmente 5GHz
alterar_ssid "@wifi-iface[1]" "2.4G" # Geralmente 2.4GHz

# Altera o SSID para as redes guest 2.4Ghz e 5Ghz
alterar_ssid "@wifi-iface[2]" "Guest 5G"
alterar_ssid "@wifi-iface[3]" "Guest 2.4G"

RESULT=$?
if [ $RESULT == 0 ]; then
    # aplicando 1 vez
    echo "Rede será reiniciada. Aguarde o comando terminar... Reconecte a wifi com o novo nome e rode o comando novamente."

    ssh root@$IP_ROUTER "uci commit wireless"
    ssh root@$IP_ROUTER "wifi"

    exit 0
fi

# Clonando projeto
echo "Clonando projeto..."
ssh_router "rm -rf /root/vanlife-openwrt"
ssh_router "rm -rf /www"
ssh_router "git clone https://github.com/agnes-it/vanlife-openwrt.git"
ssh_router "ln -sf /root/vanlife-openwrt/www /www"

echo "Configuração concluída com sucesso."

