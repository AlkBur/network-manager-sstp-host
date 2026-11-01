#!/usr/bin/env bash
#
# Build a standalone binary Debian package that installs ONLY the custom SSTP
# Plasma NetworkManager UI plugin (plasmanetworkmanagement_sstp-customui.so).
#
# The package never touches the files shipped by plasma-nm: the custom module
# uses its own file name, its own KPlugin id and its own X-NetworkManager-Services
# value, so it can be installed next to the stock SSTP UI.
#
# Usage:
#   build-deb.sh [--build-dir DIR] [--so PATH] [--out DIR] [--plugin-dir DIR]
#
#   --build-dir DIR   CMake build directory that already contains the compiled
#                     plugin (default: <repo>/build). If --so is given it wins.
#   --so PATH         Path to an already built
#                     plasmanetworkmanagement_sstp-customui.so.
#   --out DIR         Directory for the resulting .deb (default: ./dist).
#   --plugin-dir DIR  Absolute install directory of the plugin inside the
#                     package. Defaults to the Debian multiarch KDE plugin dir
#                     /usr/lib/<triplet>/qt6/plugins/plasma/network/vpn.
#
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"

build_dir=""
so_path=""
out_dir="${script_dir}/dist"
plugin_dir=""

while [ $# -gt 0 ]; do
    case "$1" in
        --build-dir) build_dir="$2"; shift 2 ;;
        --so) so_path="$2"; shift 2 ;;
        --out) out_dir="$2"; shift 2 ;;
        --plugin-dir) plugin_dir="$2"; shift 2 ;;
        -h|--help) sed -n '2,30p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

version="6.6.6"
arch="$(dpkg --print-architecture)"
triplet="$(gcc -dumpmachine)"
plugin_dir="${plugin_dir:-/usr/lib/${triplet}/qt6/plugins/plasma/network/vpn}"

if [ -z "${so_path}" ]; then
    build_dir="${build_dir:-${repo_root}/build}"
    so_path="${build_dir}/bin/plasmanetworkmanagement_sstp-customui.so"
fi

if [ ! -f "${so_path}" ]; then
    echo "Plugin library not found: ${so_path}" >&2
    echo "Build it first, e.g.:" >&2
    echo "  cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_OPENCONNECT=OFF" >&2
    echo "  cmake --build build --target plasmanetworkmanagement_sstp-customui" >&2
    exit 1
fi

json_src="${repo_root}/vpn/sstp-custom/plasmanetworkmanagement_sstp-customui.json"
if [ ! -f "${json_src}" ]; then
    echo "Plugin metadata not found: ${json_src}" >&2
    exit 1
fi

staging="$(mktemp -d)"
trap 'rm -rf "${staging}"' EXIT

install -d "${staging}${plugin_dir}"
install -m 0644 "${so_path}" "${staging}${plugin_dir}/plasmanetworkmanagement_sstp-customui.so"
install -m 0644 "${json_src}" "${staging}${plugin_dir}/plasmanetworkmanagement_sstp-customui.json"

install -d "${staging}/DEBIAN"
installed_size="$(du -k -s "${staging}/usr" | cut -f1)"
sed -e "s/@VERSION@/${version}-1/" \
    -e "s/@ARCH@/${arch}/" \
    -e "s/@INSTALLED_SIZE@/${installed_size}/" \
    "${script_dir}/DEBIAN/control.in" > "${staging}/DEBIAN/control"

( cd "${staging}" && find usr -type f -print0 | xargs -0 md5sum > DEBIAN/md5sums )

mkdir -p "${out_dir}"
deb_name="plasma-nm-sstp-custom_${version}-1_${arch}.deb"
dpkg-deb --build --root-owner-group "${staging}" "${out_dir}/${deb_name}"

echo "Built: ${out_dir}/${deb_name}"
