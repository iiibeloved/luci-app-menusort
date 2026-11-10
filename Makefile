#
# Copyright (C) 2026 luci-app-menusort
#
# This is free software, licensed under the Apache License, Version 2.0
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-menusort
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=iiibeloved

LUCI_TITLE:=LuCI 菜单排序（服务菜单一键排序）
LUCI_DESCRIPTION:=按「英文名 A-Z → 中文名拼音」对 LuCI 服务菜单一键排序，支持正向/反向，执行后自动刷新。
LUCI_DEPENDS:=+luci-base
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
