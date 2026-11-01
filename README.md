# NetworkManager SSTP — Optional Host Parameter and Custom Variant

An independent contribution archive for [GNOME NetworkManager SSTP](https://gitlab.gnome.org/GNOME/network-manager-sstp).

The repository contains two separate tracks that share the same development history but are not meant to be mixed:

| Directory | Purpose |
|---|---|
| [`upstream/`](upstream/) | Minimal patch adding the optional Host parameter to the upstream project |
| [`custom/`](custom/) | Standalone, parallel-installable SSTP backend and Plasma UI, see [`custom/README.md`](custom/README.md) |

## Upstream patch

This patch adds an optional **Host** parameter to the NetworkManager SSTP connection editor.

The value is passed to `sstpc` using the `--host` option.

This allows specifying the SSTP virtual hostname separately from the gateway address. It is useful when connecting to an IP address while requiring a specific hostname for HTTP, proxy or TLS extension handling.

### Implementation

The change affects four files:

- `properties/nm-sstp-dialog.ui` — adds the Host field.
- `properties/nm-sstp-editor.c` — reads, saves and validates the hostname.
- `shared/nm-service-defines.h` — defines the `host` property.
- `src/nm-sstp-service.c` — validates the property and passes `--host` to `sstpc`.

Hostname validation is performed both in the connection editor and in the VPN service.

Existing connections without the Host property retain their previous behavior.

### Tested

- Applies cleanly to upstream commit `4eefca0`.
- GTK3 build with `--enable-more-warnings=error`.
- GTK4 build with `--enable-more-warnings=error`.
- `make check` passes in both configurations.
- `pty` argument parsing verified with and without Host.

Live NetworkManager/SSTP connection tests have not yet been performed.

### Patch information

- Commit: `2039312ad3479ab2d9298be5aa88f4afa66877f6`
- Branch: `sstp-host-parameter`
- Changed files: 4
- Diff: 128 insertions, 1 deletion

### Files

| File | Description |
|---|---|
| `upstream/0001-sstp-add-optional-host-parameter.patch` | Git patch for applying the change to the upstream source |
| `upstream/sstp-host-parameter.bundle` | Git bundle containing the branch and commit history |

### Checksums

**Git bundle SHA-256**

`cb0421ab43658e6ca350f6245e0e1dadd0dcc7d43832d316b432db3fa44ea483`

**Patch SHA-256**

`c1ecc172274666c86e17613bb34b8f8aea82f8c56b15348bd458eacd48795cd8`

### Applying the patch

```bash
git apply upstream/0001-sstp-add-optional-host-parameter.patch
```

### Restoring the complete branch

```bash
git clone -b sstp-host-parameter \
  upstream/sstp-host-parameter.bundle \
  network-manager-sstp
```

## Custom variant

The custom variant is a standalone SSTP backend derived from the same sources, renamed to its own D-Bus identifiers (`org.freedesktop.NetworkManager.sstp.custom`) and designed to be installed alongside the stock SSTP plugin. It also includes the optional Host parameter and provides a separate Plasma 6 UI plugin.

It is distributed as two source patches and a prebuilt Plasma plugin package:

- `custom/source.patch` — NetworkManager SSTP custom backend relative to `4eefca0`.
- `custom/plasma-ui.patch` — Plasma UI plugin relative to plasma-nm `1a7177547` (6.6.6).
- `custom/package/plasma-nm-sstp-custom_6.6.6-1_amd64.deb` — prebuilt Plasma UI plugin for Plasma 6.6.6 / Ubuntu 26.04.

Build, installation and verification instructions are in [`custom/README.md`](custom/README.md).

## Upstream

Target project: [GNOME NetworkManager SSTP](https://gitlab.gnome.org/GNOME/network-manager-sstp)

This repository contains an independent contribution archive. It is not an official GNOME project or an upstream release.
