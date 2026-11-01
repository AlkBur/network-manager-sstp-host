# Custom SSTP variant

A standalone, parallel-installable SSTP backend and Plasma 6 UI plugin derived from:

- [GNOME NetworkManager SSTP](https://gitlab.gnome.org/GNOME/network-manager-sstp) 1.3.2 (`4eefca0`)
- [KDE plasma-nm](https://invent.kde.org/plasma/plasma-nm) 6.6.6 (`1a7177547`)

The custom variant uses its own D-Bus service type `org.freedesktop.NetworkManager.sstp.custom`, its own file and library names, and can be installed next to the stock SSTP plugin. It also includes the optional **Host** parameter passed to `sstpc` as `--host`.

## Contents

| File | Description |
|---|---|
| `source.patch` | NetworkManager SSTP custom backend relative to upstream `4eefca0` |
| `plasma-ui.patch` | Plasma UI plugin relative to plasma-nm `1a7177547` (6.6.6) |
| `package/plasma-nm-sstp-custom_6.6.6-1_amd64.deb` | Prebuilt Plasma UI plugin package |
| `package/build-deb.sh` | Original packaging script (copy to `plasma-nm/packaging/sstp-custom/`) |
| `package/DEBIAN/control.in` | Debian control template used by the script |

## Differences from upstream

| Upstream | Custom |
|---|---|
| Service type `org.freedesktop.NetworkManager.sstp` | `org.freedesktop.NetworkManager.sstp.custom` |
| D-Bus paths `/sstp`, `/sstp/ppp` | `/sstp/custom`, `/sstp/custom/ppp` |
| Library `libnm-vpn-plugin-sstp.so`, `nm-sstp-service` | `libnm-vpn-plugin-sstp-custom.so`, `nm-sstp-service-custom` |
| pppd plugin `nm-sstp-pppd-plugin.so` | `nm-sstp-pppd-plugin-custom.so` |
| Plasma UI plugin not provided | `plasmanetworkmanagement_sstp-customui.so` |

## Tested environment

- Ubuntu 26.04, amd64
- Plasma 6.6.6, plasma-nm 6.6.6
- NetworkManager with libnm
- pppd 2.5.2
- sstp-client 1.0.10 or newer

The prebuilt `.deb` targets Plasma 6.6.6 on amd64. Rebuild it for other Plasma versions or architectures.

## Build the custom NetworkManager SSTP backend

Install the build dependencies:

```bash
sudo apt install \
  build-essential autoconf automake libtool gettext pkg-config \
  libglib2.0-dev libnm-dev libnma-dev libsecret-1-dev libgnutls28-dev \
  ppp-dev sstp-client
```

Add `libnma-gtk4-dev` only if you also want the GTK4 connection editor.

Apply the patch to a clean upstream checkout:

```bash
git clone https://gitlab.gnome.org/GNOME/network-manager-sstp.git
cd network-manager-sstp
git checkout 4eefca0
git apply /path/to/custom/source.patch
```

Configure and install:

```bash
./autogen.sh \
  --prefix=/usr \
  --sysconfdir=/etc \
  --localstatedir=/var \
  --with-pppd-plugin-dir="$(pkg-config --variable=plugindir pppd)"

make -j"$(nproc)"
sudo make install
sudo systemctl reload dbus
sudo systemctl restart NetworkManager
```

If `pkg-config --variable=plugindir pppd` returns nothing, pass the directory explicitly, for example `--with-pppd-plugin-dir=/usr/lib/pppd/2.5.2`.

Installed files include:

- `/usr/libexec/nm-sstp-service-custom`
- `/usr/libexec/nm-sstp-auth-dialog-custom`
- `/usr/lib/NetworkManager/libnm-vpn-plugin-sstp-custom.so`
- `/usr/lib/NetworkManager/VPN/nm-sstp-service-custom.name`
- `/usr/share/dbus-1/system.d/nm-sstp-service-custom.conf`
- `/usr/lib/pppd/2.5.2/nm-sstp-pppd-plugin-custom.so`

## Install the Plasma UI plugin

### Prebuilt package

```bash
sudo apt install ./package/plasma-nm-sstp-custom_6.6.6-1_amd64.deb
```

The package installs only `plasmanetworkmanagement_sstp-customui.so` and its JSON metadata into the Plasma VPN plugin directory. It does not modify the stock plasma-nm SSTP plugin.

### Build from source

Apply the Plasma UI patch to a clean plasma-nm checkout:

```bash
git clone https://invent.kde.org/plasma/plasma-nm.git
cd plasma-nm
git checkout 1a7177547
git apply /path/to/custom/plasma-ui.patch
```

Configure and build the plugin target:

```bash
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_OPENCONNECT=OFF
cmake --build build --target plasmanetworkmanagement_sstp-customui
```

Build the `.deb` with the included packaging script:

```bash
mkdir -p packaging/sstp-custom
cp /path/to/custom/package/build-deb.sh packaging/sstp-custom/
cp -r /path/to/custom/package/DEBIAN packaging/sstp-custom/
./packaging/sstp-custom/build-deb.sh \
  --so build/bin/plasmanetworkmanagement_sstp-customui.so
```

## Usage

1. Open Plasma System Settings → Connections.
2. Add a new VPN connection and select **Secure Socket Tunneling Protocol (SSTP Custom)**.
3. Enter the gateway address. The optional **Host** field is passed to `sstpc` as `--host`.
4. Connect. The stock SSTP entry remains available separately.

Verify the service type:

```bash
nmcli -f vpn.service-type connection show "your-connection-name"
```

Expected value:

```
org.freedesktop.NetworkManager.sstp.custom
```

## Hostname validation

The Host field is optional. When set, it must satisfy:

- maximum total length 253 characters;
- DNS labels of 1–63 characters;
- ASCII letters, digits, `.` and `-` only;
- no label starting or ending with `-`;
- no trailing dot.

Validation is enforced both in the Plasma/GTK editor and in the VPN service.

## Checksums

**source.patch**

`b09b9f75d5f483eff78a1af8159b79a963c1f4d944a884b032c6b931d549f00d`

**plasma-ui.patch**

`cdbd5368d194280a23840fb9df5a595a810374f683da89cbdb105ab54ad4395f`

**plasma-nm-sstp-custom_6.6.6-1_amd64.deb**

`e8cb10d0303ca16a46667b67451a4eea6d5ba8116310ce097b60fc451ce6b92f`

## Notes

- The custom variant is independent of the upstream patch in `../upstream/`. Do not apply both to the same source tree.
- The custom D-Bus identifiers and library names are intentionally different, so both implementations can coexist.
- The prebuilt package is a convenience artifact; source patches and build instructions are authoritative.
