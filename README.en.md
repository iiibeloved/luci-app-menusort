# luci-app-menusort · LuCI Menu Sorter

> One-click reordering of the LuCI **Services** menu: **English names first (A-Z)**, then **Chinese names by pinyin**. Supports forward/reverse and auto-reloads the page. Works on **OpenWrt / ImmortalWrt / iStoreOS**.

[![build-ipk](https://github.com/iiibeloved/luci-app-menusort/actions/workflows/build.yml/badge.svg)](https://github.com/iiibeloved/luci-app-menusort/actions/workflows/build.yml)

简体中文说明见 [README.md](README.md)。

---

## What it does

After installing many apps, the LuCI "Services" menu order is controlled by whatever `order` each package ships with — English and Chinese apps end up mixed together. Editing `menu.d/*.json` and `controller/*.lua` by hand is error-prone and gets reset on every upgrade.

This app provides:

- **One-click sorting** under `System → Menu Sort`;
- **Forward / reverse** modes;
- Automatic **hard page reload** after sorting;
- Covers both menu sources: JSON (`menu.d/*.json`) and Lua controllers (`controller/*.lua`, e.g. PassWall / OpenClash);
- Only top-level app nodes are touched — sub-menus stay untouched.

## Dynamic discovery (no hard-coded app list)

The app ships **no application list**. On every run it scans:

| Source | Description |
| --- | --- |
| `/usr/share/luci/menu.d/*.json` | All JS menu entries registered as `admin/services/<app>` |
| `/usr/lib/lua/luci/controller/*.lua` | All Lua `entry({"admin","services","<app>"}, …)` entries |

So a newly installed app is picked up automatically — just click sort again. Nothing to edit, no update needed.

```sh
menusort --list      # show what was discovered (no changes)
```

## Sorting rules

1. **English apps first**, alphabetical (case-insensitive);
2. **Chinese apps after**, sorted by **pinyin** (built-in table of 20k+ characters, so full pinyin ordering, not just the initial letter);
3. New `order` values start at `10` and step by `10`, leaving room for manual insertion.

Example (forward):

```
DDNS-Go → Docker Manager → FastNet → Home Assistant → Homebox → HomeProxy →
KaiPlus → KSpeeder → Lucky → Navidrome → OpenClash → PassWall → UPnP
→ 百度网盘 → 带宽监控 → 动态 DNS → 浮动网关 → 缓存回收 → 健康检测 →
局域网设备唤醒 → 局域网设备扫描 → 网络共享 → 网络唤醒 → 应用过滤 → 易有云完整版
```

## Install

```sh
# download the ipk from Releases, then
opkg install luci-app-menusort_1.0.5-1_all.ipk
# if dependency check complains:
opkg install --force-depends luci-app-menusort_1.0.5-1_all.ipk
```

Architecture is `all` — installable on **any** platform (x86_64 / arm64 / mips …).

Build into firmware from source:

```sh
git clone https://github.com/iiibeloved/luci-app-menusort package/luci-app-menusort
make menuconfig     # LuCI → Applications → luci-app-menusort
make -j$(nproc)
```

## Usage

LuCI: **System → Menu Sort**

| Button | Action |
| --- | --- |
| Forward (English A-Z → pinyin) | `menusort forward` |
| Reverse (Chinese desc → English desc) | `menusort reverse` |
| View log | show `/tmp/menusort.log` |

CLI:

```sh
menusort              # forward
menusort reverse      # reverse
menusort --list       # list discovered apps
menusort --dry-run    # print only, do not modify
menusort --version
```

## Aliases (map English msgids to Chinese labels)

Some apps use English msgids that are displayed in Chinese (e.g. `App Filter` → 应用过滤).
Put mappings in **`/etc/menusort.aliases`**:

```
appfilter=应用过滤
floatip=浮动网关
ksmbd=网络共享
```

This file is **optional**; it only affects grouping/sorting for those apps.

## How it works

| Source | Handling |
| --- | --- |
| `/usr/share/luci/menu.d/*.json` | read `admin/services/<app>` title, rewrite its `"order"` |
| `/usr/lib/lua/luci/controller/*.lua` | parse `entry({"admin","services","<app>"}, …, N)`, rewrite `N` |

Package upgrades may reset `order` — just click sort again.

## Build ipk without the SDK

```sh
VERSION=1.0.5 RELEASE=1 sh scripts/build-ipk.sh
# output: dist/luci-app-menusort_1.0.5-1_all.ipk (+ sha256)
```

Pushing a `v*` tag builds and publishes automatically via GitHub Actions.

## Architecture independence

**Works on any architecture** — ARM, x86_64, MIPS, whatever runs OpenWrt / ImmortalWrt / iStoreOS:

| Aspect | Detail |
| --- | --- |
| Package arch | `Architecture: all` — no compiled artifacts |
| Files inside | Plain text only: POSIX sh script, JSON menu, JS view, pinyin TSV |
| Runtime deps | `luci-base` only; every command comes from **busybox** (`awk sed grep sort tr date printf cat ls xargs head basename cut wc du rm mv`) |
| Hardware-specific | None (no GPIO / kernel modules / CPU instructions) |
| Menu layout | Identical on OpenWrt 21.02+ / ImmortalWrt / iStoreOS (`menu.d/*.json` + `controller/*.lua`) |

Verified on aarch64 (RK3568, ImmortalWrt 24.10); x86_64 and other ARM targets use the same script and menu layout.

**Only requirement**: JS-based LuCI (21.02+). Legacy Lua-only LuCI (≤19.07) has no `menu.d` JSON and is unsupported.

## Compatibility

| System | Status |
| --- | --- |
| OpenWrt 23.05 / 24.10 | ✅ |
| ImmortalWrt 24.10 | ✅ (developed and verified on it) |
| iStoreOS | ✅ |
| Legacy Lua-only LuCI (<21.02) | ❌ (no `menu.d` JSON) |

## Credits

- [LuCI](https://github.com/openwrt/luci) for the menu architecture and `fs.exec`
- [mozillazg/pinyin-data](https://github.com/mozillazg/pinyin-data) for the pinyin data (MIT)

## License

Apache-2.0
