# 海纳思系统管理脚本 (HiNAS Management Tool)

海纳思系统管理脚本是一个功能丰富的Bash脚本，专为海纳思系统设计，提供了丰富的系统管理和配置功能。

## 最近更新

### 2023年新增功能

1. **USB共享文件夹功能**
   - 添加了USB外部设备共享功能
   - 支持创建和删除Samba共享
   - 自动配置共享权限和访问设置
   - 通过Windows网络可直接访问共享文件夹

2. **Nginx站点管理增强**
   - 改进了站点配置列表的显示效果
   - 添加了删除站点配置功能
   - 优化了站点启用/禁用功能的用户体验

## 主要功能

- 常用功能（文件搜索、网络服务重启、系统清理等）
- 中文语言包安装
- 系统检查和状态监控
- Aria2、BT下载工具配置
- 网络测速工具
- 格式化U盘、TF卡
- Docker容器管理
- Cockpit管理界面
- 系统迁移工具
- Tailscale配置
- Socks5服务功能

## 安装方法

### 一键安装

```bash
# 使用curl一键下载并安装
curl -fsSL https://raw.githubusercontent.com/LeoJyenn/hinas/main/caidan.sh | bash -s caidan
```

安装完成后，可以在任何目录使用以下命令打开工具菜单：

```bash
caidan
```

## 固件下载

- [海纳思固件官方下载](https://www.histb.com/download/)

## 开发者

- LeoJyenn (https://github.com/LeoJyenn)

## 贡献

欢迎提交Issues和Pull Requests来改进脚本。

## 许可证

根据MIT许可证开源。有关详细信息，请参阅[LICENSE](LICENSE)文件。 