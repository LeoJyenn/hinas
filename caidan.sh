#!/bin/bash
original_lc_all=$LC_ALL

RED='\e[91m'
GREEN='\e[32;1m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# IP
IP=$(ifconfig eth0 | grep '\<inet\>' | grep -v '127.0.0.1' | awk '{print $2}' | awk 'NR==1')

# 初始化安装目录
function mkdirTools() {
    mkdir -p /etc/caidan
}
# 脚本快捷方式
function install-caidan() {
    if [[ -f "./caidan.sh" ]] && [[ -d "/etc/caidan" ]]; then
        mv "./caidan.sh" /etc/caidan/caidan.sh
        local caidanType=
        if [[ -d "/usr/bin/" ]]; then
            if [[ ! -f "/usr/bin/caidan" ]]; then
                ln -s /etc/caidan/caidan.sh /usr/bin/caidan
                chmod 700 /usr/bin/caidan
                caidanType=true
            fi

            rm -rf "./caidan.sh"
        elif [[ -d "/usr/sbin" ]]; then
            if [[ ! -f "/usr/sbin/caidan" ]]; then
                ln -s /etc/caidan/caidan.sh /usr/sbin/caidan
                sudo chmod +x /usr/bin/caidan
                caidanType=true
            fi
            rm -rf "./caidan.sh"
        fi
        if [[ "${caidanType}" == "true" ]]; then
            echo -e "${GREEN}------------------------------------\n
            脚本安装完成，执行[caidan]打开脚本\n
            ------------------------------------${NC}" | sed -e 's/^[[:space:]]*//'
            exit 1
        fi
    fi
}

#更新脚本
function renew-caidan() {
    curl -o /etc/caidan/caidan.sh https://raw.githubusercontent.com/LeoJyenn/hinas/refs/heads/main/caidan.sh
    sudo chmod +x /usr/bin/caidan
    echo -e "${GREEN}更新成功 重新执行caidan生效。${NC}"
    exit 1
}

# 卸载脚本
function unInstall-caidan() {
    echo -e "${RED}是否确认卸载脚本？(y/n)${NC}"
    read -p "(y/n): " unInstallStatus

    if [ "$unInstallStatus" = "y" ]; then
        rm -rf /etc/caidan
        rm -rf /usr/bin/caidan
        rm -rf /usr/sbin/caidan
        echo -e "${GREEN}------------------------------------\n
            脚本卸载完成\n
            ------------------------------------${NC}" | sed -e 's/^[[:space:]]*//'
        exit 1
    elif [ "$unInstallStatus" = "n" ]; then
        echo -e "${RED}取消卸载${NC}"
    else
        echo -e "${RED}无效的选择${NC}"
    fi
    echo "按任意键继续..."
    read -n 1 -s -r -p ""
}
mkdirTools
install-caidan

while true; do
    clear

    echo -e "${YELLOW}
     _          _               _             ____                           _ 
    / \      __| |  _ __ ___   (_)  _ __     |  _ \    __ _   _ __     ___  | |
   / _ \    / _  | |  _   _ \  | | |  _ \    | |_) |  / _  | |  _ \   / _ \ | |
  / ___ \  | (_| | | | | | | | | | | | | |   |  __/  | (_| | | | | | |  __/ | |
 /_/   \_\  \__,_| |_| |_| |_| |_| |_| |_|   |_|      \__,_| |_| |_|  \___| |_|
                                                                               
${NC}"

    # 主菜单
    echo -e "${GREEN}======  主菜单 ======${NC}"
    echo -e "${YELLOW}1. 常用功能${NC}"
    echo -e "${YELLOW}2. 中文语言包${NC}"
    echo -e "${YELLOW}3. 系统检查${NC}"
    echo -e "${YELLOW}4. Aria2、BT${NC}"
    echo -e "${YELLOW}5. 网络测速${NC}"
    echo -e "${YELLOW}6. 格式化U盘、TF卡${NC}"
    echo -e "${YELLOW}7. Docker${NC}"
    echo -e "${YELLOW}8. Cockpit${NC}"
    echo -e "${YELLOW}9. 系统迁移${NC}"
    echo -e "${YELLOW}10.Tailscale${NC}"
    echo -e "${YELLOW}11.Httpsok${NC}"
    echo -e "${YELLOW}12.socks5服务功能${NC}"
    echo -e "${RED}update.系统更新和软件更新${NC}"
    echo -e "${RED}caidanu.更新脚本${NC}"
    echo -e "${RED}caidanun.卸载脚本${NC}"
    echo -e "${RED}0.系统还原${NC}"
    echo -e "${RED}pw.修改root密码${NC}"
    echo -e "${RED}r.重启系统${NC}"
    echo -e "${RED}q.退出${NC}"

    # 获取输入
    read -p "请输入选项: " choice

    case $choice in
    1)
        #常用功能菜单
        while true; do
            clear
            echo -e "${GREEN}======  菜单 ======${NC}"
            echo -e "${YELLOW}1.搜索文件${NC}"
            echo -e "${YELLOW}2.重启网络服务${NC}"
            echo -e "${YELLOW}3.清理缓存${NC}"
            echo -e "${YELLOW}4.Swap设置${NC}"
            echo -e "${YELLOW}5.粒子动态背景${NC}"
            echo -e "${YELLOW}6.优化DNS${NC}"
            echo -e "${RED}q.返回${NC}"

            read -p "请输入选项: " choice

            #搜索文件和文件夹
            function search_files() {
                read -p "请输入要搜索的关键词: " keyword
                read -p "请输入要搜索的目录路径（按 Enter 键跳过，整个系统搜索）: " search_path

                if [ -z "$search_path" ]; then
                    # 如果未提供搜索路径，使用整个系统
                    search_path="/"
                fi

                echo -e "正在搜索目录 '$search_path' 中包含关键词 '$keyword' 的文件和文件夹..."

                # 使用 find 命令搜索，使用 CYAN 颜色显示
                result=$(find "$search_path" -iname "*$keyword*" 2>/dev/null)

                if [ -n "$result" ]; then
                    echo -e "$result" | while read -r entry; do
                        echo -e "${CYAN}$entry${NC}"
                    done
                    echo "搜索完成，找到的文件和文件夹如上所示"
                else
                    echo "未找到包含关键词 '$keyword' 的文件和文件夹"
                fi
            }

            function cleanup() {
                # 清理 APT 缓存
                sudo apt-get clean

                # 移除无用的依赖项
                sudo apt-get autoremove -y

                # 删除旧版本的 Linux 内核
                sudo apt-get purge -y $(dpkg -l | awk '/^ii linux-image-.*[0-9]/{print $2}' | grep -v "$(uname -r)")

                # 清理临时文件
                sudo rm -rf /tmp/*

                # 清理用户缓存
                rm -rf ~/.cache

                # 清理系统日志
                sudo journalctl --vacuum-time=3d

                # 清理旧备份文件
                sudo rm -rf /var/backups/*

                # 清理不必要的临时文件
                sudo rm -rf /var/tmp/*

                # 清理用户的 Trash 目录
                rm -rf ~/.local/share/Trash/*

                # 清理软件包管理器的缓存
                sudo apt-get autoclean

                echo -e "${GREEN}清理完成！${NC}"
            }

            # Swap设置脚本
            function swap() {
                read -p "请输入 vm.swappiness 的值 (回车默认为 60): " swappiness_value

                # 如果没有输入，默认值为 60
                swappiness_value=${swappiness_value:-60}

                # 检查是否已存在 vm.swappiness 的设置
                if grep -q "^vm.swappiness" /etc/sysctl.conf; then
                    # 如果已存在，使用 sed 替换
                    sed -i "s/^vm.swappiness.*/vm.swappiness = $swappiness_value/" /etc/sysctl.conf
                else
                    # 如果不存在，追加新的设置
                    echo "vm.swappiness = $swappiness_value" >>/etc/sysctl.conf
                fi
                # 停止交换文件
                sudo swapoff /swapfile
                # 选择Swap文件大小，默认为1024MB
                read -p "请输入Swap交换区大小（回车默认为1024M）: " swap_size

                # 如果没有输入值，则使用默认值 1024M
                if [ -z "$swap_size" ]; then
                    swap_size=1024
                fi

                # 调整交换文件大小
                swapfile="/swapfile"
                # 交换文件路径不存在时创建
                sudo dd if=/dev/zero of=$swapfile bs=1M count=$swap_size status=progress
                sudo chmod 600 $swapfile
                sudo mkswap $swapfile

                # 启用交换文件
                sudo swapon $swapfile

                # 显示设置信息
                free -h
                echo -e "${GREEN}Swap交换区创建完成，大小为 ${swap_size}MB${NC}"
                cat /proc/sys/vm/swappiness
                echo -e "${GREEN}vm.swappiness 设置为 $swappiness_value${NC}"
                echo -e "${RED}请注意，这些更改将在下次启动时生效。${NC}"

                # 提示是否重启
                read -p "是否重启设备以使更改生效？ (y/n): " confirm_reboot
                if [ "$confirm_reboot" = "y" ]; then
                    echo "正在重启设备..."
                    sudo reboot
                else
                    echo -e "${RED}取消重启，请手动重启系统以使配置生效${NC}"
                fi
            }

            # 粒子动态背景
            function backdrop() {
                curl -o /var/www/html/img/icloud.png \
                    -o /var/www/html/home.php \
                    -o /var/www/html/index.php \
                    https://raw.githubusercontent.com/LX-webo/hinas/main/icloud.png \
                    https://raw.githubusercontent.com/LX-webo/hinas/main/home.php \
                    https://raw.githubusercontent.com/LX-webo/hinas/main/index.php

                echo -e "${GREEN}背景更换成功，清除浏览器缓存刷新${NC}"
            }

            # 添加DNS
            function DNS() {
                cat <<EOF >/etc/caidan/resolv.conf
# Dynamic resolv.conf(5) file for glibc resolver(3) generated by resolvconf(8)
# DO NOT EDIT THIS FILE BY HAND -- YOUR CHANGES WILL BE OVERWRITTEN
# 127.0.0.53 is the systemd-resolved stub resolver.
# run "systemd-resolve --status" to see details about the actual nameservers.

nameserver 8.8.8.8
nameserver 114.114.114.114
nameserver 127.0.0.53
search lan
EOF

                sudo rm /etc/resolv.conf
                sudo ln -s /etc/caidan/resolv.conf /etc/resolv.conf
                echo -e "${GREEN}DNS修改成功cat /etc/resolv.conf查看${NC}"
            }

            case $choice in
            1)
                search_files
                ;;
            2)
                sudo systemctl restart network-manager
                status_output=$(sudo systemctl status network-manager)
                if sudo systemctl is-active --quiet network-manager; then
                    echo -e "详细信息：\n$status_output"
                    echo -e "${GREEN}网络重启成功${NC}"
                else
                    echo -e "${RED}网络重启失败${NC}"
                fi
                ;;
            3)
                cleanup
                ;;
            4)
                swap
                ;;
            5)
                backdrop
                ;;
            6)
                DNS
                ;;
            q | Q)
                break
                ;;
            *)
                echo "无效的选择，请重新输入"
                ;;
            esac
            echo "按任意键继续..."
            read -n 1 -s -r -p ""
        done
        ;;
    2)
        # 安装中文语言包

        # 更新软件源
        sudo apt-get update
        # 安装
        sudo apt install language-pack-zh-hans language-pack-zh-hans-base

        # 修改配置文件
        echo "LANG=zh_CN.UTF-8" >>~/.profile && echo "export LANG=zh_CN.UTF-8" >>~/.bashrc && echo "export LC_ALL=zh_CN.UTF-8" >>~/.bashrc && echo "export LC_TIME=zh_CN.UTF-8" >>~/.bashrc

        # 提示重启
        read -p "语言配置已完成，是否现在重启系统？ (y/n): " choice
        if [ "$choice" = "y" ]; then
            sudo reboot
        else
            echo -e "${RED}取消重启，请手动重启系统以使语言配置生效${NC}"
        fi
        echo "按任意键继续..."
        read -n 1 -s -r -p ""
        ;;
    3)
        # 系统健康检查
        export LC_ALL="en_US.UTF-8"
        # ip
        function check_ip_preference() {
            local ip_address=$(curl -s test.ipw.cn)

            if [[ "$ip_address" =~ .*:.* ]]; then
                echo "${GREEN}IPv6${NC}"
            elif [[ "$ip_address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "${GREEN}IPv4${NC}"
            else
                echo "无法确定 IP 地址。"
            fi
        }
        DEVICE=$(dmesg 2>/dev/null | grep "CPU: hi3798" | awk -F ':[ ]' '/CPU/{printf ($2)}')
        [ ! "$DEVICE" ] && DEVICE=$(head -n 1 /etc/regname 2>/null)
        mac_now=$(ifconfig eth0 | grep "ether" | awk '{print $2}')
        clear
        echo -e "\e[33m
	 _   _ ___  _   _    _    ____  
	| | | |_ _|| \ | |  / \  / ___| 
	| |_| || | |  \| | / _ \ \___ \ 
	|  _  || | | |\  |/ ___ \ ___) |
	|_| |_|___||_| \_/_/   \_\____/ 

   板型名称 : ${DEVICE}_$(egrep -oa "hi3798.+reg" /dev/mmcblk0p1 2>/dev/null | cut -d '_' -f1 | sort | uniq)
   CPU 信息 : $(cat -v /proc/device-tree/compatible | sed 's/\^@//g')@$(cat /proc/cpuinfo | grep "processor" | sort | uniq | wc -l)核处理器 | $(uname -p)架构
   CPU 使用 : $(top -b -n 1 | grep "%Cpu(s):" | awk '{printf "%.2f%%", 100-$8}')
   系统版本 : $(awk -F '[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release) | V$(cat /etc/nasversion)-$(uname -r)-$(getconf LONG_BIT)
   可用存储 : $(df -m / | grep -v File | awk '{a=$4*100/$2;b=$4} {printf("%.1f%s %.1fM\n",a,"%",b)}')
   可用内存 : $(free -m | grep Mem | awk '{a=$7*100/$2;b=$7} {printf("%.1f%s %.1fM\n",a,"%",b)}') | 交换区：$(free -m | grep Swap | awk '{a=$4*100/$2;b=$4} {printf("%.1f%s %.1fM\n",a,"%",b)}')
   启动时间 : $(awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60;d=($1%60)} {printf("%d 天 %d 小时 %d 分钟 %d 秒\n",a,b,c,d)}' /proc/uptime)
   I P 地址 : $IP       
   IPv4地址 ：$(curl -s ipv4.icanhazip.com)      
   IPv6地址 ：$(curl -s api6.ipify.org)
   优先地址 : $(check_ip_preference)
   设备温度 : $(grep Tsensor /proc/msp/pm_cpu | awk '{print $4}')°C
   MAC 地址 : $mac_now
   用户状态 : $(whoami)
   设备识别码：$(histb | awk '{print $2}')
"
        alias reload='. /etc/profile'
        alias cls='clear'
        alias syslog='cat /var/log/syslog'
        alias unmount='umount -l'
        alias reg="egrep -oa 'hi3798.+' /dev/mmcblk0p1 | awk '{print $1}'"

        #Sectioning.....
        echo -e "${YELLOW}---------------------------------------------------------------------------------------------------------------${NC}"
        echo "服务状态:"
        echo -e "${YELLOW}---------------------------------------------------------------------------------------------------------------${NC}"

        # tomcat
        echo "1) Tomcat"

        pp=$(ps aux | grep tomcat | grep "[D]java.util")
        if [[ $pp =~ "-Xms512M" ]]; then
            echo -e "   Status: ${GREEN}UP${NC}"
        else
            echo -e "   Status: ${RED}DOWN${NC}"
        fi
        echo ""

        # BusyBox
        function busybox_httpd() {
            echo -e "2) BusyBox-httpd"
            # grepping BusyBox httpd status from ps aux
            busybox_httpd=$(ps aux | grep "busybox-extras httpd")
            if [[ "$busybox_httpd" ]]; then
                echo -e "   Status: ${GREEN}UP${NC}"
            else
                echo -e "   Status: ${RED}DOWN${NC}"
            fi
        }

        function elastic() {
            echo -e "3) Elasticsearch"

            elastic=$(ps aux | grep elasticsearch)
            if [[ $elastic =~ "elastic+" ]]; then
                echo -e "   Status: ${GREEN}UP${NC}"
            else
                echo -e "    Status: ${RED}DOWN${NC}"
            fi
        }

        # mysql
        function mysql() {
            echo -e "4) Mysql"

            mysql=$(ps aux | grep mysqld)
            if [[ $mysql =~ "mysqld" ]]; then
                echo -e "   Status: ${GREEN}UP${NC}"
            else
                echo -e "   Status: ${RED}DOWN${NC}"
            fi
        }

        # docker
        function docker1() {
            echo -e "5) Docker"

            if systemctl is-active --quiet docker; then
                echo -e "   Status: ${GREEN}UP${NC}"
            else
                echo -e "   Status: ${RED}DOWN${NC}"
            fi
        }

        busybox_httpd
        echo ""
        elastic
        echo ""
        mysql
        echo ""
        docker1
        echo ""

        echo -e "${YELLOW}---------------------------------------------------------------------------------------------------------------${NC}"
        echo "内存信息:"
        echo -e "${YELLOW}---------------------------------------------------------------------------------------------------------------${NC}"

        free -h
        echo -e "${CYAN}检查时间: $(uptime) ${NC}"
        echo -e "${CYAN}进程总数: $(ps aux | wc -l) 资源使用率较高的前 10 个服务：${NC}"

        ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head

        echo -e "${YELLOW}---------------------------------------------------------------------------------------------------------------${NC}"
        echo "服务器空间详情:"
        echo -e "${YELLOW}---------------------------------------------------------------------------------------------------------------${NC}"

        df -h -P -T
        echo -e "${YELLOW}---------------------------------------------------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}---------------------------------------------------------------------------------------------------------------${NC}"
        echo "按任意键继续..."
        read -n 1 -s -r -p ""
        export LC_ALL=$original_lc_all
        ;;
    4)
        # Aria2、BT菜单
        while true; do
            clear
            echo -e "${GREEN}======  菜单 ======${NC}"
            echo -e "${YELLOW}1.更改Aria2下载路径${NC}"
            echo -e "${YELLOW}2.更改BT下载路径${NC}"
            echo -e "${YELLOW}3.Aria2、BT开启ipv6${NC}"
            echo -e "${RED}q.返回${NC}"

            read -p "请输入选项: " choice

            function change_aria2_path() {
                aria2_conf="/usr/local/aria2/aria2.conf"
                if [ -f "$aria2_conf" ]; then
                    prompt_and_change_path "$aria2_conf"
                    # 重启 Aria2
                    systemctl restart aria2c
                else
                    echo "错误：Aria2配置文件不存在"
                fi
            }

            function prompt_and_change_path() {
                config_file="$1"
                current_path=$(grep "^dir=" "$config_file" | awk -F "=" '{print $2}' | tr -d '[:space:]')
                read -p "当前路径为: $current_path，是否要更改？（y/n）" confirm_change
                if [ "$confirm_change" == "y" ]; then
                    read -p "请输入新的相对路径（相对于当前工作目录）： " new_relative_path
                    new_path=$(readlink -f "$new_relative_path")
                    if [ -d "$new_path" ]; then
                        sed -i "s|^dir=.*$|dir=$new_path|" "$config_file"
                        echo -e "${GREEN}路径已更改为: $new_path${NC}"
                    else
                        echo -e "${RED}错误：新路径不存在，请重新操作${NC}"
                    fi
                else
                    echo -e "${RED}更改操作已取消${NC}"
                fi
            }

            function change_bt_path() {
                service transmission-daemon stop
                prompt_and_change_bt_path
                service transmission-daemon start
            }

            function prompt_and_change_bt_path() {
                config_file="/etc/transmission-daemon/settings.json"
                current_path=$(grep -E '"download-dir":' "$config_file" | awk -F '"' '{print $4}')
                read -p "当前路径为: $current_path，是否要更改？（y/n）" confirm_change
                if [ "$confirm_change" == "y" ]; then
                    read -p "请输入新的相对路径（相对于当前工作目录）： " new_relative_path
                    new_path=$(readlink -f "$new_relative_path")
                    if [ -d "$new_path" ]; then
                        sed -i 's|"download-dir": ".*"|"download-dir": "'"$new_path"'"|' "$config_file"
                        echo -e "${GREEN}路径已更改为: $new_path${NC}"
                    else
                        echo -e "${RED}错误：新路径不存在，请重新操作${NC}"
                    fi
                else
                    echo -e "${RED}更改操作已取消${NC}"
                fi
            }

            function aria2_bt_ipv6_path() {
                # 添加 Transmission 官方 PPA
                sudo add-apt-repository -y ppa:transmissionbt/ppa

                # 安装软件-properties-common
                sudo apt-get update
                sudo apt-get install -y software-properties-common

                # 安装 Transmission
                sudo apt-get install -y transmission

                # Transmission Web 控制面板中文化脚本
                # 获取第一个参数
                ARG1="$1"
                ROOT_FOLDER=""
                SCRIPT_NAME="$0"
                SCRIPT_VERSION="1.2.2-beta2"
                VERSION=""
                WEB_FOLDER=""
                ORG_INDEX_FILE="index.original.html"
                INDEX_FILE="index.html"
                TMP_FOLDER="/tmp/tr-web-control"
                PACK_NAME="master.tar.gz"
                WEB_HOST="https://github.com/ronggang/transmission-web-control/archive/"
                DOWNLOAD_URL="$WEB_HOST$PACK_NAME"
                # 安装类型
                # 1 安装至当前 Transmission Web 所在目录
                # 2 安装至 TRANSMISSION_WEB_HOME 环境变量指定的目录，参考：https://github.com/transmission/transmission/wiki/Environment-Variables#transmission-specific-variables
                # 使用环境变量时，如果 transmission 不是当前用户运行的，则需要将 TRANSMISSION_WEB_HOME 添加至 /etc/profile 文件，以达到“永久”的目的
                # 3 用户指定参数做为目录，如 sh install-tr-control.sh /usr/local/transmission/share/transmission
                INSTALL_TYPE=-1
                SKIP_SEARCH=0
                AUTOINSTALL=0
                if which whoami 2>/dev/null; then
                    USER=$(whoami)
                fi

                #==========================================================
                MSG_TR_WORK_FOLDER="当前 Transmission Web 目录为: "
                MSG_SPECIFIED_VERSION="您正在使用指定版本安装，版本："
                MSG_SEARCHING_TR_FOLDER="正在搜索 Transmission Web 目录..."
                MSG_THE_SPECIFIED_DIRECTORY_DOES_NOT_EXIST="指定的目录不存在，准备进行搜索，请稍候..."
                MSG_USE_WEB_HOME="使用 TRANSMISSION_WEB_HOME 变量: $TRANSMISSION_WEB_HOME"
                MSG_AVAILABLE="可用"
                MSG_TRY_SPECIFIED_VERSION="正在尝试指定版本"
                MSG_PACK_COPYING="正在复制安装包..."
                MSG_WEB_PATH_IS_MISSING="错误 : Transmisson WEB 目录不存在，请确认是否已安装 Transmisson "
                MSG_PACK_IS_EXIST=" 已存在，是否重新下载？（y/n）"
                MSG_SIKP_DOWNLOAD="\n跳过下载，正在准备安装"
                MSG_DOWNLOADING="正在下载 Transmission Web Control..."
                MSG_DOWNLOAD_COMPLETE="下载完成，正在准备安装..."
                MSG_DOWNLOAD_FAILED="安装包下载失败，请重试或尝试其他版本"
                MSG_INSTALL_COMPLETE="Transmission Web Control 安装完成!"
                MSG_PACK_EXTRACTING="正在解压安装包..."
                MSG_PACK_CLEANING_UP="正在清理安装包..."
                MSG_DONE="安装脚本执行完成，如遇到问题请查看：https://github.com/ronggang/transmission-web-control/wiki "
                MSG_SETTING_PERMISSIONS="正在设置权限，大约需要一分钟 ..."
                MSG_BEGIN="开始"
                MSG_END="结束"
                MSG_MAIN_MENU="
	            欢迎使用 Transmission Web Control 中文安装脚本
	            官方帮助文档：https://github.com/ronggang/transmission-web-control/wiki 
	            安装脚本版本：$SCRIPT_VERSION 

	            1. 安装最新的发布版本，推荐（release）；
	            2. 安装指定版本，可用于降级；
	            3. 恢复到官方UI；
	            4. 重新下载安装脚本（$SCRIPT_NAME）；
	            5. 检测 Transmission 是否已启动；
	            6. 指定安装目录；
	            9. 安装最新代码库中的内容（master）；
	            ===================
	            0. 退出安装；

	            请输入对应的数字："
                MSG_INPUT_VERSION="请输入版本号（如：1.5.1）："
                MSG_INPUT_TR_FOLDER="请输入 Transmission Web 所在的目录（不包含web，如：/usr/share/transmission）："
                MSG_SPECIFIED_FOLDER="安装目录已指定为："
                MSG_INVALID_PATH="输入的路径无效"
                MSG_MASTER_INSTALL_CONFIRM="最新代码可能包含未知错误，是否确认安装？ (y/n): "
                MSG_FIND_WEB_FOLDER_FROM_PROCESS="正在尝试从进程中识别 Transmission Web 目录..."
                MSG_FIND_WEB_FOLDER_FROM_PROCESS_FAILED=" × 识别失败，请确认 Transmission 已启动"
                MSG_CHECK_TR_DAEMON="正在检测 Transmission 进程..."
                MSG_CHECK_TR_DAEMON_FAILED="在系统进程中没有找到 Transmission ，请确认是否已启动"
                MSG_TRY_START_TR="是否尝试启动 Transmission ？（y/n）"
                MSG_TR_DAEMON_IS_STARTED="Transmission 已启动"
                MSG_REVERTING_ORIGINAL_UI="正在恢复官方UI..."
                MSG_REVERT_COMPLETE="恢复完成，在浏览器中重新访问 http://ip:9091/ 或刷新即可查看官方UI"
                MSG_ORIGINAL_UI_IS_MISSING="官方UI不存在"
                MSG_DOWNLOADING_INSTALL_SCRIPT="正在重新下载安装脚本..."
                MSG_INSTALL_SCRIPT_DOWNLOAD_COMPLETE="下载完成，请重新运行安装脚本"
                MSG_INSTALL_SCRIPT_DOWNLOAD_FAILED="安装脚本下载失败！"
                MSG_NON_ROOT_USER="无法确认当前是否为 root 用户，可能无法进行安装操作，是否继续？（y/n）"
                #==========================================================

                # 是否自动安装
                if [ "$ARG1" = "auto" ]; then
                    AUTOINSTALL=1
                else
                    ROOT_FOLDER=$ARG1
                fi

                initValues() {
                    # 判断临时目录是否存在，不存在则创建
                    if [ ! -d "$TMP_FOLDER" ]; then
                        mkdir -p "$TMP_FOLDER"
                    fi

                    # 获取 Transmission 目录
                    getTransmissionPath

                    # 判断 ROOT_FOLDER 是否为一个有效的目录，如果是则表明传递了一个有效路径
                    if [ -d "$ROOT_FOLDER" ]; then
                        showLog "$MSG_TR_WORK_FOLDER $ROOT_FOLDER/web"
                        INSTALL_TYPE=3
                        WEB_FOLDER="$ROOT_FOLDER/web"
                        SKIP_SEARCH=1
                    fi

                    # 判断是否指定了版本
                    if [ "$VERSION" != "" ]; then
                        # master 或 hash
                        if [ "$VERSION" = "master" -o ${#VERSION} = 40 ]; then
                            PACK_NAME="$VERSION.tar.gz"
                        # 是否指定了 v
                        elif [ ${VERSION:0:1} = "v" ]; then
                            PACK_NAME="$VERSION.tar.gz"
                            VERSION=${VERSION:1}
                        else
                            PACK_NAME="v$VERSION.tar.gz"
                        fi
                        showLog "$MSG_SPECIFIED_VERSION $VERSION"

                        DOWNLOAD_URL="https://github.com/ronggang/transmission-web-control/archive/$PACK_NAME"
                    fi

                    if [ $SKIP_SEARCH = 0 ]; then
                        # 查找目录
                        findWebFolder
                    fi
                }

                # 开始
                main() {
                    begin
                    # 初始化值
                    initValues
                    # 安装
                    install
                    # 清理
                    clear
                }

                # 查找Web目录
                findWebFolder() {
                    # 找出web ui 目录
                    showLog "$MSG_SEARCHING_TR_FOLDER"

                    # 判断 TRANSMISSION_WEB_HOME 环境变量是否被定义，如果是，直接用这个变量的值
                    if [ $TRANSMISSION_WEB_HOME ]; then
                        showLog "$MSG_USE_WEB_HOME"
                        # 判断目录是否存在，如果不存在则创建 https://github.com/ronggang/transmission-web-control/issues/167
                        if [ ! -d "$TRANSMISSION_WEB_HOME" ]; then
                            mkdir -p "$TRANSMISSION_WEB_HOME"
                        fi
                        INSTALL_TYPE=2
                    else
                        if [ -d "$ROOT_FOLDER" -a -d "$ROOT_FOLDER/web" ]; then
                            WEB_FOLDER="$ROOT_FOLDER/web"
                            INSTALL_TYPE=1
                            showLog "$ROOT_FOLDER/web $MSG_AVAILABLE."
                        else
                            showLog "$MSG_THE_SPECIFIED_DIRECTORY_DOES_NOT_EXIST"
                            ROOT_FOLDER=$(find / -name 'web' -type d 2>/dev/null | grep 'transmission/web' | sed 's/\/web$//g')

                            if [ -d "$ROOT_FOLDER/web" ]; then
                                WEB_FOLDER="$ROOT_FOLDER/web"
                                INSTALL_TYPE=1
                            fi
                        fi
                    fi
                }

                # 安装
                install() {
                    # 是否指定版本
                    if [ "$VERSION" != "" ]; then
                        showLog "$MSG_TRY_SPECIFIED_VERSION $VERSION"
                        # 下载安装包
                        download
                        # 解压安装包
                        unpack

                        showLog "$MSG_PACK_COPYING"
                        # 复制文件到
                        cp -r "$TMP_FOLDER/transmission-web-control-$VERSION/src/." "$WEB_FOLDER/"
                        # 设置权限
                        setPermissions "$WEB_FOLDER"
                        # 安装完成
                        installed

                    # 如果目录存在，则进行下载和更新动作
                    elif [ $INSTALL_TYPE = 1 -o $INSTALL_TYPE = 3 ]; then
                        # 下载安装包
                        download
                        # 创建web文件夹，从 20171014 之后，打包文件不包含web目录，直接打包为src下所有文件
                        mkdir web

                        # 解压缩包
                        unpack "web"

                        showLog "$MSG_PACK_COPYING"
                        # 复制文件到
                        cp -r web "$ROOT_FOLDER"
                        # 设置权限
                        setPermissions "$ROOT_FOLDER"
                        # 安装完成
                        installed

                    elif [ $INSTALL_TYPE = 2 ]; then
                        # 下载安装包
                        download
                        # 解压缩包
                        unpack "$TRANSMISSION_WEB_HOME"
                        # 设置权限
                        setPermissions "$TRANSMISSION_WEB_HOME"
                        # 安装完成
                        installed

                    else
                        echo "##############################################"
                        echo "#"
                        echo "# $MSG_WEB_PATH_IS_MISSING"
                        echo "#"
                        echo "##############################################"
                    fi
                }

                # 下载安装包
                download() {
                    # 切换到临时目录
                    cd "$TMP_FOLDER"
                    # 判断安装包文件是否已存在
                    if [ -f "$PACK_NAME" ]; then
                        if [ $AUTOINSTALL = 0 ]; then
                            echo -n "\n$PACK_NAME $MSG_PACK_IS_EXIST"
                            read flag
                        else
                            flag="y"
                        fi

                        if [ "$flag" = "y" -o "$flag" = "Y" ]; then
                            rm "$PACK_NAME"
                        else
                            showLog "$MSG_SIKP_DOWNLOAD"
                            return 0
                        fi
                    fi
                    showLog "$MSG_DOWNLOADING"
                    echo ""
                    wget "$DOWNLOAD_URL" --no-check-certificate
                    # 判断是否下载成功
                    if [ $? -eq 0 ]; then
                        showLog "$MSG_DOWNLOAD_COMPLETE"
                        return 0
                    else
                        showLog "$MSG_DOWNLOAD_FAILED"
                        end
                        exit 1
                    fi
                }

                # 安装完成
                installed() {
                    showLog "$MSG_INSTALL_COMPLETE"
                }

                # 输出日志
                showLog() {
                    TIME=$(date "+%Y-%m-%d %H:%M:%S")

                    case $2 in
                    "n")
                        echo -n "<< $TIME >> $1"
                        ;;
                    *)
                        echo "<< $TIME >> $1"
                        ;;
                    esac

                }

                # 解压安装包
                unpack() {
                    showLog "$MSG_PACK_EXTRACTING"
                    if [ "$1" != "" ]; then
                        tar -xzf "$PACK_NAME" -C "$1"
                    else
                        tar -xzf "$PACK_NAME"
                    fi
                    # 如果之前没有安装过，则先将原系统的文件改为
                    if [ ! -f "$WEB_FOLDER/$ORG_INDEX_FILE" -a -f "$WEB_FOLDER/$INDEX_FILE" ]; then
                        mv "$WEB_FOLDER/$INDEX_FILE" "$WEB_FOLDER/$ORG_INDEX_FILE"
                    fi

                    # 清除原来的内容
                    if [ -d "$WEB_FOLDER/tr-web-control" ]; then
                        rm -rf "$WEB_FOLDER/tr-web-control"
                    fi
                }

                # 清除工作
                clear() {
                    showLog "$MSG_PACK_CLEANING_UP"
                    if [ -f "$PACK_NAME" ]; then
                        # 删除安装包
                        rm "$PACK_NAME"
                    fi

                    if [ -d "$TMP_FOLDER" ]; then
                        # 删除临时目录
                        rm -rf "$TMP_FOLDER"
                    fi

                    showLog "$MSG_DONE"
                    end
                }

                # 设置权限
                setPermissions() {
                    folder="$1"
                    showLog "$MSG_SETTING_PERMISSIONS"
                    # 设置权限
                    find "$folder" -type d -exec chmod o+rx {} \;
                    find "$folder" -type f -exec chmod o+r {} \;
                }

                # 开始
                begin() {
                    echo ""
                    showLog "== $MSG_BEGIN =="
                    showLog ""
                }

                # 结束
                end() {
                    showLog "== $MSG_END =="
                    echo ""
                }

                # 显示主菜单
                showMainMenu() {
                    echo -n "$MSG_MAIN_MENU"
                    read flag
                    echo ""
                    case $flag in
                    1)
                        getLatestReleases
                        main
                        ;;

                    2)
                        echo -n "$MSG_INPUT_VERSION"
                        read VERSION
                        main
                        ;;

                    3)
                        revertOriginalUI
                        ;;

                    4)
                        downloadInstallScript
                        ;;

                    5)
                        checkTransmissionDaemon
                        ;;

                    6)
                        echo -n "$MSG_INPUT_TR_FOLDER"
                        read input
                        if [ -d "$input/web" ]; then
                            ROOT_FOLDER="$input"
                            showLog "$MSG_SPECIFIED_FOLDER $input/web"
                        else
                            showLog "$MSG_INVALID_PATH"
                        fi
                        sleep 2
                        showMainMenu
                        ;;

                    # 下载最新的代码
                    9)
                        echo -n "$MSG_MASTER_INSTALL_CONFIRM"
                        read input
                        if [ "$input" = "y" -o "$input" = "Y" ]; then
                            VERSION="master"
                            main
                        else
                            showMainMenu
                        fi
                        ;;
                    *)
                        showLog "$MSG_END"
                        ;;
                    esac
                }

                # 获取Tr所在的目录
                getTransmissionPath() {
                    # 指定一次当前系统的默认目录
                    # 用户如知道自己的 Transmission Web 所在的目录，直接修改这个值，以避免搜索所有目录
                    # ROOT_FOLDER="/usr/local/transmission/share/transmission"
                    # Fedora 或 Debian 发行版的默认 ROOT_FOLDER 目录
                    if [ -f "/etc/fedora-release" ] || [ -f "/etc/debian_version" ]; then
                        ROOT_FOLDER="/usr/share/transmission"
                    fi

                    if [ ! -d "$ROOT_FOLDER" ]; then
                        showLog "$MSG_FIND_WEB_FOLDER_FROM_PROCESS" "n"
                        infos=$(ps -ef | awk '/[t]ransmission-da/{print $8}')
                        if [ "$infos" != "" ]; then
                            echo " √"
                            search="bin/transmission-daemon"
                            replace="share/transmission"
                            path=${infos//$search/$replace}
                            if [ -d "$path" ]; then
                                ROOT_FOLDER=$path
                            fi
                        else
                            echo "$MSG_FIND_WEB_FOLDER_FROM_PROCESS_FAILED"
                        fi
                    fi
                }

                # 获取最后的发布版本号
                # 因在源码库里提交二进制文件不便于管理，以后将使用这种方式获取最新发布的版本
                getLatestReleases() {
                    VERSION=$(wget -O - https://api.github.com/repos/ronggang/transmission-web-control/releases/latest | grep tag_name | head -n 1 | cut -d '"' -f 4)
                }

                # 检测 Transmission 进程是否存在
                checkTransmissionDaemon() {
                    showLog "$MSG_CHECK_TR_DAEMON"
                    ps -C transmission-daemon
                    if [ $? -ne 0 ]; then
                        showLog "$MSG_CHECK_TR_DAEMON_FAILED"
                        echo -n "$MSG_TRY_START_TR"
                        read input
                        if [ "$input" = "y" -o "$input" = "Y" ]; then
                            service transmission-daemon start
                        fi
                    else
                        showLog "$MSG_TR_DAEMON_IS_STARTED"
                    fi
                    sleep 2
                    showMainMenu
                }

                # 恢复官方UI
                revertOriginalUI() {
                    initValues
                    # 判断是否有官方的UI存在
                    if [ -f "$WEB_FOLDER/$ORG_INDEX_FILE" ]; then
                        showLog "$MSG_REVERTING_ORIGINAL_UI"
                        # 清除原来的内容
                        if [ -d "$WEB_FOLDER/tr-web-control" ]; then
                            rm -rf "$WEB_FOLDER/tr-web-control"
                            rm "$WEB_FOLDER/favicon.ico"
                            rm "$WEB_FOLDER/index.html"
                            rm "$WEB_FOLDER/index.mobile.html"
                            mv "$WEB_FOLDER/$ORG_INDEX_FILE" "$WEB_FOLDER/$INDEX_FILE"
                            showLog "$MSG_REVERT_COMPLETE"
                        else
                            showLog "$MSG_WEB_PATH_IS_MISSING"
                            sleep 2
                            showMainMenu
                        fi
                    else
                        showLog "$MSG_ORIGINAL_UI_IS_MISSING"
                        sleep 2
                        showMainMenu
                    fi
                }

                # 重新下载安装脚本
                downloadInstallScript() {
                    if [ -f "$SCRIPT_NAME" ]; then
                        rm "$SCRIPT_NAME"
                    fi
                    showLog "$MSG_DOWNLOADING_INSTALL_SCRIPT"
                    wget "https://github.com/ronggang/transmission-web-control/raw/master/release/$SCRIPT_NAME" --no-check-certificate
                    # 判断是否下载成功
                    if [ $? -eq 0 ]; then
                        showLog "$MSG_INSTALL_SCRIPT_DOWNLOAD_COMPLETE"
                    else
                        showLog "$MSG_INSTALL_SCRIPT_DOWNLOAD_FAILED"
                        sleep 2
                        showMainMenu
                    fi
                }

                if [ "$USER" != 'root' ]; then
                    showLog "$MSG_NON_ROOT_USER" "n"
                    read input
                    if [ "$input" = "n" -o "$input" = "N" ]; then
                        exit -1
                    fi
                fi

                if [ $AUTOINSTALL = 1 ]; then
                    getLatestReleases
                    main
                else
                    # 执行
                    showMainMenu
                fi
                # Aria2 配置更新
                conf_file="/usr/local/aria2/aria2.conf"

                if [ ! -f "$conf_file" ]; then
                    echo "错误：$conf_file 文件不存在."
                    exit 1
                fi

                sudo sed -i 's/disable-ipv6=true/disable-ipv6=false/' "$conf_file"
                sudo sed -i 's/enable-dht6=false/enable-dht6=true/' "$conf_file"

                echo "aria2 已开启ipv6."
                systemctl restart aria2c

                # Transmission Daemon 配置更新
                sudo service transmission-daemon stop
                sudo sed -i 's/"rpc-bind-address": "0.0.0.0"/"rpc-bind-address": "::"/' /etc/transmission-daemon/settings.json

                if [ $? -ne 0 ]; then
                    echo "错误：Transmission-daemon 配置更新失败."
                    exit 1
                fi

                sudo service transmission-daemon start

                if [ $? -ne 0 ]; then
                    echo "错误：无法启动 Transmission-daemon 服务."
                    exit 1
                fi

                echo "Transmission 已开启ipv6."
                echo "配置更新成功！"
            }

            case $choice in
            1)
                change_aria2_path
                ;;
            2)
                change_bt_path
                ;;
            3)
                aria2_bt_ipv6_path
                ;;
            q | Q)
                break
                ;;
            *)
                echo "无效的选择，请重新输入"
                ;;
            esac
            echo "按任意键继续..."
            read -n 1 -s -r -p ""
        done
        ;;
    5)
        # speedtest测速
        if ! command -v speedtest &>/dev/null; then
            echo -e "${YELLOW}Speedtest CLI is not installed${NC}"

            echo -e "${YELLOW}正在安装 Speedtest CLI...${NC}"
            curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
            sudo apt-get install speedtest

            if command -v speedtest &>/dev/null; then
                echo -e "${GREEN}Speedtest CLI安装成功.${NC}"
            else
                echo -e "${RED}未能安装Speedtest CLI.${NC}"
                exit 1
            fi
        else
            echo -e "${GREEN}Speedtest CLI 已安装，正在测试网速...${NC}"
            speedtest
        fi
        echo "按任意键继续..."
        read -n 1 -s -r -p ""
        ;;
    6)
        # 调用格式化脚本
        format-disk.sh
        echo -e "${GREEN}格式化完成${NC}"
        echo "按任意键继续..."
        read -n 1 -s -r -p ""
        ;;
    7)
        # Docker菜单
        while true; do
            clear
            echo -e "${GREEN}====== Docker管理脚本 ====== ${NC}"
            echo -e "${YELLOW}1. 显示所有容器${NC}"
            echo -e "${YELLOW}2. 显示所有镜像${NC}"
            echo -e "${YELLOW}3. 启动容器${NC}"
            echo -e "${YELLOW}4. 停止容器${NC}"
            echo -e "${YELLOW}5. 重启容器${NC}"
            echo -e "${YELLOW}6. 删除容器${NC}"
            echo -e "${YELLOW}7. 删除镜像${NC}"
            echo -e "${YELLOW}8. 安装docker${NC}"
            echo -e "${YELLOW}9. 卸载docker${NC}"
            echo -e "${YELLOW}10.安装Portainer${NC}"
            echo -e "${YELLOW}11.安装青龙面板${NC}"
            echo -e "${YELLOW}12.安装DDNSGO${NC}"
            echo -e "${YELLOW}13.安装小雅${NC}"
            echo -e "${YELLOW}14.安装Lucky${NC}"
            echo -e "${YELLOW}15.安装Uptime Kuma${NC}"
            echo -e "${RED}q. 返回${NC}"
            read -p "请输入选项: " choice

            function check_docker_installed() {
                if ! command -v docker &>/dev/null; then
                    echo -e "${RED}请先安装Docker${NC}"
                    return 1
                fi
            }

            function install_docker() {
                # 调用安装 Docker 的脚本
                install-docker.sh
            }

            function uninstall_docker() {
                # 卸载docker
                check_docker_installed || return 1
                sudo apt-get purge docker-ce docker-ce-cli containerd.io
                sudo rm -rf /var/lib/docker
                sudo rm /usr/local/bin/docker-compose
                echo -e "${GREEN}Docker卸载完成${NC}"
            }

            function install_portainer() {
                check_docker_installed || return 1
                # 调用安装 Portainer 的脚本
                install-portainer.sh
            }

            function install_qinglong() {
                check_docker_installed || return 1
                # 调用安装青龙面板的脚本
                install-qinglong.sh
            }

            function install_ddnsgo() {
                check_docker_installed || return 1
                # 安装ddnsgo
                docker run -d --name ddns-go --restart=always --net=host -v /opt/ddns-go:/root jeessy/ddns-go
                # 图标
                curl -o /var/www/html/img/png/ddnsgo.png https://raw.githubusercontent.com/LX-webo/hinas/main/ddnsgo.png

                cat <<EOF >/var/www/html/icons_wan/ddnsgo.html
            <li>
                <a href="http://<?php echo \$lanip ?>:9876" target="_blank"><img class="shake" src="img/png/ddnsgo.png" /><strong>DDNSGO</strong></a>
            </li>
EOF
                echo -e "${GREEN}安装完成，web地址: $IP:9876${NC}"
            }

            function show_running_containers() {
                check_docker_installed || return 1
                echo -e "${GREEN}================================================ 所有容器 ================================================${NC}"
                # 获取容器的信息
                docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.CreatedAt}}\t{{.Status}}"
                echo -e "${GREEN}=========================================================================================================${NC}"
            }

            function show_images() {
                check_docker_installed || return 1
                echo -e "${GREEN}================================================ 所有镜像 ================================================${NC}"
                # 获取镜像的信息
                docker images
                echo -e "${GREEN}=========================================================================================================${NC}"
            }

            function start_container() {
                check_docker_installed || return 1
                read -p "请输入容器名称: " container_name
                docker start $container_name

                if [ $? -eq 0 ]; then
                    echo "容器 $container_name 已成功启动."
                else
                    echo "启动容器 $container_name 失败."
                fi
            }

            function stop_container() {
                check_docker_installed || return 1
                read -p "请输入容器名称: " container_name
                docker stop $container_name

                if [ $? -eq 0 ]; then
                    echo "容器 $container_name 已成功停止."
                else
                    echo "停止容器 $container_name 失败."
                fi
            }

            function restart_container() {
                check_docker_installed || return 1
                read -p "请输入容器名称: " container_name
                docker restart $container_name

                if [ $? -eq 0 ]; then
                    echo "容器 $container_name 已成功重启."
                else
                    echo "重启容器 $container_name 失败."
                fi
            }

            function remove_container() {
                check_docker_installed || return 1
                read -p "请输入容器名称: " container_name
                docker rm $container_name

                if [ $? -eq 0 ]; then
                    echo "容器 $container_name 已成功删除."
                else
                    echo "删除容器 $container_name 失败."
                fi
            }

            function remove_image() {
                check_docker_installed || return 1
                read -p "请输入镜像名称: " image_name
                docker rmi $image_name

                if [ $? -eq 0 ]; then
                    echo "镜像 $image_name 已成功删除."
                else
                    echo "删除镜像 $image_name 失败."
                fi
            }

            function xiaoya() {
                check_docker_installed || return 1
                clear
                echo -e "${YELLOW}====================================================================================================${NC}"
                echo -e "${CYAN}=== 安装小雅前请先获取token、opentoken、文件夹ID ===${NC}"
                echo -e "${CYAN}token获取链接：    |   https://aliyuntoken.vercel.app/                            |
                   |   https://alist.nn.ci/zh/guide/drivers/aliyundrive.html      |
                   |                                                              |
opentoken获取链接：|   https://alist.nn.ci/zh/guide/drivers/aliyundrive_open.html | 
文件夹ID：         |   浏览器地址复制                                             |${NC}"
                echo -e "${YELLOW}====================================================================================================${NC}"
                # 小雅docker菜单
                echo -e "${GREEN}======= 小雅Docker ======= ${NC}"
                echo -e "${YELLOW}1.安装小雅 ${NC}"
                echo -e "${YELLOW}2.获取小雅令牌 ${NC}"
                echo -e "${YELLOW}3.定时同步数据 ${NC}"
                echo -e "${YELLOW}4.自动清理阿里云视频缓存 ${NC}"
                echo -e "${RED}q.返回 ${NC}"
                read -p "请输入选项: " choice
                case $choice in
                1)
                    # 确认信息
                    read -p "是否准备好安装所需文件？（y/n): " confirmation

                    if [[ $confirmation == "y" ]]; then
                        bash -c "$(curl http://docker.xiaoya.pro/update_new.sh)" -s host
                        # 图标
                        curl -o /var/www/html/img/png/xiaoya.png https://raw.githubusercontent.com/LX-webo/hinas/main/xiaoya.png
                        cat <<EOF >/var/www/html/icons_wan/xiaoya.html
            <li>
                <a href="http://<?php echo \$lanip ?>:5678" target="_blank"><img class="shake" src="img/png/xiaoya.png" /><strong>Alist小雅</strong></a>
            </li>
EOF
                        echo -e "${GREEN}安装完成，web地址: $IP:5678${NC}"
                    elif [[ $confirmation == "n" ]]; then
                        echo -e "${RED}取消安装小雅docker${NC}"
                    else
                        echo -e "${RED}无效的选项，取消安装小雅Docker.${NC}"
                    fi
                    ;;
                2)
                    #获取小雅令牌
                    docker exec -i xiaoya sqlite3 data/data.db <<EOF
select value from x_setting_items where key = "token";
EOF
                    ;;
                3)
                    # 设置定时同步任务

                    # 清理旧有的定时同步任务
                    cron_task="docker restart xiaoya"
                    crontab -l | sed -e "\@$cron_task@d" | crontab -

                    # 添加新的定时同步任务
                    cron_task="0 6 * * * docker restart xiaoya"
                    crontab -l | {
                        cat
                        echo "$cron_task"
                    } | crontab -
                    echo -e "${GREEN}已添加定时同步：每日6点同步数据${NC}"
                    ;;
                4)
                    #清理阿里云缓存
                    bash -c "$(curl -s https://xiaoyahelper.ddsrem.com/aliyun_clear.sh | tail -n +2)" -s 5
                    echo "按任意键继续..."
                    read -n 1 -s -r -p ""
                    ;;
                q | Q)
                    return 1
                    ;;
                *)
                    echo -e "${RED}无效的选项${NC}"
                    ;;
                esac
            }

            function Lucky() {
                check_docker_installed || return 1
                docker run -d --name lucky --restart=always --net=host gdy666/lucky
                # 图标
                curl -o /var/www/html/img/png/lucky.png https://raw.githubusercontent.com/LX-webo/hinas/main/lucky.png
                cat <<EOF >/var/www/html/icons_wan/lucky.html
            <li>
                <a href="http://<?php echo \$lanip ?>:16601" target="_blank"><img class="shake" src="img/png/lucky.png" /><strong>Lucky</strong></a>
            </li>
EOF
                echo -e "${GREEN}安装完成，web地址: $IP:16601${NC}"
            }

            function UptimeKuma() {
                check_docker_installed || return 1
                docker run -d --restart=always -p 3001:3001 -v uptime-kuma:/app/data --name uptime-kuma louislam/uptime-kuma:1
                # 图标
                curl -o /var/www/html/img/png/UptimeKuma.png https://raw.githubusercontent.com/LX-webo/hinas/main/UptimeKuma.png
                cat <<EOF >/var/www/html/icons_lan/UptimeKuma.html
            <li>
                <a href="http://<?php echo \$lanip ?>:3001" target="_blank"><img class="shake" src="img/png/UptimeKuma.png" /><strong>UptimeKuma</strong></a>
            </li>
EOF
                echo -e "${GREEN}安装完成，web地址: $IP:3001${NC}"
            }

            case $choice in
            1) show_running_containers ;;
            2) show_images ;;
            3) start_container ;;
            4) stop_container ;;
            5) restart_container ;;
            6) remove_container ;;
            7) remove_image ;;
            8) install_docker ;;
            9) uninstall_docker ;;
            10) install_portainer ;;
            11) install_qinglong ;;
            12) install_ddnsgo ;;
            13) xiaoya ;;
            14) Lucky ;;
            15) UptimeKuma ;;
            q | Q)
                break
                ;;
            *)
                echo -e "${RED}无效的选项${NC}"
                ;;
            esac
            echo "按任意键继续..."
            read -n 1 -s -r -p ""
        done
        ;;
    8)
        # 安装 Cockpit
        sudo apt install cockpit
        # 图标
        curl -o /var/www/html/img/png/cockpit.png https://raw.githubusercontent.com/LX-webo/hinas/main/cockpit.png
        cat <<EOF >/var/www/html/icons_lan/cockpit.html
            <li>
                <a href="http://<?php echo \$lanip ?>:9090" target="_blank"><img class="shake" src="img/png/cockpit.png" /><strong>Cockpit</strong></a>
            </li>
EOF
        echo -e "${GREEN}安装完成，web地址: $IP:9090${NC}"
        echo "按任意键继续..."
        read -n 1 -s -r -p ""
        ;;

    9)
        # 系统迁移菜单
        while true; do
            clear
            echo -e "${GREEN}选择一个操作：${NC}"
            echo -e "${YELLOW}1.制作U盘、TF启动系统，建议先备份EMMC启动文件${NC}"
            echo -e "${YELLOW}2.备份EMMC、TF、USB 存储启动系统文件${NC}"
            echo -e "${YELLOW}3.恢复EMMC、TF、USB 存储启动系统文件${NC}"
            echo -e "${RED}q.返回${NC}"
            read -p "请输入选项: " menu_choice

            case "$menu_choice" in
            1)
                # 创建目录
                echo -e "${RED}系统创建中，请耐心等待...${NC}"
                sudo mkdir /mnt/mm8 && sudo mount /dev/mmcblk0p8 /mnt/mm8

                platformbit=$(getconf LONG_BIT)
                if [ "${platformbit}" == '64' ]; then
                    cp /mnt/mm8/backup-64.gz /home/ubuntu
                    gunzip /home/ubuntu/backup-64.gz
                    backup_file=/home/ubuntu/backup-64
                else
                    cp /mnt/mm8/backup-32.gz /home/ubuntu
                    gunzip /home/ubuntu/backup-32.gz
                    backup_file=/home/ubuntu/backup-32
                fi

                umount /mnt/mm8 && rm -rf /mnt/mm8
                # 写入TF卡或USB驱动器
                echo "选择新的系统位置："
                echo -e "${GREEN}1.TF卡${NC}"
                echo -e "${GREEN}2.USB驱动器${NC}"
                read -p "请输入选项: " device_choice

                case "$device_choice" in
                1)
                    target_partition="/dev/mmcblk1p1"
                    mount_point="/mnt/mmcblk1p1"
                    new_content="root=/dev/mmcblk1p1"
                    ;;
                2)
                    target_partition="/dev/sda1"
                    mount_point="/mnt/sda1"
                    new_content="root=/dev/sda1"
                    ;;
                *)
                    echo -e "${RED}无效的选择${NC}"
                    break
                    ;;
                esac

                # dd 写入选定设备
                echo "正在写入设备... ($target_partition)"
                dd if="$backup_file" of="$target_partition" bs=4M status=progress
                rm -f "$backup_file"

                # 检查调整分区
                echo -e "${YELLOW}自动调整分区 (${target_partition})${NC}"

                umount "$target_partition"
                e2fsck -f "$target_partition"
                resize2fs "$target_partition"
                mount "$target_partition" "$mount_point"

                # 制作bootargs.bin

                file_path="/etc/bootargs_input.txt"
                original_content=$(cat $file_path)

                # 替换root参数
                sed -i "s|root=/dev/[a-zA-Z0-9_]*|${new_content}|" $file_path

                # 生成bootargs.bin
                mkbootargs -s 64 -r /etc/bootargs_input.txt -o bootargs.bin >/dev/null

                # 还原root参数
                sed -i "s|root=/dev/[a-zA-Z0-9_]*|root=/dev/mmcblk0p9|" $file_path

                # 命令刷入
                echo -e "\n${YELLOW}正在写入启动文件...${NC}"
                dd if=bootargs.bin of=/dev/mmcblk0p2 bs=1024 count=1024
                rm -f bootargs.bin

                read -p "切换系统完成，请重启设备 (y/n): " confirm_reboot
                if [ "$confirm_reboot" = "y" ]; then
                    echo -e "${GREEN}重启设备...${NC}"
                    reboot
                else
                    echo -e "${RED}取消重启设备，请稍后手动重启设备以使更改生效${NC}"
                    echo "按任意键继续..."
                    read -n 1 -s -r -p ""
                    break
                fi
                ;;
            2)
                # 备份EMMC、TF、USB菜单
                clear
                echo -e "${GREEN}备份EMMC、TF、USB 存储启动系统文件${NC}"
                echo -e "${YELLOW}1.备份EMMC启动: ${NC}"
                echo -e "${YELLOW}2.备份TF启动: ${NC}"
                echo -e "${YELLOW}3.备份USB启动: ${NC}"
                echo -e "${RED}q.返回${NC}"

                read -p "请输入选项: " backup_type

                case "$backup_type" in
                1)
                    # 备份EMMC
                    echo -e "${GREEN}备份EMMC启动${NC}"
                    read -p "是否确认备份EMMC启动？ (y/n): " confirm_emmc_backup
                    if [ "$confirm_emmc_backup" = "y" ]; then
                        dd if=/dev/mmcblk0p2 of=/mnt/sda1/hi3798mv100_bootargs_emmc_backup.img
                        echo -e "${GREEN}EMMC启动备份完成${NC}"
                    else
                        echo -e "${RED}取消EMMC启动备份${NC}"

                    fi
                    ;;
                2)
                    # 备份TF
                    echo -e "${GREEN}备份TF启动${NC}"
                    read -p "是否确认备份TF启动？ (y/n): " confirm_tf_backup
                    if [ "$confirm_tf_backup" = "y" ]; then
                        dd if=/dev/mmcblk0p2 of=/mnt/sda1/hi3798mv100_bootargs_tf_backup.img
                        echo -e "${GREEN}TF启动备份完成${NC}"
                    else
                        echo -e "${RED}取消TF启动备份${NC}"
                    fi
                    ;;
                3)
                    # 备份USB
                    echo -e "${GREEN}备份USB启动${NC}"
                    read -p "是否确认备份USB启动？ (y/n): " confirm_usb_backup
                    if [ "$confirm_usb_backup" = "y" ]; then
                        dd if=/dev/mmcblk0p2 of=/mnt/sda1/hi3798mv100_bootargs_usb_backup.img
                        echo -e "${GREEN}USB启动备份完成${NC}"
                    else
                        echo -e "${RED}取消USB启动备份${NC}"
                    fi
                    ;;
                q | Q)
                    continue
                    ;;
                *)
                    echo -e "${RED}无效的选择${NC}"
                    ;;
                esac
                ;;
            3)
                # 恢复EMMC、TF、USB菜单
                clear
                echo -e "${GREEN}恢复EMMC、TF、USB 存储启动系统文件${NC}"
                echo -e "${YELLOW}1.恢复EMMC启动${NC}"
                echo -e "${YELLOW}2.恢复TF启动${NC}"
                echo -e "${YELLOW}3.恢复USB启动${NC}"
                echo -e "${RED}q.返回${NC}"

                read -p "请输入选项: " restore_type

                case "$restore_type" in
                1)
                    # 恢复EMMC
                    echo -e "${GREEN}恢复EMMC启动${NC}"
                    read -p "是否确认恢复EMMC启动？ (y/n): " confirm_emmc_restore
                    if [ "$confirm_emmc_restore" = "y" ]; then
                        if [ -f "/mnt/sda1/hi3798mv100_bootargs_emmc_backup.img" ]; then
                            dd if=/mnt/sda1/hi3798mv100_bootargs_emmc_backup.img of=/dev/mmcblk0p2
                            read -p "EMMC启动恢复完成，是否重启设备 (y/n): " confirm_reboot
                            if [ "$confirm_reboot" = "y" ]; then
                                echo -e "${GREEN}重启设备...${NC}"
                                reboot
                            else
                                echo -e "${RED}取消重启设备，请稍后手动重启设备以使更改生效${NC}"
                            fi
                        else
                            echo -e "${RED}备份文件 hi3798mv100_bootargs_emmc_backup.img 不存在，无法执行EMMC启动恢复${NC}"
                        fi
                    else
                        echo -e "${RED}取消EMMC启动恢复${NC}"
                    fi
                    ;;
                2)
                    # 恢复TF
                    echo -e "${GREEN}恢复TF启动${NC}"
                    read -p "是否确认恢复TF启动？ (y/n): " confirm_tf_restore
                    if [ "$confirm_tf_restore" = "y" ]; then
                        if [ -f "/mnt/sda1/hi3798mv100_bootargs_tf_backup.img" ]; then
                            dd if=/mnt/sda1/hi3798mv100_bootargs_tf_backup.img of=/dev/mmcblk0p2
                            read -p "TF启动恢复完成，是否重启设备 (y/n): " confirm_reboot
                            if [ "$confirm_reboot" = "y" ]; then
                                echo -e "${GREEN}重启设备...${NC}"
                                reboot
                            else
                                echo -e "${RED}取消重启设备，请稍后手动重启设备以使更改生效${NC}"
                            fi
                        else
                            echo -e "${RED}备份文件 hi3798mv100_bootargs_tf_backup.img 不存在，无法执行tf启动恢复${NC}"
                        fi
                    else
                        echo -e "${RED}取消tf启动恢复${NC}"
                    fi
                    ;;
                3)
                    # 恢复USB
                    echo -e "${GREEN}恢复USB启动${NC}"
                    read -p "是否确认恢复USB启动？ (y/n): " confirm_usb_restore
                    if [ "$confirm_usb_restore" = "y" ]; then
                        if [ -f "/mnt/sda1/hi3798mv100_bootargs_usb_backup.img" ]; then
                            dd if=/mnt/sda1/hi3798mv100_bootargs_usb_backup.img of=/dev/mmcblk0p2
                            read -p "USB启动恢复完成，是否重启设备 (y/n): " confirm_reboot
                            if [ "$confirm_reboot" = "y" ]; then
                                echo -e "${GREEN}重启设备...${NC}"
                                reboot
                            else
                                echo -e "${RED}取消重启设备，请稍后手动重启设备以使更改生效${NC}"
                            fi
                        else
                            echo -e "${RED}备份文件 hi3798mv100_bootargs_usb_backup.img 不存在，无法执行usb启动恢复${NC}"
                        fi
                    else
                        echo -e "${RED}取消usb启动恢复${NC}"
                    fi
                    ;;
                q | Q)
                    continue
                    ;;
                *)
                    echo -e "${RED}无效的选择${NC}"
                    ;;
                esac
                ;;

            q | Q)
                break
                ;;
            *)
                # 无效选项
                echo -e "${RED}无效的选择${NC}"
                ;;
            esac
            echo "按任意键继续..."
            read -n 1 -s -r -p ""
        done
        ;;
    10)
        # 安装tailscale穿透

        #停止固件自带的tailscale
        systemctl stop tailscaled
        #关闭固件自带的tailscale的开机自启
        systemctl disable tailscaled
        #删除执行文件和服务文件
        rm -rf /usr/bin/tailscaled
        rm -rf /etc/systemd/system/tailscaled.service
        #执行官方的安装脚本
        curl -fsSL https://tailscale.com/install.sh | sh
        #启动软件并设为自启
        systemctl start tailscaled
        systemctl enable tailscaled
        #启动软件，并在链接中登录
        tailscale up
        echo "安装完成，请打开链接登入账户"
        echo "按任意键继续..."
        read -n 1 -s -r -p ""
        ;;

    11)
        # 图标
        curl -o /var/www/html/img/png/httpsok.png https://raw.githubusercontent.com/LX-webo/hinas/main/httpsok.png

        cat <<EOF >/var/www/html/icons_wan/httpsok.html
            <li>
                <a href="https://httpsok.com/login" target="_blank"><img class="shake" src="img/png/httpsok.png" /><strong>Httpsok</strong></a>
            </li>
EOF
        echo -e "${GREEN}安装完成，刷新点击主页图标${NC}"
        echo "按任意键继续..."
        read -n 1 -s -r -p ""
        ;;
    12)
        # socks5服务功能
    	while true; do
        clear
        echo -e "${GREEN}====== socks5服务功能 ====== ${NC}"
        echo -e "${YELLOW}1. 搭建v2ray客户端${NC}"
        echo -e "${YELLOW}2. 测试是否联通${NC}"
        echo -e "${YELLOW}3. 重启v2ray${NC}"
        echo -e "${YELLOW}4. 开启代理本机${NC}"
        echo -e "${YELLOW}5. 关闭代理本机${NC}"
	echo -e "${YELLOW}6. 测试本机代理${NC}"
        echo -e "${YELLOW}7. 卸载服务${NC}"
        echo -e "${RED}q. 返回${NC}"
        read -p "请输入选项: " choice

        function socks5() {
            install-v2ray.sh --version v5.6.0
            echo -e "${GREEN}安装完成！配置文件的位置：/usr/local/etc/v2ray/config.json${NC}"
            echo -e "${GREEN}编辑修改保存这个配置文件后，输入以下命令重启客户端服务：${NC}"
            echo -e "${GREEN}systemctl daemon-reload${NC}"
            echo -e "${GREEN}systemctl restart v2ray${NC}"
        }

        function test() {
            curl --socks5 127.0.0.1:10808 google.com
        }

        function restart() {
            systemctl restart v2ray
            echo -e "${GREEN}重启成功${NC}"
        }

        function on() {
    	echo 'export https_proxy="127.0.0.1:10809"' >> ~/.bashrc
    	source ~/.bashrc
    	echo -e "${GREEN}代理已设置为永久生效。${NC}"
	}

        function off() {
    	sed -i '/export https_proxy="127.0.0.1:10809"/d' ~/.bashrc
    	source ~/.bashrc
    	echo -e "${GREEN}代理已从 .bashrc 中移除。${NC}"
	}
 
	function test1() {
    	curl https://google.com
	}
 
        function uninstall() {
            install-v2ray.sh --remove
            rm /usr/local/etc/v2ray/config.json
            echo -e "${GREEN}卸载成功${NC}"
        }

        case "$choice" in
            1) socks5 ;;
            2) test ;;
            3) restart ;;
            4) on ;;
            5) off ;;
            6) test1 ;
            7) uninstall ;;   
            q) break ;;
            *) echo "无效选项，请重试" ;;
        esac

        read -p "按回车继续..." dummy
    done
    ;;

    update)
        sudo apt-get update
	sudo apt-get upgrade
        ;;

    caidanu)
        renew-caidan
        ;;
	
    caidanun)
        unInstall-caidan
        ;;
    0)
        # 系统还原
        echo -e "${RED}警告:此操作将还原系统,请做好资料备份，是否要继续？(y/n)${NC}"
        read -p "(y/n): " response

        if [ "$response" = "y" ]; then
            recoverbackup
        elif [ "$response" = "n" ]; then
            echo -e "${RED}取消操作${NC}"
        else
            echo -e "${RED}无效的选择${NC}"
        fi
        echo "按任意键继续..."
        read -n 1 -s -r -p ""
        ;;
    w | W)
        # 修改 root 密码
        sudo passwd root
        echo "按任意键继续..."
        read -n 1 -s -r -p ""
        ;;
    r | R)
        # 重启系统
        sudo reboot
        ;;
    q | Q)
        # 退出
        echo -e "${RED}已退出...${NC}"
        exit 1
        ;;
    *)
        echo -e "${RED}无效的选择${NC}"
        echo "按任意键继续..."
        read -n 1 -s -r -p ""
        ;;
    esac
done
