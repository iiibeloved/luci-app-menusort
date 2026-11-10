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
( cd "$WORK/control" && tar -czf "$WORK/control.tar.gz" ./control 2>/dev/null || tar -czf "$WORK/control.tar.gz" control )
( cd "$WORK/data" && tar -czf "$WORK/data.tar.gz" . )
( cd "$WORK" && tar --format=gnu -czf "$OUT/$PKG-${VER}-${REL}.tar.gz" ./control.tar.gz ./data.tar.gz ./debian-binary 2>/dev/null || true )
# 生成 ipk（ar 格式）
IPK="$OUT/${PKG}_${VER}-${REL}_all.ipk"
if command -v ar >/dev/null 2>&1; then
	( cd "$WORK" && ar rcs "$OLDPWD/$IPK" ./debian-binary ./control.tar.gz ./data.tar.gz )
else
	python3 - "$WORK" "$IPK" <<'PY'
import sys, os
work, out = sys.argv[1], sys.argv[2]
def ar_entry(name, data):
    hdr = b"%-16s%-12s%-6s%-6s%-8s%-10d`\n" % (name.encode(), b"0", b"0", b"0", b"100644", len(data))
    return hdr + data + (b"\n" if len(data) % 2 else b"")
with open(out, "wb") as f:
    f.write(b"!<arch>\n")
    for n, p in [("debian-binary","debian-binary"),("control.tar.gz","control.tar.gz"),("data.tar.gz","data.tar.gz")]:
        f.write(ar_entry(n, open(os.path.join(work,p),"rb").read()))
PY
fi
rm -f "$OUT/$PKG-${VER}-${REL}.tar.gz"
( cd "$OUT" && sha256sum "${PKG}_${VER}-${REL}_all.ipk" > "${PKG}_${VER}-${REL}_all.ipk.sha256" )
echo "== 产物 =="
ls -l "$OUT"
cat "$OUT/${PKG}_${VER}-${REL}_all.ipk.sha256"
