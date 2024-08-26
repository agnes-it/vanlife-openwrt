#!/bin/bash

# Verifica se o número de argumentos é igual a 3
if [ "$#" -ne 3 ]; then
    echo "Uso: $0 <IP_do_roteador> <Nome_da_SSID> <Caminho_para_web.zip>"
    exit 1
fi

# Atribui os argumentos a variáveis
IP_ROUTER=$1
SSID_NAME=$2
WEB_ZIP_PATH=$3

# Verifica se o arquivo ZIP existe
if [ ! -f "$WEB_ZIP_PATH" ]; then
    echo "Arquivo zip não encontrado: $WEB_ZIP_PATH"
    exit 1
fi

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

    if [ $? -ne 0 ]; então
        echo "Falha ao se reconectar ao roteador. Verifique a conexão Wi-Fi e tente novamente."
        exit 1
    fi
fi

# Descompacta o arquivo ZIP na pasta /www do roteador
echo "Descompactando $WEB_ZIP_PATH no roteador em /www..."
scp "$WEB_ZIP_PATH" root@$IP_ROUTER:/tmp/web.zip
ssh_router "unzip -o /tmp/web.zip -d /www"
ssh_router "rm /tmp/web.zip"

echo "Configuração concluída com sucesso."

