#!/bin/bash

os="$(uname)"
cpu_arch="$(uname -m)"

download_url_mac="https://assets.coreservice.io/public/package/18/app/1.0.3/app-1_0_3.tar.gz"
download_url_linux_386=""
download_url_linux_amd64=""
download_url_linux_arm32=""
download_url_linux_arm64=""

# functions
now() {
    date +"%Y/%m/%d %H:%M:%S"
} # display current time

function isGagaStart() {
    # echo "$1"
    while read line; do
        if [[ "${line}" =~ "gaganode" && "${line}" =~ "RUN" ]]; then
            return 0
        fi
    done <<<$1
    return 1
}

function waitForGagaRun(){
    while :; do
        result="$(./app status)"
        status=$(isGagaStart "$result")
        # echo ${status}
        if [[ ${status}=0 ]]; then
            # echo "running"
            return
        fi
        sleep 2s
    done
}



printf '\n%.0s' {1,100}
echo "
    ░█▀▀█ ─█▀▀█ ░█▀▀█ ─█▀▀█ 　 ▀█▀ ░█▄─░█ ░█▀▀▀█ ▀▀█▀▀ ─█▀▀█ ░█─── ░█─── ░█▀▀▀ ░█▀▀█ 
    ░█─▄▄ ░█▄▄█ ░█─▄▄ ░█▄▄█ 　 ░█─ ░█░█░█ ─▀▀▀▄▄ ─░█── ░█▄▄█ ░█─── ░█─── ░█▀▀▀ ░█▄▄▀ 
    ░█▄▄█ ░█─░█ ░█▄▄█ ░█─░█ 　 ▄█▄ ░█──▀█ ░█▄▄▄█ ─░█── ░█─░█ ░█▄▄█ ░█▄▄█ ░█▄▄▄ ░█─░█\
"
printf '\n%.0s' {1,100}

# configuration

read -p "
    Welcome!
    Before you start, you need to register at https://dashboard.gaganode.com/ to get your token.
    Press ENTER to continue:"
read -p "    
        Please enter your token: " token
read -p "
    
                Your token: $token

        Please ENTER to verify:"
echo "        $(now) Installation started!"

# mac installation
if [ "${os}" = "Darwin111" ]; then
    # download
    echo "$(now) Downloding App for mac"
    wget $download_url_mac
    echo "$(now) Downloaded!"

    # unzip
    tar -zxf app-1_0_3.tar.gz
    echo "$(now) Extracted!"
    rm -f app-1_0_3.tar.gz

    # install and start service
    cd app-darwin-amd64
    ./app service install
    ./app service start

    echo "app service started, waiting for gaga start..."
    sleep 8s
    # wait for gaga run
    while :; do
        result="$(./app status)"
        status=$(isGagaStart "$result")
        if [[ ${status}=0 ]]; then
            break
        fi
        sleep 2s
    done

    # gaga running, set token
    echo "set token"
    ./apps/gaganode/gaganode config set --token=$token
    ./app restart
    echo "gaga launched, please go to https://dashboard.gaganode.com/user_node check your nodes"

# linux x86 installation
elif [["${os}" = "Linux"]] && [[ "${cpu_arch}" = "x86" ]]; then
    echo "$(now) Downloding App for x86"
    wget $download_url_linux_386
    echo "$(now) Downloaded!"
    tar -zxf app-1_0_1.tar.gz
    echo "$(now) Extracted!"
    rm -f app-1_0_1.tar.gz
    cd app-darwin-amd64
    sudo ./service install meson_cdn
    sudo ./meson_cdn config set --token=$token --https_port=$port --cache.size=$storage
    sudo ./service start meson_cdn

# linux x86_64 installation
# detect x86_64 CPUs
elif [["${os}" = "Linux"]] && [[ "${cpu_arch}" = "x86_64" ]]; then
    echo "$(now) Downloding Meson for x86-64"
    wget $AMD
    echo "$(now) Downloaded!"
    tar -zxf meson_cdn-linux-amd64.tar.gz
    echo "$(now) Extracted!"
    rm -f meson_cdn-linux-amd64.tar.gz
    cd meson_cdn-linux-amd64
    sudo ufw allow $port
    sudo systemctl restart ufw
    echo "$(now) Firewall updated"
    echo "$(now) Port $port opened"
    sudo ./service install meson_cdn
    sudo ./meson_cdn config set --token=$token --https_port=$port --cache.size=$storage
    sudo ./service start meson_cdn

# linux arm32 installation

# linux arm64 installation
# detect arm64 CPUs
elif [["${os}" = "Linux"]] && [[ "${cpu_arch}" = "arm64" || "${cpu_arch}" = "aarch64" ]]; then
    echo "$(now) Downloding Meson for arm64"
    wget $ARM
    echo "$(now) Downloaded!"
    tar -zxf meson_cdn-linux-arm64.tar.gz
    echo "$(now) Extracted!"
    rm -f meson_cdn-linux-arm64.tar.gz
    cd ./meson_cdn-linux-arm64
    sudo ufw allow $port
    sudo systemctl restart ufw
    echo "$(now) Firewall updated"
    echo "$(now) Port $port opened"
    sudo ./service install meson_cdn
    sudo ./meson_cdn config set --token=$token --https_port=$port --cache.size=$storage
    sudo ./service start meson_cdn

    # Other CPU types error message
else
    echo "$(now) Unfortunately Meson Network does not support  ${cpu_arch} type CPUs yet"

fi
