# Scripts

A collection of automation scripts for system administration and DevOps tasks.
Each script addresses a specific workflow—from LUKS password management to
Cloudflare configuration and OpenShift image mirroring.

This README provides an overview of each file included in this repository.

## add_luks_key.sh

Add a new LUKS passphrase to all encrypted block devices on the system.

**Prerequisites:** `cryptsetup`, `expect`, and `lsblk`.

**Usage:**
```bash
add_luks_key.sh [--old <existing-password>] [--new <new-password>] [--debug]
```

## checkport

Lightweight TCP port connectivity checker with retries.

**Prerequisites:** Bash with `/dev/tcp` support and GNU `timeout`.

**Usage:**
```bash
checkport [ -h|--help ] HOST PORT
```

## mount -external.sh

Detect and mount the first USB storage device on `/mnt`.

**Prerequisites:** Root privileges and `udevadm`, `lsblk`.

**Usage:**
```bash
./mount -external.sh
```

## oc-mirror-wrapper.sh

Wrapper around `oc-mirror` to automatically retry on failure and log output.

**Prerequisites:** OpenShift `oc-mirror` binary, Bash.

**Usage:**
```bash
oc-mirror-wrapper.sh -c <config-file> -d <destination-dir> [-l <log-dir>] [--ocpath /path/to/oc-mirror] [--debug]
```

## openshift_offline_mirror.py

Export images listed in a mapping file, save them as Docker archives, and generate
an `ImageContentSourcePolicy` for offline OpenShift installations.

**Prerequisites:** Python 3, `skopeo`, `pyyaml`.

**Usage:**
```bash
openshift_offline_mirror.py -f <mapping-file> [--authfile <docker-authfile>]
```

## racadm-disk-mounting.sh

Mount and unmount ISO images on Dell iDRAC-managed hosts via `racadm`.

**Prerequisites:** `racadm` tool, Bash.

**Usage:**
```bash
# Single host
racadm-disk-mounting.sh -h <host> -u <user> -p <password> -f <iso-path> [--debug]

# Multiple hosts
racadm-disk-mounting.sh -i hosts.txt -u <user> -p <password> -f <iso-path> [--debug] [--restart-hosts]
```

## remoteluksunlock.sh

Expect script to remotely send a LUKS passphrase to a host during boot via Dropbear SSH.

**Prerequisites:** `expect`, SSH access to target host.

**Usage:**
```bash
remoteluksunlock.sh <host> <port> <luks-passphrase>
```

## salt_users_gen.py

Generate a SaltStack Pillar `users.yml` file by scanning `/home` directories
and collecting SSH public keys and user IDs from `/etc/passwd`.

**Prerequisites:** Python 2.7, `pyyaml`.

**Usage:**
```bash
./salt_users_gen.py
```

## ssl_cert_check.sh

Check SSL certificate expiry for a list of domains and report remaining days.

**Prerequisites:** OpenSSL, GNU `timeout`.

**Usage:**
```bash
ssl_cert_check.sh -f <input-file> [-o <output-file>]
```

## validate_cert_chain.sh

Validate that a private key matches its certificate and verify the certificate chain
against a root CA and optional intermediates.

**Prerequisites:** OpenSSL.

**Usage:**
```bash
validate_cert_chain.sh <key-file> <cert-file> <root-ca-file> [<intermediate-cert-file>]
```

## wigle_scanner_upload.sh

Archive and upload Kismet wardrive output to the Wigle API.

**Prerequisites:** `curl`, Kismet, appropriate API credentials.

**Usage:**
```bash
wigle_scanner_upload.sh
```

## cloudflare/cf_zone_setting_enable.sh

Enable or disable HTTP/3, 0-RTT, and Enhanced HTTP/2 Edge Prioritization settings
for all Cloudflare zones.

**Prerequisites:** `curl`, `jq`, `CF_TOKEN` environment variable.

**Usage:**
```bash
HTTP3_ENABLED=<TRUE|FALSE> ZERO_RTT_ENABLED=<TRUE|FALSE> H2_PRIORITIZATION_ENABLED=<TRUE|FALSE> CF_TOKEN=<token> cloudflare/cf_zone_setting_enable.sh
```

## cloudflare/cf_record_check.sh

Retrieve the zone ID and A record IP address for a given subdomain.

**Prerequisites:** `curl`, `jq`, `CF_TOKEN`, `DOMAIN`, and `SUBDOMAIN` environment variables.

**Usage:**
```bash
cf_record_check.sh
```

## cloudflare/cf_config_check.sh

Check enabled HTTP/3, 0-RTT, and Enhanced HTTP/2 settings for all accessible Cloudflare zones.

**Prerequisites:** `curl`, `jq`, `CF_TOKEN` environment variable.

**Usage:**
```bash
cloudflare/cf_config_check.sh
```

## cloudflare/cf_cipher_check.sh

Query custom TLS cipher settings for a specific Cloudflare zone.

**Prerequisites:** `curl`, `jq`, `CF_TOKEN`, and `DOMAIN` environment variables.

**Usage:**
```bash
cf_cipher_check.sh
```

## LICENSE

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
