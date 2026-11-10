# luci-app-menusort · LuCI 菜单排序

> 一键把 LuCI「服务」菜单按 **英文名 A-Z → 中文名拼音** 排序，支持**正向 / 反向**，
> 执行后页面自动强制刷新。适用于 **OpenWrt / ImmortalWrt / iStoreOS** 等使用 LuCI 的固件。
>
> 🌐 **English**: [README.en.md](README.en.md)

[![build-ipk](https://github.com/iiibeloved/luci-app-menusort/actions/workflows/build.yml/badge.svg)](https://github.com/iiibeloved/luci-app-menusort/actions/workflows/build.yml)

---

## 一、解决什么问题

iStoreOS / ImmortalWrt 装了一堆应用后，「服务」菜单顺序完全由各包自带的 `order` 决定，
英文名、中文名混在一起，非常乱。手动改 `menu.d/*.json` 和 `controller/*.lua` 又容易出错、升级后还会被重置。

本应用提供：

- **一键排序**：`系统 → 菜单排序`，点一下即可；
- **正向 / 反向**两种模式；
- 排序完成后**自动强制刷新**当前页面；
- 覆盖两类来源：JSON 菜单（`menu.d/*.json`）和 Lua 控制器（`controller/*.lua`，如 PassWall / OpenClash）；
- 只动**顶层应用节点**，子菜单（如 `homeproxy/client`）不受影响。

## 二、动态扫描（不写死应用列表）

> 本应用**不内置任何应用清单**。每次点击「菜单排序」时，脚本会实时扫描：

| 扫描来源 | 说明 |
| --- | --- |
| `/usr/share/luci/menu.d/*.json` | 所有以 `admin/services/<app>` 注册的 JS 菜单项（含 title / order） |
| `/usr/lib/lua/luci/controller/*.lua` | 所有 `entry({"admin","services","<app>"}, …)` 的 Lua 菜单项（PassWall / OpenClash 等） |

因此：**新装应用 → 点一次排序就自动纳入**，卸载应用后也会自动消失；不需要改脚本、不需要等更新。

查看当前扫描到了什么（不改文件）：

```sh
menusort --list
```

示例输出：

```
== 扫描到的服务菜单应用（运行时）==
  ddns-go          DDNS-Go              luci-app-ddns-go.json
  openclash        OpenClash            openclash.lua
  passwall         Pass Wall            passwall.lua
  ...
```

> 测试方法：随便新建一个 `/usr/share/luci/menu.d/luci-app-zzz.json`，
> 再执行 `menusort --dry-run`，能看到它被自动排进列表里 —— 说明没有写死。

## 三、排序规则

1. **英文名应用**在前，按英文名字母序（忽略大小写）；
2. **中文名应用**在后，按**拼音**排序（内置 2 万+ 汉字拼音表，可做到「同首字母再按全拼」）；
3. 新的序号从 `10` 开始、步长 `10`，保证以后手工插入也有余量。

示例（正向后）：

```
DDNS-Go → Docker Manager → FastNet → Home Assistant → Homebox → HomeProxy →
KaiPlus → KSpeeder → Lucky → Navidrome → OpenClash → PassWall → UPnP
→ 百度网盘 → 带宽监控 → 动态 DNS → 浮动网关 → 缓存回收 → 健康检测 →
局域网设备唤醒 → 局域网设备扫描 → 网络共享 → 网络唤醒 → 应用过滤 → 易有云完整版
```

## 四、安装

### 方式 1：直接装 ipk（推荐）

到 [Releases](https://github.com/iiibeloved/luci-app-menusort/releases) 下载 `luci-app-menusort_*_all.ipk`，然后：

```sh
opkg install /tmp/luci-app-menusort_1.0.0-1_all.ipk
# 若依赖检查报错：
opkg install --force-depends /tmp/luci-app-menusort_1.0.0-1_all.ipk
```

Architecture = `all`，**任何架构**（x86_64 / arm64 / mips…）都能装。

### 方式 2：源码编译进固件

```sh
# 放到 OpenWrt/ImmortalWrt 源码的 package/ 下
git clone https://github.com/iiibeloved/luci-app-menusort package/luci-app-menusort
make menuconfig     # LuCI → Applications → luci-app-menusort
make -j$(nproc)
```

## 五、使用

### LuCI 界面

**系统 → 菜单排序**

| 按钮 | 说明 |
| --- | --- |
| 正向排序（英文 A-Z → 中文拼音） | `menusort forward` |
| 反向排序（中文倒序 → 英文倒序） | `menusort reverse` |
| 查看日志 | 显示 `/tmp/menusort.log` |

点击后页面会自动刷新（等价 Ctrl+F5）。

### 命令行

```sh
menusort              # 正向
menusort reverse      # 反向
menusort --dry-run    # 只打印结果，不修改文件
menusort --list       # 列出运行时扫描到的服务菜单应用
menusort --version    # 版本
```

## 六、别名（把英文标题归到中文分组）

不少应用的菜单标题是英文 msgid（例如 `App Filter` 实际显示为「应用过滤」）。
本应用提供别名文件 **`/etc/menusort.aliases`**，格式：

```
app=界面显示名
```

内置了一批常见 iStore/iStoreOS 应用：

```
appfilter=应用过滤
floatip=浮动网关
ksmbd=网络共享
ddns=动态 DNS
nlbw=带宽监控
wol=网络唤醒
linkeasefull=易有云完整版
baidudrive=百度网盘
```

自己装的特殊应用可以按同样格式追加一行，然后用 `menusort --dry-run` 检查效果。

## 七、原理

| 来源 | 处理方式 |
| --- | --- |
| `/usr/share/luci/menu.d/*.json` | 读取 `admin/services/<app>` 的 `title`，重写其 `"order"` |
| `/usr/lib/lua/luci/controller/*.lua` | 解析 `entry({"admin","services","<app>"}, …, N)`，改写末尾的 `N` |
| 初始化脚本 | 不注册（避免每次开机都改）；需要自动执行可自行加到 `/etc/rc.local` |

> 应用升级/重装会覆盖 `order`，届时重新点一次「正向排序」即可。

## 八、目录结构

```
.
├── Makefile                       # OpenWrt/LuCI 包描述
├── htdocs/luci-static/resources/view/menusort/menusort.js   # LuCI 页面
├── root/usr/bin/menusort          # 排序脚本（POSIX sh）
├── root/usr/share/menusort/pinyin.tsv                       # 拼音表（2 万+ 字）
├── root/usr/share/luci/menu.d/luci-app-menusort.json        # 菜单位置
├── root/usr/share/rpcd/acl.d/luci-app-menusort.json         # ACL（fs.exec）
├── root/etc/menusort.aliases      # 别名（可编辑）
└── scripts/build-ipk.sh           # 不依赖 SDK 打包 ipk
```

## 九、构建 ipk

无需 OpenWrt SDK：

```sh
VERSION=1.0.0 RELEASE=1 sh scripts/build-ipk.sh
# 产物：dist/luci-app-menusort_1.0.0-1_all.ipk（含 sha256）
```

打 tag 会自动构建并发布到 Release：

```sh
git tag v1.0.0 && git push origin v1.0.0
```

## 十、架构与系统兼容性

**结论：ARM / x86 / MIPS 等任何架构的 OpenWrt、ImmortalWrt、iStoreOS 都能用。**

原因：

| 维度 | 情况 |
| --- | --- |
| ipk 架构 | `Architecture: all`（不含任何编译产物） |
| 包内文件 | 全部是**纯文本**：POSIX sh 脚本、JSON 菜单、JS 页面、拼音表（TSV） |
| 运行时依赖 | 仅 `luci-base`；命令全部来自 **busybox**：`awk sed grep sort tr date printf cat ls xargs head basename cut wc du rm mv` |
| 与硬件相关的东西 | 无（不涉及 GPIO / 内核模块 / CPU 指令集） |
| 菜单结构 | OpenWrt 21.02+ / ImmortalWrt / iStoreOS 均为 `menu.d/*.json` + `controller/*.lua`，一致 |

已验证环境：

| 平台 | 架构 | 系统 | 结果 |
| --- | --- | --- | --- |
| NSY G68-PLUS（RK3568） | aarch64 | ImmortalWrt 24.10 | ✅ 正向/反向/动态扫描均通过 |
| 其他 ARM 软路由 | aarch64/armv7 | OpenWrt 23.05+ | ✅ 同一套脚本与菜单结构 |
| x86_64 软路由 | x86_64 | OpenWrt / ImmortalWrt | ✅ 同上（脚本不依赖架构） |

**唯一限制**：需要 **JS 版 LuCI**（21.02 及以后）。更老的纯 Lua LuCI（≤19.07）没有 `menu.d` JSON 结构，不支持。

> 不装 LuCI 也能用 CLI：`menusort forward|reverse|--list`，只要存在 `/usr/share/luci/menu.d` 或 `/usr/lib/lua/luci/controller`。

## 十一、兼容性

| 系统 | 说明 |
| --- | --- |
| OpenWrt 23.05 / 24.10 | ✅ 已按 24.10 的 LuCI(JS) 结构开发，23.05 兼容 |
| ImmortalWrt 24.10 | ✅ 本应用即在该固件上开发验证 |
| iStoreOS | ✅ 同 LuCI 结构 |
| 老版 Lua LuCI（<21.02） | ❌ 不支持（无 `menu.d` JSON 结构） |

## 十二、镜像与加速

- **下载慢**：在链接前加代理前缀即可（内容与 sha256 不变）：
  `https://gh-proxy.com/` · `https://ghfast.top/` · `https://ghproxy.net/`
- **Gitee 镜像**：仓库内置可选工作流 `.github/workflows/mirror-gitee.yml`，
  在 Settings → Secrets 里配置 `GITEE_USERNAME` + `GITEE_TOKEN`（可选 Variable `GITEE_REPO`），
  之后每次 push / 打 tag 会自动镜像到 `gitee.com/<用户名>/<仓库>`；未配置时该工作流自动跳过。

## 十三、致谢

- [LuCI](https://github.com/openwrt/luci) 项目结构与 `fs.exec` 机制
- [mozillazg/pinyin-data](https://github.com/mozillazg/pinyin-data) 汉字拼音数据（MIT）

## 许可证

Apache-2.0
