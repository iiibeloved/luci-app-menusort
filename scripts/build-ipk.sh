#!/bin/sh
# 不依赖 OpenWrt SDK，直接产出 arch=all 的 ipk（OpenWrt 兼容 ar 格式）
set -eu
VER="${VERSION:-1.0.0}"
REL="${RELEASE:-1}"
OUT="${OUTDIR:-dist}"
PKG=luci-app-menusort
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/control" "$WORK/data" "$OUT"
cp -a root/. "$WORK/data/"
cp -a htdocs "$WORK/data/www" 2>/dev/null || { mkdir -p "$WORK/data/www"; cp -a htdocs/. "$WORK/data/www/"; }
find "$WORK/data" -type d -exec chmod 755 {} +
find "$WORK/data" -type f -exec chmod 644 {} +
chmod 755 "$WORK/data/usr/bin/menusort"
printf '%s\n' "$VER" > "$WORK/data/usr/share/menusort/version"

SIZE=$(du -sk "$WORK/data" | awk '{print $1}')
cat > "$WORK/control/control" <<CTRL
Package: $PKG
Version: $VER-$REL
Depends: luci-base
Source: https://github.com/iiibeloved/$PKG
SourceName: $PKG
Section: luci
SourceDateEpoch: $(date +%s)
Architecture: all
Installed-Size: $SIZE
Description: LuCI 菜单排序（服务菜单一键排序，支持正向/反向）
CTRL

echo "2.0" > "$WORK/debian-binary"

# control.tar.gz / data.tar.gz（与 OpenWrt ipkg-build 相同参数）
( cd "$WORK/data" && tar --format=gnu --owner=0 --group=0 --numeric-owner --sort=name -cf - . | gzip -n - > "$WORK/data.tar.gz" )
( cd "$WORK/control" && tar --format=gnu --owner=0 --group=0 --numeric-owner --sort=name -cf - . | gzip -n - > "$WORK/control.tar.gz" )

# ipk = gzip(tar(./debian-binary ./data.tar.gz ./control.tar.gz))
IPK="$OUT/${PKG}_${VER}-${REL}_all.ipk"
( cd "$WORK" && tar --format=gnu --owner=0 --group=0 --numeric-owner --sort=name -cf - \
      ./debian-binary ./data.tar.gz ./control.tar.gz | gzip -n - > "$OLDPWD/$IPK" )

# 清理中间文件（无）

( cd "$OUT" && sha256sum "${PKG}_${VER}-${REL}_all.ipk" > "${PKG}_${VER}-${REL}_all.ipk.sha256" )
echo "== 产物 =="
ls -l "$OUT"
cat "$OUT/${PKG}_${VER}-${REL}_all.ipk.sha256"
