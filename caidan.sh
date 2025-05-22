#!/bin/bash
original_lc_all=$LC_ALL

# 定义main函数，确保脚本被调用时执行主菜单
main() {
    # 此函数将在脚本被直接执行时调用
    # 确保菜单正常显示并处理用户输入
    :
}

# 处理命令行参数
if [[ "$1" == "--download" ]]; then
    echo -e "\033[32m正在执行一键安装...\033[0m"
    # 创建安装目录
    mkdir -p /etc/caidan
    # 拷贝脚本到安装目录
    cp "$0" /etc/caidan/caidan.sh
    # 添加执行权限
    chmod +x /etc/caidan/caidan.sh
    # 创建软链接
    ln -sf /etc/caidan/caidan.sh /usr/bin/caidan
    # 修复可能的换行符问题
    sed -i 's/\r$//' /etc/caidan/caidan.sh 2>/dev/null
    echo -e "\033[32m------------------------------------\033[0m"
    echo -e "\033[32m脚本安装完成，输入 [caidan] 打开脚本\033[0m"
    echo -e "\033[32m------------------------------------\033[0m"
    exit 0
fi

# 加载代理环境变量（如果已配置）
if grep -q 'export.*_proxy=' ~/.bashrc; then
    # 从.bashrc提取代理设置并直接应用到当前会话
    proxy_https=$(grep 'export https_proxy=' ~/.bashrc | cut -d'"' -f2)
    proxy_http=$(grep 'export http_proxy=' ~/.bashrc | cut -d'"' -f2)
    proxy_all=$(grep 'export all_proxy=' ~/.bashrc | cut -d'"' -f2)

    # 只有在变量为空时才设置，避免覆盖已经设置的值
    [ -n "$proxy_https" ] && [ -z "$https_proxy" ] && export https_proxy="$proxy_https"
    [ -n "$proxy_http" ] && [ -z "$http_proxy" ] && export http_proxy="$proxy_http"
    [ -n "$proxy_all" ] && [ -z "$all_proxy" ] && export all_proxy="$proxy_all"
fi

# 颜色定义
RED='\e[91m'
GREEN='\e[92m'
YELLOW='\e[93m'
BLUE='\e[94m'
MAGENTA='\e[95m'
CYAN='\e[96m'
WHITE='\e[97m'
BOLD='\e[1m'
NC='\e[0m' # No Color

# IP
IP=$(ifconfig eth0 | grep '\<inet\>' | grep -v '127.0.0.1' | awk '{print $2}' | awk 'NR==1')

# 初始化安装目录
function mkdirTools() {
    mkdir -p /etc/caidan
}

# 脚本快捷方式安装
function install-caidan() {
    if [[ -f "./caidan.sh" ]]; then
        mkdir -p /etc/caidan
        mv ./caidan.sh /etc/caidan/caidan.sh
        chmod +x /etc/caidan/caidan.sh
        ln -sf /etc/caidan/caidan.sh /usr/bin/caidan

        echo -e "${GREEN}------------------------------------${NC}"
        echo -e "${GREEN}脚本安装完成，输入 [caidan] 打开脚本${NC}"
        echo -e "${GREEN}------------------------------------${NC}"
        exit 0
    fi
}

# 更新脚本 - 此函数保留兼容性，实际更新逻辑已移至主菜单
function renew-caidan() {
    echo -e "${YELLOW}正在使用兼容模式更新脚本...${NC}"

    # 创建备份
    backup_path="/etc/caidan/caidan.sh.backup-$(date +%Y%m%d%H%M%S)"
    if [ -f "/etc/caidan/caidan.sh" ]; then
        cp /etc/caidan/caidan.sh "$backup_path"
        echo -e "${CYAN}已创建备份: $backup_path${NC}"
    fi

    # 更新脚本
    if curl -s -o /etc/caidan/caidan.sh.new https://raw.githubusercontent.com/LeoJyenn/hinas/refs/heads/main/caidan.sh; then
        if [ -f "/etc/caidan/caidan.sh.new" ] && [ -s "/etc/caidan/caidan.sh.new" ]; then
            chmod +x /etc/caidan/caidan.sh.new
            mv /etc/caidan/caidan.sh.new /etc/caidan/caidan.sh
            ln -sf /etc/caidan/caidan.sh /usr/bin/caidan
            echo -e "${GREEN}✓ 脚本更新成功，重新执行 [caidan] 生效${NC}"
        else
            echo -e "${RED}✗ 下载的文件不完整${NC}"
            if [ -f "$backup_path" ]; then
                echo -e "${YELLOW}正在恢复备份...${NC}"
                cp "$backup_path" /etc/caidan/caidan.sh
            fi
        fi
    else
        echo -e "${RED}✗ 更新失败，请检查网络连接${NC}"
    fi
    exit 0
}

# 卸载脚本
function unInstall-caidan() {
    echo -e "${RED}是否确认卸载脚本？(y/n)${NC}"
    read -e -p "(y/n): " unInstallStatus

    if [[ "$unInstallStatus" == "y" ]]; then
        rm -rf /etc/caidan
        rm -f /usr/bin/caidan
        echo -e "${GREEN}------------------------------------${NC}"
        echo -e "${GREEN}脚本卸载完成${NC}"
        echo -e "${GREEN}------------------------------------${NC}"
        exit 0
    elif [[ "$unInstallStatus" == "n" ]]; then
        echo -e "${RED}取消卸载${NC}"
    else
        echo -e "${RED}无效的选择${NC}"
    fi
    echo "按任意键继续..."
    read -n 1 -s -r -p ""
}

mkdirTools
install-caidan

# 绘制菜单标题
function print_menu_header() {
    local title="$1"
    local width=70

    # 计算中文字符数量（每个中文字符在终端中占两个字符宽度）
    local chinese_count=$(echo "$title" | grep -o -P '\p{Han}' | wc -l)

    # 计算实际显示宽度（英文+中文*2）
    local display_width=$((${#title} + chinese_count))

    # 计算左侧填充空格数
    local left_padding=$(((width - display_width) / 2))

    # 计算右侧填充空格数
    local right_padding=$((width - display_width - left_padding))

    # 生成标题栏
    echo -e "${BLUE}┌$(printf '%.0s─' $(seq 1 $width))┐${NC}"
    echo -e "${BLUE}│${BOLD}${YELLOW}$(printf '%*s' $left_padding '')$title$(printf '%*s' $right_padding '')${NC}${BLUE}│${NC}"
    echo -e "${BLUE}└$(printf '%.0s─' $(seq 1 $width))┘${NC}"
}

# 绘制菜单选项
function print_menu_option() {
    local number="$1"
    local text="$2"
    local color="${3:-$YELLOW}"

    echo -e "  ${BOLD}${color}[$number]${NC} $text"
}

# 绘制菜单分隔线
function print_menu_separator() {
    echo -e "${BLUE}──────────────────────────────────────────────────────────────────────${NC}"
}

while true; do
    clear

    echo -e "${CYAN}
     _          _               _             ____                           _ 
    / \      __| |  _ __ ___   (_)  _ __     |  _ \    __ _   _ __     ___  | |
   / _ \    / _  | |  _   _ \  | | |  _ \    | |_) |  / _  | |  _ \   / _ \ | |
  / ___ \  | (_| | | | | | | | | | | | | |   |  __/  | (_| | | | | | |  __/ | |
 /_/   \_\  \__,_| |_| |_| |_| |_| |_| |_|   |_|      \__,_| |_| |_|  \___| |_|
                                                                               
${NC}"

    # 主菜单
    print_menu_header "海纳思系统管理菜单"

    print_menu_option "1" "常用功能"
    print_menu_option "2" "中文语言包"
    print_menu_option "3" "系统检查"
    print_menu_option "4" "Aria2、BT"
    print_menu_option "5" "网络测速"
    print_menu_option "6" "格式化U盘、TF卡"
    print_menu_option "7" "Docker"
    print_menu_option "8" "Cockpit"
    print_menu_option "9" "系统迁移"
    print_menu_option "10" "Tailscale"

    # 检查代理状态并显示
    function check_proxy_status() {
        local v2ray_running=false
        local proxy_configured=false

        # 检查v2ray服务是否运行
        if systemctl is-active --quiet v2ray 2>/dev/null; then
            v2ray_running=true
        fi

        # 检查代理是否在.bashrc中配置
        if grep -q 'export.*_proxy=' ~/.bashrc; then
            proxy_configured=true
        fi

        # 优先检查当前会话是否有代理环境变量
        if [ -n "$https_proxy" ] || [ -n "$http_proxy" ] || [ -n "$all_proxy" ]; then
            if [ "$v2ray_running" = true ]; then
                echo "${GREEN}[活跃]${NC}"
            else
                echo "${YELLOW}[已配置但服务未运行]${NC}"
            fi
        # 其次检查是否在.bashrc中配置了但未加载到当前会话
        elif [ "$proxy_configured" = true ]; then
            if [ "$v2ray_running" = true ]; then
                echo "${YELLOW}[配置未激活]${NC}"
            else
                echo "${YELLOW}[配置未激活,服务未运行]${NC}"
            fi
        else
            echo "${RED}[未激活]${NC}"
        fi
    }

    print_menu_option "11" "socks5服务功能 $(check_proxy_status)"

    print_menu_separator

    # 系统命令选项，使用简化字母命令
    echo -e "  ${BOLD}${RED}[a]${NC} 系统更新和软件更新    ${BOLD}${RED}[b]${NC} 系统还原"
    echo -e "  ${BOLD}${RED}[c]${NC} 更新脚本            ${BOLD}${RED}[d]${NC} 修改root密码"
    echo -e "  ${BOLD}${RED}[e]${NC} 卸载脚本            ${BOLD}${RED}[f]${NC} 重启系统"
    echo -e "  ${BOLD}${RED}[q]${NC} 退出"

    # 获取输入
    echo
    read -e -p "请输入选项: " choice

    case $choice in
    1)
        #常用功能菜单
        while true; do
            clear
            print_menu_header "常用功能"

            print_menu_option "1" "搜索文件"
            print_menu_option "2" "重启网络服务"
            print_menu_option "3" "清理缓存"
            print_menu_option "4" "Swap设置"
            print_menu_option "5" "粒子动态背景"
            print_menu_option "6" "优化DNS"
            print_menu_option "7" "Nginx管理"
            print_menu_option "q" "返回" $RED

            echo
            read -e -p "请输入选项: " choice

            #搜索文件和文件夹
            function search_files() {
                read -e -p "请输入要搜索的关键词: " keyword
                read -e -p "请输入要搜索的目录路径（按 Enter 键跳过，整个系统搜索）: " search_path

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
                clear
                print_menu_header "系统清理工具"

                # 获取磁盘使用状态
                disk_usage=$(df -h / | awk 'NR==2 {print $5}')
                disk_free=$(df -h / | awk 'NR==2 {print $4}')
                echo -e "${CYAN}当前系统状态: 使用率 ${YELLOW}$disk_usage${CYAN} (剩余空间: ${GREEN}$disk_free${CYAN})${NC}\n"

                print_menu_option "1" "标准清理 (安全清理缓存和临时文件)"
                print_menu_option "2" "深度清理 (包括系统日志和备份)"
                print_menu_option "3" "高级清理 (删除未使用的依赖和内核)"
                print_menu_option "4" "优化服务 (禁用不必要的系统服务)"
                print_menu_option "5" "全面系统清理 (执行所有清理操作)"
                print_menu_option "q" "返回" $RED

                echo
                read -e -p "请选择清理级别: " clean_level

                case "$clean_level" in
                1) # 标准清理
                    echo -e "\n${YELLOW}执行标准清理...${NC}"
                    echo -e "${CYAN}清理APT缓存...${NC}"
                    sudo apt-get clean

                    echo -e "${CYAN}清理临时文件...${NC}"
                    sudo rm -rf /tmp/.[!.]* /tmp/..?* /tmp/*

                    echo -e "${CYAN}清理用户缓存...${NC}"
                    rm -rf ~/.cache/*

                    echo -e "${CYAN}清理回收站...${NC}"
                    rm -rf ~/.local/share/Trash/*

                    echo -e "${CYAN}清理软件包缓存...${NC}"
                    sudo apt-get autoclean

                    # 获取清理后的磁盘使用情况
                    disk_after=$(df -h / | awk 'NR==2 {print $4}')
                    echo -e "\n${GREEN}✓ 标准清理完成!${NC}"
                    echo -e "${CYAN}当前可用空间: $disk_after${NC}"
                    ;;

                2) # 深度清理
                    echo -e "\n${YELLOW}执行深度清理...${NC}"

                    # 先执行标准清理
                    echo -e "${CYAN}执行标准清理步骤...${NC}"
                    sudo apt-get clean
                    sudo rm -rf /tmp/.[!.]* /tmp/..?* /tmp/*
                    rm -rf ~/.cache/*
                    rm -rf ~/.local/share/Trash/*
                    sudo apt-get autoclean

                    # 深度清理特有步骤
                    echo -e "${CYAN}清理系统日志...${NC}"
                    sudo journalctl --vacuum-time=3d

                    echo -e "${CYAN}清理旧的备份文件...${NC}"
                    sudo rm -rf /var/backups/*.old 2>/dev/null

                    echo -e "${CYAN}清理旧的安装包...${NC}"
                    sudo rm -rf /var/cache/apt/archives/*.deb

                    echo -e "${CYAN}清理临时数据目录...${NC}"
                    sudo rm -rf /var/tmp/.[!.]* /var/tmp/..?* /var/tmp/* 2>/dev/null

                    echo -e "${CYAN}清理遗留的日志文件...${NC}"
                    sudo find /var/log -type f -name "*.gz" -o -name "*.old" -o -name "*.1" | xargs sudo rm -f 2>/dev/null
                    sudo find /var/log -type f -regex '.*\.[0-9]+\(\.gz\)?' | xargs sudo rm -f 2>/dev/null

                    echo -e "\n${GREEN}✓ 深度清理完成!${NC}"
                    ;;

                3) # 高级清理
                    echo -e "\n${YELLOW}执行高级清理 (依赖和内核)...${NC}"
                    echo -e "${RED}警告: 此操作将移除未使用的软件包和旧内核，确认继续? (y/n)${NC}"
                    read -e -p "" confirm
                    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                        echo -e "${CYAN}删除未使用的依赖项...${NC}"
                        sudo apt-get autoremove -y

                        echo -e "${CYAN}删除旧版本的Linux内核...${NC}"
                        old_kernels=$(dpkg -l | awk '/^ii linux-image-.*[0-9]/{print $2}' | grep -v "$(uname -r)")
                        if [ -n "$old_kernels" ]; then
                            echo -e "${YELLOW}发现以下旧内核:${NC}"
                            echo "$old_kernels"
                            echo -e "${YELLOW}正在删除...${NC}"
                            sudo apt-get purge -y $old_kernels
                        else
                            echo -e "${CYAN}未发现旧内核${NC}"
                        fi

                        echo -e "${CYAN}清理未完全卸载的软件包...${NC}"
                        dpkg_removed=$(dpkg -l | grep "^rc" | awk '{print $2}')
                        if [ -n "$dpkg_removed" ]; then
                            echo -e "${YELLOW}发现以下未完全卸载的软件包:${NC}"
                            echo "$dpkg_removed"
                            echo -e "${YELLOW}正在清理...${NC}"
                            sudo dpkg --purge $dpkg_removed
                        else
                            echo -e "${CYAN}未发现未完全卸载的软件包${NC}"
                        fi

                        echo -e "${CYAN}检查Snap包...${NC}"
                        if command -v snap &>/dev/null; then
                            # 保留当前及前一个版本，删除更旧的版本
                            sudo snap list --all | awk '/disabled/{print $1, $3}' |
                                while read snapname revision; do
                                    sudo snap remove "$snapname" --revision="$revision"
                                done
                        fi

                        echo -e "${CYAN}检查Flatpak残留...${NC}"
                        if command -v flatpak &>/dev/null; then
                            sudo flatpak uninstall --unused -y
                        fi

                        echo -e "\n${GREEN}✓ 高级清理完成!${NC}"
                    else
                        echo -e "${YELLOW}已取消高级清理${NC}"
                    fi
                    ;;

                4) # 优化服务
                    echo -e "\n${YELLOW}分析系统服务...${NC}"

                    # 创建常见非必要服务列表
                    declare -A services_desc=(
                        ["bluetooth.service"]="蓝牙服务 - 如果不使用蓝牙设备可禁用"
                        ["cups.service"]="打印服务 - 如果不需要打印功能可禁用"
                        ["avahi-daemon.service"]="局域网设备发现服务 - 局域网内设备发现"
                        ["ModemManager.service"]="调制解调器管理服务 - 如不使用调制解调器可禁用"
                        ["whoopsie.service"]="Ubuntu崩溃报告服务 - 用于发送崩溃报告"
                        ["snapd.service"]="Snap包管理服务 - 如不使用snap可禁用"
                        ["apt-daily.service"]="APT自动更新服务 - 自动检查更新"
                        ["apt-daily-upgrade.service"]="APT自动升级服务"
                        ["multipathd.service"]="多路径设备管理服务 - 服务器存储多路径"
                        ["speech-dispatcher.service"]="语音调度服务 - 语音合成"
                    )

                    # 列出正在运行的服务
                    echo -e "${CYAN}检测非必要服务...${NC}"
                    echo -e "${YELLOW}===================${NC}"

                    running_services=()
                    for service in "${!services_desc[@]}"; do
                        if systemctl is-active --quiet "$service" 2>/dev/null; then
                            running_services+=("$service")
                            status="${GREEN}运行中${NC}"
                        else
                            status="${RED}已停止${NC}"
                        fi
                        echo -e "${CYAN}[$service]${NC} - ${services_desc[$service]} - $status"
                    done

                    if [ ${#running_services[@]} -eq 0 ]; then
                        echo -e "\n${CYAN}未发现可优化的非必要服务${NC}"
                    else
                        echo -e "\n${YELLOW}发现以下非必要服务正在运行:${NC}"
                        for ((i = 0; i < ${#running_services[@]}; i++)); do
                            service=${running_services[$i]}
                            echo -e "$((i + 1)). ${CYAN}${service}${NC} - ${services_desc[$service]}"
                        done

                        echo -e "\n${YELLOW}输入服务编号以禁用，多个服务用空格分隔 (例如: 1 3)，或按Enter跳过${NC}"
                        read -e -p "要禁用的服务: " services_to_disable

                        if [ -n "$services_to_disable" ]; then
                            for num in $services_to_disable; do
                                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#running_services[@]} ]; then
                                    service=${running_services[$((num - 1))]}
                                    echo -e "${YELLOW}正在禁用 $service...${NC}"
                                    sudo systemctl stop "$service"
                                    sudo systemctl disable "$service"
                                    echo -e "${GREEN}✓ $service 已禁用${NC}"
                                fi
                            done
                            echo -e "\n${GREEN}✓ 服务优化完成!${NC}"
                        else
                            echo -e "${YELLOW}未选择任何服务，跳过优化${NC}"
                        fi
                    fi
                    ;;

                5) # 全面系统清理
                    echo -e "\n${YELLOW}执行全面系统清理...${NC}"
                    echo -e "${RED}警告: 此操作将执行所有清理步骤，可能需要一些时间。确认继续? (y/n)${NC}"
                    read -e -p "" confirm
                    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                        disk_usage_before=$(df -h / | awk 'NR==2 {print $4}')
                        echo -e "${CYAN}清理前可用空间: $disk_usage_before${NC}"

                        # 标准清理
                        echo -e "\n${YELLOW}1. 执行标准清理...${NC}"
                        sudo apt-get clean
                        sudo rm -rf /tmp/.[!.]* /tmp/..?* /tmp/* 2>/dev/null
                        rm -rf ~/.cache/* 2>/dev/null
                        rm -rf ~/.local/share/Trash/* 2>/dev/null
                        sudo apt-get autoclean

                        # 深度清理
                        echo -e "\n${YELLOW}2. 执行深度清理...${NC}"
                        sudo journalctl --vacuum-time=3d
                        sudo rm -rf /var/backups/*.old 2>/dev/null
                        sudo rm -rf /var/cache/apt/archives/*.deb
                        sudo rm -rf /var/tmp/.[!.]* /var/tmp/..?* /var/tmp/* 2>/dev/null
                        sudo find /var/log -type f -name "*.gz" -o -name "*.old" -o -name "*.1" | xargs sudo rm -f 2>/dev/null
                        sudo find /var/log -type f -regex '.*\.[0-9]+\(\.gz\)?' | xargs sudo rm -f 2>/dev/null

                        # 高级清理
                        echo -e "\n${YELLOW}3. 执行高级清理...${NC}"
                        sudo apt-get autoremove -y

                        old_kernels=$(dpkg -l | awk '/^ii linux-image-.*[0-9]/{print $2}' | grep -v "$(uname -r)")
                        if [ -n "$old_kernels" ]; then
                            sudo apt-get purge -y $old_kernels
                        fi

                        dpkg_removed=$(dpkg -l | grep "^rc" | awk '{print $2}')
                        if [ -n "$dpkg_removed" ]; then
                            sudo dpkg --purge $dpkg_removed
                        fi

                        # 清理搜索索引
                        echo -e "\n${YELLOW}4. 清理搜索索引...${NC}"
                        if [ -d ~/.cache/tracker ]; then
                            rm -rf ~/.cache/tracker/* 2>/dev/null
                        fi
                        # 如果系统有mlocate，更新数据库
                        if command -v updatedb &>/dev/null; then
                            sudo updatedb
                        fi

                        # 清理缩略图
                        echo -e "\n${YELLOW}5. 清理缩略图缓存...${NC}"
                        rm -rf ~/.thumbnails/* 2>/dev/null
                        rm -rf ~/.cache/thumbnails/* 2>/dev/null

                        # 清理Firefox/Chrome缓存(如果存在)
                        echo -e "\n${YELLOW}6. 清理浏览器缓存...${NC}"
                        if [ -d ~/.mozilla/firefox ]; then
                            find ~/.mozilla/firefox -name "*.sqlite" | xargs -I{} sqlite3 "{}" "VACUUM;"
                        fi
                        if [ -d ~/.config/google-chrome ]; then
                            rm -rf ~/.config/google-chrome/Default/Cache/* 2>/dev/null
                            rm -rf ~/.config/google-chrome/Default/Code\ Cache/* 2>/dev/null
                        fi

                        disk_usage_after=$(df -h / | awk 'NR==2 {print $4}')
                        echo -e "\n${GREEN}✓ 全面系统清理完成!${NC}"
                        echo -e "${CYAN}清理前可用空间: $disk_usage_before${NC}"
                        echo -e "${CYAN}清理后可用空间: $disk_usage_after${NC}"
                    else
                        echo -e "${YELLOW}已取消全面系统清理${NC}"
                    fi
                    ;;

                q | Q)
                    return
                    ;;

                *)
                    echo -e "${RED}无效的选择${NC}"
                    ;;
                esac

                echo -e "\n${CYAN}清理操作已完成，系统现在更加整洁!${NC}"
            }

            # Swap设置脚本
            function swap() {
                read -e -p "请输入 vm.swappiness 的值 (回车默认为 60): " swappiness_value

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
                read -e -p "请输入Swap交换区大小（回车默认为1024M）: " swap_size

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
                read -e -p "是否重启设备以使更改生效？ (y/n): " confirm_reboot
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

            # Nginx管理函数
            function nginx_manager() {
                clear
                print_menu_header "Nginx管理工具"

                local nginx_installed=false
                local nginx_running=false
                local nginx_version=""

                # 检查Nginx是否已安装
                if command -v nginx &>/dev/null; then
                    nginx_installed=true
                    nginx_version=$(nginx -v 2>&1 | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")

                    # 检查Nginx状态
                    if systemctl is-active --quiet nginx; then
                        nginx_running=true
                    fi
                fi

                # 显示Nginx状态
                echo -e "${CYAN}Nginx状态:${NC}"
                if [ "$nginx_installed" = true ]; then
                    echo -e "  安装状态: ${GREEN}已安装${NC} (版本: $nginx_version)"
                    if [ "$nginx_running" = true ]; then
                        echo -e "  运行状态: ${GREEN}运行中${NC}"
                    else
                        echo -e "  运行状态: ${RED}已停止${NC}"
                    fi
                else
                    echo -e "  安装状态: ${RED}未安装${NC}"
                fi
                echo

                # 显示菜单选项
                if [ "$nginx_installed" = false ]; then
                    print_menu_option "1" "安装Nginx"
                else
                    if [ "$nginx_running" = true ]; then
                        print_menu_option "1" "停止Nginx"
                        print_menu_option "2" "重启Nginx"
                    else
                        print_menu_option "1" "启动Nginx"
                    fi
                    print_menu_option "3" "查看Nginx配置"
                    print_menu_option "4" "检查Nginx配置语法"
                    print_menu_option "5" "编辑Nginx配置"
                    print_menu_option "6" "查看Nginx状态"
                    print_menu_option "7" "查看访问日志"
                    print_menu_option "8" "查看错误日志"
                    print_menu_option "9" "管理站点配置"
                fi
                print_menu_option "q" "返回" $RED

                echo
                read -e -p "请输入选项: " nginx_choice

                case "$nginx_choice" in
                1)
                    if [ "$nginx_installed" = false ]; then
                        echo -e "${YELLOW}正在安装Nginx...${NC}"
                        # 安装Nginx
                        sudo apt-get update
                        sudo apt-get install -y nginx

                        # 检查安装结果
                        if command -v nginx &>/dev/null; then
                            echo -e "${GREEN}✓ Nginx安装成功${NC}"

                            # 配置防火墙（如果存在）
                            if command -v ufw &>/dev/null && sudo ufw status | grep -q "Status: active"; then
                                echo -e "${YELLOW}配置防火墙规则...${NC}"
                                sudo ufw allow 'Nginx HTTP'
                                echo -e "${GREEN}✓ 防火墙规则已添加${NC}"
                            fi

                            # 启动Nginx
                            sudo systemctl start nginx
                            sudo systemctl enable nginx

                            echo -e "${GREEN}✓ Nginx服务已启动并设为开机自启${NC}"
                            echo -e "${CYAN}可通过 http://$IP 访问${NC}"
                        else
                            echo -e "${RED}✗ Nginx安装失败${NC}"
                        fi
                    else
                        if [ "$nginx_running" = true ]; then
                            echo -e "${YELLOW}正在停止Nginx...${NC}"
                            sudo systemctl stop nginx
                            echo -e "${GREEN}✓ Nginx已停止${NC}"
                        else
                            echo -e "${YELLOW}正在启动Nginx...${NC}"
                            sudo systemctl start nginx
                            echo -e "${GREEN}✓ Nginx已启动${NC}"
                        fi
                    fi
                    ;;
                2)
                    if [ "$nginx_installed" = true ]; then
                        echo -e "${YELLOW}正在重启Nginx...${NC}"
                        sudo systemctl restart nginx
                        echo -e "${GREEN}✓ Nginx已重启${NC}"
                    fi
                    ;;
                3)
                    if [ "$nginx_installed" = true ]; then
                        echo -e "${YELLOW}Nginx主配置文件:${NC}"
                        cat /etc/nginx/nginx.conf
                        echo -e "\n${YELLOW}按任意键继续...${NC}"
                        read -n 1 -s -r -p ""
                    fi
                    ;;
                4)
                    if [ "$nginx_installed" = true ]; then
                        echo -e "${YELLOW}检查Nginx配置语法...${NC}"
                        sudo nginx -t
                        echo -e "\n${YELLOW}按任意键继续...${NC}"
                        read -n 1 -s -r -p ""
                    fi
                    ;;
                5)
                    if [ "$nginx_installed" = true ]; then
                        echo -e "${YELLOW}编辑Nginx配置文件...${NC}"
                        if command -v nano &>/dev/null; then
                            sudo nano /etc/nginx/nginx.conf
                        elif command -v vim &>/dev/null; then
                            sudo vim /etc/nginx/nginx.conf
                        else
                            echo -e "${RED}未找到编辑器，请安装nano或vim${NC}"
                        fi
                    fi
                    ;;
                6)
                    if [ "$nginx_installed" = true ]; then
                        echo -e "${YELLOW}Nginx状态:${NC}"
                        sudo systemctl status nginx
                        echo -e "\n${YELLOW}按任意键继续...${NC}"
                        read -n 1 -s -r -p ""
                    fi
                    ;;
                7)
                    if [ "$nginx_installed" = true ]; then
                        echo -e "${YELLOW}Nginx访问日志 (最新50行):${NC}"
                        sudo tail -n 50 /var/log/nginx/access.log
                        echo -e "\n${YELLOW}按任意键继续...${NC}"
                        read -n 1 -s -r -p ""
                    fi
                    ;;
                8)
                    if [ "$nginx_installed" = true ]; then
                        echo -e "${YELLOW}Nginx错误日志 (最新50行):${NC}"
                        sudo tail -n 50 /var/log/nginx/error.log
                        echo -e "\n${YELLOW}按任意键继续...${NC}"
                        read -n 1 -s -r -p ""
                    fi
                    ;;
                9)
                    if [ "$nginx_installed" = true ]; then
                        # 站点配置管理子菜单
                        while true; do
                            clear
                            print_menu_header "Nginx站点管理"

                            # 列出可用站点
                            echo -e "${CYAN}可用站点配置:${NC}"
                            sites_available=()
                            i=1
                            while read -r site_path; do
                                site_name=$(basename "$site_path")
                                sites_available+=("$site_name")

                                # 检查站点是否已启用
                                if [ -L "/etc/nginx/sites-enabled/$site_name" ]; then
                                    status="${GREEN}已启用${NC}"
                                else
                                    status="${RED}已禁用${NC}"
                                fi

                                echo -e "$i. ${CYAN}$site_name${NC} - $status"
                                ((i++))
                            done < <(find /etc/nginx/sites-available -type f -name "*" | sort)

                            echo
                            print_menu_option "a" "创建新站点配置"
                            print_menu_option "b" "启用/禁用站点"
                            print_menu_option "c" "删除站点配置"
                            print_menu_option "q" "返回" $RED

                            echo
                            read -e -p "请输入选项: " site_choice

                            case "$site_choice" in
                            a)
                                read -e -p "输入新站点名称 (例如: mysite): " site_name
                                if [ -n "$site_name" ]; then
                                    # 创建配置文件
                                    cat >"/tmp/${site_name}.conf" <<EOF
server {
    listen 80;
    server_name ${site_name}.local;
    
    root /var/www/html/${site_name};
    index index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    access_log /var/log/nginx/${site_name}_access.log;
    error_log /var/log/nginx/${site_name}_error.log;
}
EOF
                                    # 创建网站目录
                                    sudo mkdir -p /var/www/html/${site_name}
                                    # 创建示例index.html
                                    cat >"/tmp/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>${site_name}</title>
</head>
<body>
    <h1>欢迎访问 ${site_name}</h1>
    <p>此网站由Nginx提供服务</p>
</body>
</html>
EOF
                                    sudo mv "/tmp/index.html" "/var/www/html/${site_name}/index.html"
                                    sudo mv "/tmp/${site_name}.conf" "/etc/nginx/sites-available/${site_name}"

                                    # 提示是否启用站点
                                    read -e -p "是否立即启用该站点? (y/n): " enable_site
                                    if [[ "$enable_site" == "y" || "$enable_site" == "Y" ]]; then
                                        sudo ln -sf "/etc/nginx/sites-available/${site_name}" "/etc/nginx/sites-enabled/${site_name}"
                                        sudo nginx -t && sudo systemctl reload nginx
                                        echo -e "${GREEN}✓ 站点已创建并启用${NC}"
                                    else
                                        echo -e "${GREEN}✓ 站点已创建但未启用${NC}"
                                    fi
                                fi
                                ;;
                            b)
                                read -e -p "输入要启用/禁用的站点编号: " site_num
                                if [[ "$site_num" =~ ^[0-9]+$ ]] && [ "$site_num" -ge 1 ] && [ "$site_num" -le ${#sites_available[@]} ]; then
                                    site_name=${sites_available[$((site_num - 1))]}

                                    # 检查站点状态并切换
                                    if [ -L "/etc/nginx/sites-enabled/$site_name" ]; then
                                        # 禁用站点
                                        sudo rm "/etc/nginx/sites-enabled/$site_name"
                                        echo -e "${GREEN}✓ 站点 $site_name 已禁用${NC}"
                                    else
                                        # 启用站点
                                        sudo ln -sf "/etc/nginx/sites-available/$site_name" "/etc/nginx/sites-enabled/$site_name"
                                        echo -e "${GREEN}✓ 站点 $site_name 已启用${NC}"
                                    fi
                                    # 重载Nginx
                                    sudo nginx -t && sudo systemctl reload nginx
                                else
                                    echo -e "${RED}✗ 无效的站点编号${NC}"
                                fi
                                ;;
                            c)
                                read -e -p "输入要删除的站点编号: " site_num
                                if [[ "$site_num" =~ ^[0-9]+$ ]] && [ "$site_num" -ge 1 ] && [ "$site_num" -le ${#sites_available[@]} ]; then
                                    site_name=${sites_available[$((site_num - 1))]}

                                    read -e -p "确定要删除站点 $site_name? (y/n): " confirm
                                    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                                        # 如果站点已启用，先禁用它
                                        if [ -L "/etc/nginx/sites-enabled/$site_name" ]; then
                                            sudo rm "/etc/nginx/sites-enabled/$site_name"
                                        fi
                                        # 删除配置文件
                                        sudo rm "/etc/nginx/sites-available/$site_name"
                                        echo -e "${GREEN}✓ 站点 $site_name 已删除${NC}"
                                        # 提示是否删除网站文件
                                        read -e -p "是否删除网站文件 /var/www/html/$site_name? (y/n): " delete_files
                                        if [[ "$delete_files" == "y" || "$delete_files" == "Y" ]]; then
                                            sudo rm -rf "/var/www/html/$site_name"
                                            echo -e "${GREEN}✓ 网站文件已删除${NC}"
                                        fi
                                        # 重载Nginx
                                        sudo nginx -t && sudo systemctl reload nginx
                                    fi
                                else
                                    echo -e "${RED}✗ 无效的站点编号${NC}"
                                fi
                                ;;
                            q | Q)
                                break
                                ;;
                            *)
                                echo -e "${RED}✗ 无效的选择${NC}"
                                sleep 1
                                ;;
                            esac
                            echo -e "\n${YELLOW}按任意键继续...${NC}"
                            read -n 1 -s -r -p ""
                        done
                    fi
                    ;;
                q | Q)
                    return
                    ;;
                *)
                    echo -e "${RED}✗ 无效的选择${NC}"
                    sleep 1
                    ;;
                esac
            }

            case $choice in
            1)
                search_files
                echo
                echo -e "${BLUE}按任意键继续...${NC}"
                read -n 1 -s -r -p ""
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
                echo
                echo -e "${BLUE}按任意键继续...${NC}"
                read -n 1 -s -r -p ""
                ;;
            3)
                cleanup
                echo
                echo -e "${BLUE}按任意键继续...${NC}"
                read -n 1 -s -r -p ""
                ;;
            4)
                swap
                echo
                echo -e "${BLUE}按任意键继续...${NC}"
                read -n 1 -s -r -p ""
                ;;
            5)
                backdrop
                echo
                echo -e "${BLUE}按任意键继续...${NC}"
                read -n 1 -s -r -p ""
                ;;
            6)
                DNS
                echo
                echo -e "${BLUE}按任意键继续...${NC}"
                read -n 1 -s -r -p ""
                ;;
            7)
                nginx_manager
                ;;
            q | Q)
                break
                ;;
            *)
                echo -e "${RED}无效的选择，请重新输入${NC}"
                echo
                echo -e "${BLUE}按任意键继续...${NC}"
                read -n 1 -s -r -p ""
                ;;
            esac
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
        read -e -p "语言配置已完成，是否现在重启系统？ (y/n): " choice
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

            read -e -p "请输入选项: " choice

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
                read -e -p "当前路径为: $current_path，是否要更改？（y/n）" confirm_change
                if [ "$confirm_change" == "y" ]; then
                    read -e -p "请输入新的相对路径（相对于当前工作目录）： " new_relative_path
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
                read -e -p "当前路径为: $current_path，是否要更改？（y/n）" confirm_change
                if [ "$confirm_change" == "y" ]; then
                    read -e -p "请输入新的相对路径（相对于当前工作目录）： " new_relative_path
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
                # 使用环境变量时，如果 transmission 不是当前用户运行的，则需要将 TRANSMISSION_WEB_HOME 添加至 /etc/profile 文件，以达到"永久"的目的
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
        # 网络测速菜单
        while true; do
            clear
            print_menu_header "网络测速工具"

            print_menu_option "1" "Speedtest测速 (标准模式)"
            print_menu_option "2" "Speedtest测速 (简洁模式)"
            print_menu_option "3" "Ping测试"
            print_menu_option "4" "查看网络接口状态"
            print_menu_option "5" "安装/更新 Speedtest CLI"
            print_menu_option "q" "返回" $RED

            echo
            read -e -p "请输入选项: " speedtest_choice

            # 确保Speedtest CLI已安装
            function ensure_speedtest_installed() {
                if ! command -v speedtest &>/dev/null; then
                    echo -e "${YELLOW}Speedtest CLI未安装，正在安装...${NC}"

                    # 备份原始源列表
                    if [ -f /etc/apt/sources.list.d/speedtest.list ]; then
                        sudo cp /etc/apt/sources.list.d/speedtest.list /etc/apt/sources.list.d/speedtest.list.bak
                    fi

                    # 安装Speedtest CLI
                    if curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash; then
                        echo -e "${CYAN}软件源添加成功，正在安装...${NC}"
                        if sudo apt-get install -y speedtest; then
                            echo -e "${GREEN}✓ Speedtest CLI 安装成功!${NC}"
                            return 0
                        else
                            echo -e "${RED}✗ Speedtest CLI 安装失败${NC}"
                            return 1
                        fi
                    else
                        echo -e "${RED}✗ 添加软件源失败${NC}"
                        return 1
                    fi
                else
                    return 0 # 已安装
                fi
            }

            # 标准模式测速
            function run_standard_speedtest() {
                echo -e "${YELLOW}正在进行完整网络测速，请稍候...${NC}"
                echo -e "${CYAN}这将测试您的下载、上传速度和网络延迟${NC}\n"

                if ensure_speedtest_installed; then
                    # 执行测速并捕获输出
                    echo -e "${CYAN}测试开始 - $(date '+%Y-%m-%d %H:%M:%S')${NC}\n"

                    # 等待动画函数
                    speedtest_pid=""
                    function show_spinner() {
                        local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
                        local charwidth=3
                        local i=0
                        while kill -0 $speedtest_pid 2>/dev/null; do
                            i=$(((i + 1) % ${#spin}))
                            printf "${CYAN}%s${NC}" "${spin:$i:$charwidth}"
                            printf "\r"
                            sleep 0.2
                        done
                        printf "    \r" # 清除spinner
                    }

                    # 在后台运行speedtest，并在前台显示旋转动画
                    speedtest --accept-license --accept-gdpr >speedtest_result.txt 2>&1 &
                    speedtest_pid=$!
                    show_spinner

                    # 检查测试结果
                    if [ -f "speedtest_result.txt" ]; then
                        cat speedtest_result.txt
                        rm speedtest_result.txt
                        echo -e "\n${GREEN}✓ 测速完成!${NC}"
                    else
                        echo -e "${RED}✗ 测速失败${NC}"
                    fi
                fi
            }

            # 简洁模式测速
            function run_simple_speedtest() {
                echo -e "${YELLOW}正在进行简洁网络测速，请稍候...${NC}"

                if ensure_speedtest_installed; then
                    echo -e "${CYAN}测试开始 - $(date '+%Y-%m-%d %H:%M:%S')${NC}"

                    # 执行测速并实时显示进度
                    local result=$(speedtest --accept-license --accept-gdpr --format=json 2>/dev/null)

                    if [ $? -eq 0 ]; then
                        # 确保所需工具已安装
                        local tools_missing=false

                        # 检查jq
                        if ! command -v jq &>/dev/null; then
                            echo -e "${YELLOW}正在安装JSON解析工具(jq)...${NC}"
                            sudo apt install -y jq || tools_missing=true
                        fi

                        # 检查bc
                        if ! command -v bc &>/dev/null; then
                            echo -e "${YELLOW}正在安装计算工具(bc)...${NC}"
                            sudo apt install -y bc || tools_missing=true
                        fi

                        if [ "$tools_missing" = true ]; then
                            echo -e "${RED}✗ 部分工具安装失败，结果可能不完整${NC}"
                        fi

                        if command -v jq &>/dev/null; then
                            local ping=$(echo $result | jq -r '.ping.latency')
                            local download=$(echo $result | jq -r '.download.bandwidth')
                            local upload=$(echo $result | jq -r '.upload.bandwidth')
                            local isp=$(echo $result | jq -r '.isp')
                            local server=$(echo $result | jq -r '.server.name')
                            local server_loc=$(echo $result | jq -r '.server.location')

                            # 转换带宽单位 (bytes/s to Mbps)
                            if command -v bc &>/dev/null; then
                                download=$(echo "scale=2; $download * 8 / 1000000" | bc)
                                upload=$(echo "scale=2; $upload * 8 / 1000000" | bc)
                            else
                                # 如果bc不可用，使用awk作为替代方案
                                download=$(awk "BEGIN {printf \"%.2f\", $download * 8 / 1000000}")
                                upload=$(awk "BEGIN {printf \"%.2f\", $upload * 8 / 1000000}")
                            fi

                            echo -e "\n${GREEN}=== 测速结果 ===${NC}"
                            echo -e "${CYAN}ISP:${NC} $isp"
                            echo -e "${CYAN}服务器:${NC} $server ($server_loc)"
                            echo -e "${CYAN}Ping延迟:${NC} ${GREEN}${ping} ms${NC}"
                            echo -e "${CYAN}下载速度:${NC} ${GREEN}${download} Mbps${NC}"
                            echo -e "${CYAN}上传速度:${NC} ${GREEN}${upload} Mbps${NC}"
                        else
                            echo -e "${RED}✗ 无法安装jq解析工具${NC}"
                            echo "$result" # 直接显示JSON
                        fi

                        echo -e "\n${GREEN}✓ 测速完成!${NC}"
                    else
                        echo -e "${RED}✗ 测速失败${NC}"
                    fi
                fi
            }

            # Ping测试
            function run_ping_test() {
                clear
                echo -e "${YELLOW}Ping测试工具${NC}"
                echo -e "${CYAN}此工具将测试您的网络连接延迟${NC}\n"

                # 预设的目标服务器
                local targets=(
                    "www.baidu.com:百度"
                    "www.qq.com:腾讯"
                    "www.aliyun.com:阿里云"
                    "1.1.1.1:Cloudflare DNS"
                    "8.8.8.8:Google DNS"
                )

                echo -e "${GREEN}=== 预设目标 ===${NC}"
                for i in "${!targets[@]}"; do
                    local index=$((i + 1))
                    local target=(${targets[$i]/:/ })
                    echo -e "  ${BOLD}${YELLOW}[$index]${NC} ${target[1]} (${target[0]})"
                done
                echo -e "  ${BOLD}${YELLOW}[c]${NC} 自定义目标"
                echo -e "  ${BOLD}${RED}[q]${NC} 返回"

                echo
                read -e -p "请选择目标: " target_choice

                local host=""
                local name=""

                case "$target_choice" in
                [1-9])
                    local index=$((target_choice - 1))
                    if [ $index -lt ${#targets[@]} ]; then
                        local target=(${targets[$index]/:/ })
                        host=${target[0]}
                        name=${target[1]}
                    else
                        echo -e "${RED}无效的选择${NC}"
                        sleep 1
                        return
                    fi
                    ;;
                c | C)
                    read -e -p "请输入要Ping的主机名或IP: " custom_host
                    host=$custom_host
                    name="自定义目标"
                    ;;
                q | Q)
                    return
                    ;;
                *)
                    echo -e "${RED}无效的选择${NC}"
                    sleep 1
                    return
                    ;;
                esac

                if [ -n "$host" ]; then
                    echo -e "\n${YELLOW}正在Ping ${name} (${host})...${NC}"
                    ping -c 10 $host

                    echo -e "\n${GREEN}✓ Ping测试完成!${NC}"
                fi
            }

            # 显示网络接口状态
            function show_network_interfaces() {
                clear
                echo -e "${YELLOW}网络接口状态${NC}"
                echo -e "${CYAN}显示所有活动网络接口的详细信息${NC}\n"

                echo -e "${GREEN}=== 网络接口列表 ===${NC}"
                ip -br addr

                echo -e "\n${GREEN}=== 详细网络信息 ===${NC}"
                ifconfig

                echo -e "\n${GREEN}=== 路由表 ===${NC}"
                ip route

                echo -e "\n${GREEN}=== DNS配置 ===${NC}"
                if [ -f "/etc/resolv.conf" ]; then
                    cat /etc/resolv.conf
                else
                    echo -e "${RED}未找到DNS配置文件${NC}"
                fi
            }

            # 安装/更新Speedtest CLI
            function install_update_speedtest() {
                echo -e "${YELLOW}正在安装/更新 Speedtest CLI...${NC}"

                # 移除旧版本
                if command -v speedtest &>/dev/null; then
                    echo -e "${CYAN}移除旧版本...${NC}"
                    sudo apt-get remove -y speedtest
                fi

                # 重新安装
                ensure_speedtest_installed
            }

            # 处理用户选择
            case "$speedtest_choice" in
            1)
                run_standard_speedtest
                ;;
            2)
                run_simple_speedtest
                ;;
            3)
                run_ping_test
                ;;
            4)
                show_network_interfaces
                ;;
            5)
                install_update_speedtest
                ;;
            q | Q)
                break
                ;;
            *)
                echo -e "${RED}无效的选择${NC}"
                ;;
            esac

            echo
            echo -e "${BLUE}按任意键继续...${NC}"
            read -n 1 -s -r -p ""
        done
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
            read -e -p "请输入选项: " choice

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
                read -e -p "请输入容器名称: " container_name
                docker start $container_name

                if [ $? -eq 0 ]; then
                    echo "容器 $container_name 已成功启动."
                else
                    echo "启动容器 $container_name 失败."
                fi
            }

            function stop_container() {
                check_docker_installed || return 1
                read -e -p "请输入容器名称: " container_name
                docker stop $container_name

                if [ $? -eq 0 ]; then
                    echo "容器 $container_name 已成功停止."
                else
                    echo "停止容器 $container_name 失败."
                fi
            }

            function restart_container() {
                check_docker_installed || return 1
                read -e -p "请输入容器名称: " container_name
                docker restart $container_name

                if [ $? -eq 0 ]; then
                    echo "容器 $container_name 已成功重启."
                else
                    echo "重启容器 $container_name 失败."
                fi
            }

            function remove_container() {
                check_docker_installed || return 1
                read -e -p "请输入容器名称: " container_name
                docker rm $container_name

                if [ $? -eq 0 ]; then
                    echo "容器 $container_name 已成功删除."
                else
                    echo "删除容器 $container_name 失败."
                fi
            }

            function remove_image() {
                check_docker_installed || return 1
                read -e -p "请输入镜像名称: " image_name
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
                read -e -p "请输入选项: " choice
                case $choice in
                1)
                    # 确认信息
                    read -e -p "是否准备好安装所需文件？（y/n): " confirmation

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
            read -e -p "请输入选项: " menu_choice

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
                read -e -p "请输入选项: " device_choice

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

                read -e -p "切换系统完成，请重启设备 (y/n): " confirm_reboot
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

                read -e -p "请输入选项: " backup_type

                case "$backup_type" in
                1)
                    # 备份EMMC
                    echo -e "${GREEN}备份EMMC启动${NC}"
                    read -e -p "是否确认备份EMMC启动？ (y/n): " confirm_emmc_backup
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
                    read -e -p "是否确认备份TF启动？ (y/n): " confirm_tf_backup
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
                    read -e -p "是否确认备份USB启动？ (y/n): " confirm_usb_backup
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

                read -e -p "请输入选项: " restore_type

                case "$restore_type" in
                1)
                    # 恢复EMMC
                    echo -e "${GREEN}恢复EMMC启动${NC}"
                    read -e -p "是否确认恢复EMMC启动？ (y/n): " confirm_emmc_restore
                    if [ "$confirm_emmc_restore" = "y" ]; then
                        if [ -f "/mnt/sda1/hi3798mv100_bootargs_emmc_backup.img" ]; then
                            dd if=/mnt/sda1/hi3798mv100_bootargs_emmc_backup.img of=/dev/mmcblk0p2
                            read -e -p "EMMC启动恢复完成，是否重启设备 (y/n): " confirm_reboot
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
                    read -e -p "是否确认恢复TF启动？ (y/n): " confirm_tf_restore
                    if [ "$confirm_tf_restore" = "y" ]; then
                        if [ -f "/mnt/sda1/hi3798mv100_bootargs_tf_backup.img" ]; then
                            dd if=/mnt/sda1/hi3798mv100_bootargs_tf_backup.img of=/dev/mmcblk0p2
                            read -e -p "TF启动恢复完成，是否重启设备 (y/n): " confirm_reboot
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
                    read -e -p "是否确认恢复USB启动？ (y/n): " confirm_usb_restore
                    if [ "$confirm_usb_restore" = "y" ]; then
                        if [ -f "/mnt/sda1/hi3798mv100_bootargs_usb_backup.img" ]; then
                            dd if=/mnt/sda1/hi3798mv100_bootargs_usb_backup.img of=/dev/mmcblk0p2
                            read -e -p "USB启动恢复完成，是否重启设备 (y/n): " confirm_reboot
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
        # socks5服务功能
        while true; do
            clear
            print_menu_header "SOCKS5 服务功能"

            print_menu_option "1" "搭建v2ray客户端"
            print_menu_option "2" "测试是否联通"
            print_menu_option "3" "重启v2ray"
            print_menu_option "4" "开启代理本机"
            print_menu_option "5" "关闭代理本机"
            print_menu_option "6" "测试本机代理"
            print_menu_option "7" "卸载服务"
            print_menu_option "q" "返回" $RED

            echo
            read -e -p "请输入选项: " choice

            # v2ray 安装函数
            function socks5_install() {
                echo -e "${YELLOW}正在安装v2ray客户端 (版本v5.6.0)...${NC}"
                if command -v install-v2ray.sh &>/dev/null; then
                    install-v2ray.sh --version v5.6.0

                    if systemctl is-active --quiet v2ray; then
                        echo -e "\n${GREEN}✓ v2ray安装成功并已启动!${NC}"
                        echo -e "\n${CYAN}配置文件位置: /usr/local/etc/v2ray/config.json${NC}"
                        echo -e "${CYAN}配置文件修改后，运行以下命令使其生效:${NC}"
                        echo -e "  ${WHITE}systemctl daemon-reload${NC}"
                        echo -e "  ${WHITE}systemctl restart v2ray${NC}"
                    else
                        echo -e "\n${RED}✗ v2ray安装完成但服务未能启动${NC}"
                        echo -e "${YELLOW}请检查配置文件是否正确${NC}"
                    fi
                else
                    echo -e "${RED}✗ 安装脚本不存在，请确认系统环境${NC}"
                fi
            }

            # 连接测试函数
            function socks5_test() {
                echo -e "${YELLOW}正在测试SOCKS5连接 (127.0.0.1:10808)...${NC}"
                echo -e "${CYAN}尝试连接到google.com...${NC}\n"

                timeout 10 curl --silent --show-error --socks5 127.0.0.1:10808 -I https://www.google.com &>/dev/null

                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ 连接测试成功!${NC}"
                    echo -e "${GREEN}SOCKS5代理正常工作${NC}"
                else
                    echo -e "${RED}✗ 连接测试失败!${NC}"
                    echo -e "${YELLOW}可能的原因:${NC}"
                    echo -e "  - v2ray服务未运行 (检查: systemctl status v2ray)"
                    echo -e "  - 配置文件有误 (检查: /usr/local/etc/v2ray/config.json)"
                    echo -e "  - 代理上游连接失败 (检查配置中的服务器地址)"
                fi
            }

            # 重启v2ray函数
            function socks5_restart() {
                echo -e "${YELLOW}正在重启v2ray服务...${NC}"

                # 检查服务是否存在
                if ! systemctl list-unit-files | grep -q v2ray; then
                    echo -e "${RED}✗ v2ray服务不存在，请先安装${NC}"
                    return 1
                fi

                # 保存重启前状态
                local was_active=false
                if systemctl is-active --quiet v2ray; then
                    was_active=true
                fi

                # 执行重启
                sudo systemctl restart v2ray
                sleep 2 # 给服务一些启动时间

                # 检查重启后状态
                if systemctl is-active --quiet v2ray; then
                    echo -e "${GREEN}✓ v2ray服务重启成功${NC}"
                    systemctl status v2ray --no-pager | grep "Active:"
                    return 0
                else
                    echo -e "${RED}✗ 重启失败，服务未能正常启动${NC}"
                    echo -e "${YELLOW}正在检查可能的错误:${NC}"

                    # 配置文件检查
                    if [ -f "/usr/local/etc/v2ray/config.json" ]; then
                        if ! jq . "/usr/local/etc/v2ray/config.json" &>/dev/null; then
                            echo -e "${RED}✗ 配置文件JSON格式错误${NC}"
                        fi
                    else
                        echo -e "${RED}✗ 配置文件不存在${NC}"
                    fi

                    # 显示最近的日志
                    echo -e "\n${YELLOW}服务日志 (最近10行):${NC}"
                    sudo journalctl -u v2ray -n 10 --no-pager

                    # 如果本来是启动的，现在挂了，尝试恢复之前的状态
                    if [ "$was_active" = true ]; then
                        echo -e "\n${YELLOW}尝试恢复之前的运行状态...${NC}"
                        sudo systemctl start v2ray
                    fi

                    return 1
                fi
            }

            # 开启系统代理
            function socks5_enable_proxy() {
                echo -e "${YELLOW}正在设置系统代理...${NC}"

                # 立即设置当前会话的代理环境变量
                export https_proxy="127.0.0.1:10809"
                export http_proxy="127.0.0.1:10809"
                export all_proxy="socks5://127.0.0.1:10808"

                # 检查代理是否已永久设置
                if grep -q 'export https_proxy="127.0.0.1:10809"' ~/.bashrc; then
                    echo -e "${GREEN}✓ 代理已激活（当前会话和永久配置）${NC}"
                else
                    # 添加代理设置到.bashrc实现永久生效
                    echo 'export https_proxy="127.0.0.1:10809"' >>~/.bashrc
                    echo 'export http_proxy="127.0.0.1:10809"' >>~/.bashrc
                    echo 'export all_proxy="socks5://127.0.0.1:10808"' >>~/.bashrc

                    echo -e "${GREEN}✓ 代理已激活（当前会话）${NC}"
                    echo -e "${GREEN}✓ 已添加到永久配置（.bashrc）${NC}"
                fi

                # 显示当前活动的代理设置
                echo -e "\n${CYAN}当前代理设置:${NC}"
                echo -e "  https_proxy = ${https_proxy}"
                echo -e "  http_proxy = ${http_proxy}"
                echo -e "  all_proxy = ${all_proxy}"
            }

            # 关闭系统代理
            function socks5_disable_proxy() {
                echo -e "${YELLOW}正在关闭系统代理...${NC}"
                local changes_made=false

                # 1. 先清除当前会话的代理设置
                if [ -n "$https_proxy" ] || [ -n "$http_proxy" ] || [ -n "$all_proxy" ]; then
                    unset https_proxy
                    unset http_proxy
                    unset all_proxy
                    changes_made=true
                    echo -e "${GREEN}✓ 已清除当前会话的代理环境变量${NC}"
                fi

                # 2. 从.bashrc中移除永久配置
                if grep -q 'export.*_proxy=' ~/.bashrc; then
                    # 创建备份
                    cp ~/.bashrc ~/.bashrc.proxy.bak

                    # 移除所有代理设置
                    sed -i '/export.*_proxy=/d' ~/.bashrc
                    changes_made=true
                    echo -e "${GREEN}✓ 已从永久配置(.bashrc)中移除代理设置${NC}"
                    echo -e "${CYAN}   备份已保存到 ~/.bashrc.proxy.bak${NC}"
                fi

                if [ "$changes_made" = false ]; then
                    echo -e "${YELLOW}未发现任何代理设置，无需操作${NC}"
                else
                    # 验证当前状态
                    echo -e "\n${CYAN}当前代理状态:${NC}"
                    if [ -z "$https_proxy" ] && [ -z "$http_proxy" ] && [ -z "$all_proxy" ]; then
                        echo -e "${GREEN}✓ 已确认当前会话中无代理环境变量${NC}"
                    else
                        echo -e "${RED}✗ 警告: 一些代理变量仍然存在${NC}"
                    fi
                fi
            }

            # 测试系统代理
            function socks5_test_system_proxy() {
                echo -e "${YELLOW}正在测试系统代理...${NC}"
                local proxy_status="未设置"
                local connection_status="未知"
                local curl_output=""
                local temp_file="/tmp/proxy_test_$$.tmp"

                # 1. 先检查代理环境变量是否在当前会话中存在
                if [ -n "$https_proxy" ] || [ -n "$http_proxy" ] || [ -n "$all_proxy" ]; then
                    echo -e "${CYAN}当前会话检测到以下代理环境变量:${NC}"
                    [ -n "$https_proxy" ] && echo -e "  https_proxy = ${https_proxy}"
                    [ -n "$http_proxy" ] && echo -e "  http_proxy = ${http_proxy}"
                    [ -n "$all_proxy" ] && echo -e "  all_proxy = ${all_proxy}"
                    proxy_status="已设置"
                else
                    echo -e "${YELLOW}当前会话未检测到代理环境变量${NC}"

                    # 检查.bashrc中是否有配置但未加载
                    if grep -q 'export.*_proxy=' ~/.bashrc; then
                        echo -e "${YELLOW}提示: 在.bashrc中发现代理设置，但在当前会话中未激活${NC}"
                        echo -e "${YELLOW}运行 'source ~/.bashrc' 或选择选项4重新激活代理${NC}"
                    fi
                fi

                # 2. 检查v2ray服务状态
                echo -e "\n${CYAN}检查v2ray服务状态:${NC}"
                if systemctl is-active --quiet v2ray 2>/dev/null; then
                    echo -e "  v2ray服务: ${GREEN}运行中${NC}"
                else
                    echo -e "  v2ray服务: ${RED}未运行${NC}"
                    echo -e "${YELLOW}提示: 即使设置了环境变量，没有运行的v2ray服务也无法提供代理功能${NC}"
                    echo -e "${YELLOW}请使用选项3重启v2ray服务${NC}"
                fi

                # 3. 实际连接测试
                echo -e "\n${CYAN}正在测试连接到google.com...${NC}"
                echo -e "(测试过程可能需要几秒钟...)"

                # 使用curl测试连接，将输出存入临时文件
                timeout 15 curl --silent --show-error -I https://www.google.com >"$temp_file" 2>&1
                local curl_result=$?

                if [ $curl_result -eq 0 ]; then
                    # 连接成功
                    local status_code=$(grep -E "^HTTP" "$temp_file" | awk '{print $2}')
                    echo -e "${GREEN}✓ 连接测试成功! (HTTP状态码: $status_code)${NC}"
                    connection_status="成功"

                    # 检查抓取到的内容是否是谷歌页面
                    if grep -q "Server: gws" "$temp_file"; then
                        echo -e "${GREEN}✓ 确认连接到谷歌服务器${NC}"
                    else
                        echo -e "${YELLOW}⚠ 已连接，但可能不是谷歌的服务器${NC}"
                    fi
                else
                    # 连接失败
                    echo -e "${RED}✗ 连接测试失败!${NC}"
                    connection_status="失败"

                    # 错误诊断
                    echo -e "${YELLOW}详细诊断:${NC}"

                    # 检查超时问题
                    if [ $curl_result -eq 124 ]; then
                        echo -e "  - ${RED}连接超时${NC} - 代理可能速度太慢或无法到达目标"
                    fi

                    # 测试DNS解析
                    echo -e "  - 检查DNS解析: "
                    if host www.google.com &>/dev/null; then
                        echo -e "    ${GREEN}DNS正常${NC} - 可以解析域名"
                    else
                        echo -e "    ${RED}DNS问题${NC} - 无法解析域名"
                    fi

                    # 检查是否安装了host命令
                    if ! command -v host &>/dev/null; then
                        echo -e "  - 安装DNS工具以进行更好的诊断..."
                        sudo apt-get install -y dnsutils &>/dev/null
                    fi

                    # 检查本地连接
                    echo -e "  - 检查本地代理: "
                    if curl --silent --connect-timeout 5 --socks5 127.0.0.1:10808 -I http://localhost &>/dev/null; then
                        echo -e "    ${GREEN}本地代理服务正常${NC}"
                    else
                        echo -e "    ${RED}本地代理服务问题${NC} - 无法连接到127.0.0.1:10808"
                    fi
                fi

                # 清理临时文件
                rm -f "$temp_file"

                # 总结
                echo -e "\n${CYAN}=== 测试总结 ===${NC}"
                echo -e "代理环境变量: ${proxy_status}"
                echo -e "v2ray服务: $(systemctl is-active --quiet v2ray 2>/dev/null && echo "运行中" || echo "未运行")"
                echo -e "连接测试: ${connection_status}"

                if [ "$connection_status" = "失败" ]; then
                    echo -e "\n${YELLOW}建议解决步骤:${NC}"
                    echo -e "1. 使用选项4重新激活代理环境变量"
                    echo -e "2. 使用选项3重启v2ray服务"
                    echo -e "3. 检查v2ray配置文件 (/usr/local/etc/v2ray/config.json)"
                fi
            }

            # 卸载服务
            function socks5_uninstall() {
                echo -e "${YELLOW}即将卸载v2ray服务...${NC}"
                echo -e "${RED}此操作将删除v2ray服务及其配置文件${NC}"
                read -e -p "是否继续? (y/n): " confirm

                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    echo -e "${YELLOW}正在卸载v2ray...${NC}"

                    # 检查卸载脚本是否存在
                    if command -v install-v2ray.sh &>/dev/null; then
                        install-v2ray.sh --remove

                        # 删除配置文件
                        if [ -f "/usr/local/etc/v2ray/config.json" ]; then
                            rm -f /usr/local/etc/v2ray/config.json
                            echo -e "${CYAN}已删除配置文件${NC}"
                        fi

                        # 检查是否有遗留服务
                        if systemctl list-unit-files | grep -q v2ray; then
                            echo -e "${YELLOW}检测到服务文件残留，尝试清理...${NC}"
                            sudo systemctl disable v2ray
                            sudo rm -f /etc/systemd/system/v2ray.service
                            sudo systemctl daemon-reload
                        fi

                        echo -e "${GREEN}✓ v2ray已成功卸载${NC}"
                    else
                        echo -e "${RED}✗ 卸载脚本不存在${NC}"
                        echo -e "${YELLOW}尝试手动删除...${NC}"

                        # 停止并禁用服务
                        if systemctl list-unit-files | grep -q v2ray; then
                            sudo systemctl stop v2ray
                            sudo systemctl disable v2ray
                            sudo rm -f /etc/systemd/system/v2ray.service
                            sudo systemctl daemon-reload
                        fi

                        # 删除二进制文件
                        sudo rm -rf /usr/local/bin/v2ray
                        sudo rm -rf /usr/local/etc/v2ray
                        sudo rm -rf /usr/local/share/v2ray

                        echo -e "${GREEN}✓ v2ray已手动清理${NC}"
                    fi

                    # 清理代理设置
                    socks5_disable_proxy
                else
                    echo -e "${YELLOW}卸载已取消${NC}"
                fi
            }

            # 处理用户选择
            case "$choice" in
            1)
                socks5_install
                ;;
            2)
                socks5_test
                ;;
            3)
                socks5_restart
                ;;
            4)
                socks5_enable_proxy
                ;;
            5)
                socks5_disable_proxy
                ;;
            6)
                socks5_test_system_proxy
                ;;
            7)
                socks5_uninstall
                ;;
            q | Q)
                break
                ;;
            *)
                echo -e "${RED}无效选项，请重试${NC}"
                ;;
            esac

            echo
            echo -e "${BLUE}按回车继续...${NC}"
            read -e -p "" dummy
        done
        ;;

    a | A | update)
        echo -e "${YELLOW}正在更新系统...${NC}"

        # 优化系统更新逻辑
        echo -e "${CYAN}1. 更新软件源...${NC}"
        sudo apt-get update

        # 检查可用更新数量
        updates_available=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
        echo -e "${CYAN}发现 ${YELLOW}$updates_available${CYAN} 个可用更新${NC}"

        if [ $updates_available -gt 0 ]; then
            echo -e "${CYAN}2. 安装更新...${NC}"
            sudo apt-get upgrade -y

            # 检查是否有发行版更新
            dist_upgrade_needed=$(apt-get --simulate dist-upgrade | grep -c "^Inst")
            if [ $dist_upgrade_needed -gt 0 ]; then
                echo -e "${YELLOW}发现系统级更新，是否安装？(y/n)${NC}"
                read -e -p "(y/n): " upgrade_response
                if [[ "$upgrade_response" == "y" || "$upgrade_response" == "Y" ]]; then
                    echo -e "${CYAN}3. 安装系统级更新...${NC}"
                    sudo apt-get dist-upgrade -y
                fi
            fi

            echo -e "${CYAN}4. 清理不再需要的依赖...${NC}"
            sudo apt-get autoremove -y

            echo -e "${GREEN}✓ 系统更新完成！${NC}"
        else
            echo -e "${GREEN}✓ 系统已是最新！${NC}"
        fi
        ;;

    c | C | caidanu)
        echo -e "${YELLOW}正在更新脚本...${NC}"

        # 创建备份
        backup_path="/etc/caidan/caidan.sh.backup-$(date +%Y%m%d%H%M%S)"
        if [ -f "/etc/caidan/caidan.sh" ]; then
            cp /etc/caidan/caidan.sh "$backup_path"
            echo -e "${CYAN}已创建备份: $backup_path${NC}"
        fi

        # 检查网络连接
        echo -e "${CYAN}检查网络连接...${NC}"
        # 尝试使用不同的方式检查网络
        if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
            echo -e "${GREEN}网络连接正常${NC}"
        else
            echo -e "${RED}✗ 无法连接到互联网，请检查网络连接${NC}"
            read -e -p "是否继续尝试更新？(y/n): " continue_update
            if [[ "$continue_update" != "y" && "$continue_update" != "Y" ]]; then
                echo -e "${YELLOW}更新已取消${NC}"
                exit 0
            fi
        fi
        
        # 设置下载URL
        GITHUB_URL="https://raw.githubusercontent.com/LeoJyenn/hinas/main/caidan.sh"
        
        # 更新脚本
        echo -e "${CYAN}从GitHub下载最新版本...${NC}"
        if curl -s --connect-timeout 10 -m 30 -o /etc/caidan/caidan.sh.new $GITHUB_URL; then
            # 检查文件完整性
            if [ -f "/etc/caidan/caidan.sh.new" ] && [ -s "/etc/caidan/caidan.sh.new" ]; then
                chmod +x /etc/caidan/caidan.sh.new
                # 修复可能的换行符问题
                sed -i 's/\r$//' /etc/caidan/caidan.sh.new 2>/dev/null
                mv /etc/caidan/caidan.sh.new /etc/caidan/caidan.sh
                ln -sf /etc/caidan/caidan.sh /usr/bin/caidan
                echo -e "${GREEN}✓ 脚本更新成功，重新执行 [caidan] 生效${NC}"
            else
                echo -e "${RED}✗ 下载的文件不完整${NC}"
                if [ -f "$backup_path" ]; then
                    echo -e "${YELLOW}正在恢复备份...${NC}"
                    cp "$backup_path" /etc/caidan/caidan.sh
                fi
            fi
        else
            echo -e "${RED}✗ 更新失败，网络错误或GitHub不可访问${NC}"
            echo -e "${YELLOW}恢复原始文件...${NC}"
            if [ -f "$backup_path" ]; then
                cp "$backup_path" /etc/caidan/caidan.sh
                echo -e "${GREEN}已恢复原始文件${NC}"
            fi
        fi
        exit 0
        ;;

    e | E | caidanun)
        unInstall-caidan
        ;;

    b | B | 0)
        # 系统还原
        echo -e "${RED}警告:此操作将还原系统,请做好资料备份，是否要继续？(y/n)${NC}"
        read -e -p "(y/n): " response

        if [ "$response" = "y" ]; then
            recoverbackup
        elif [ "$response" = "n" ]; then
            echo -e "${RED}取消操作${NC}"
        else
            echo -e "${RED}无效的选择${NC}"
        fi
        echo
        echo -e "${BLUE}按任意键继续...${NC}"
        read -n 1 -s -r -p ""
        ;;

    d | D | pw | PW)
        # 修改 root 密码
        echo -e "${YELLOW}正在修改root密码...${NC}"
        sudo passwd root
        echo
        echo -e "${BLUE}按任意键继续...${NC}"
        read -n 1 -s -r -p ""
        ;;

    f | F | r | R)
        # 重启系统
        echo -e "${YELLOW}系统即将重启...${NC}"
        echo -e "${CYAN}将在5秒后重启，按Ctrl+C取消...${NC}"
        sleep 5
        sudo reboot
        ;;

    q | Q)
        # 退出
        echo -e "${RED}已退出...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}无效的选择${NC}"
        echo
        echo -e "${BLUE}按任意键继续...${NC}"
        read -n 1 -s -r -p ""
        ;;
    esac
done

# 调用main函数，确保脚本被直接执行时显示菜单
main