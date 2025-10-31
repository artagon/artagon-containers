#!/usr/bin/env bash
set -euo pipefail

FLAVOR="jdk25"
ARCH="amd64"
LIBC="glibc"
TYPE="chainguard"
OUTPUT=""

usage() {
  cat <<'USAGE'
resolve_jdk.sh --flavor=<jdk25|jdk26ea|jdk26valhalla> --arch=<amd64|arm64> [--libc=<glibc|musl>] [--type=<chainguard|distroless|ubi9>] [--output=FILE]
Parses Artagon tap formulae (26 EA/Valhalla) or Adoptium API (25 GA) to emit build args.
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --flavor=*) FLAVOR="${arg#*=}" ;;
    --arch=*) ARCH="${arg#*=}" ;;
    --libc=*) LIBC="${arg#*=}" ;;
    --type=*) TYPE="${arg#*=}" ;;
    --output=*) OUTPUT="${arg#*=}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage; exit 1 ;;
  esac
done

if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" ]]; then
  echo "Unsupported arch: $ARCH" >&2
  exit 1
fi

if [[ "$LIBC" != "glibc" && "$LIBC" != "musl" ]]; then
  echo "Unsupported libc: $LIBC" >&2
  exit 1
fi

emit_env() {
  if [[ -n "$OUTPUT" ]]; then
    mkdir -p "$(dirname "$OUTPUT")"
    cat >"$OUTPUT"
  else
    cat
  fi
}

if [[ "$FLAVOR" == "jdk26ea" || "$FLAVOR" == "jdk26valhalla" ]]; then
  formula="$FLAVOR"
  url="https://raw.githubusercontent.com/artagon/homebrew-${formula}/main/Formula/${formula}.rb"
  tmpfile="$(mktemp)"
  curl -fsSL "$url" >"$tmpfile"

  FORMULA_PATH="$tmpfile" ARCH="$ARCH" LIBC="$LIBC" FLAVOR="$FLAVOR" TYPE="$TYPE" \
  python3 <<'PY' | emit_env
import os, re, sys

path = os.environ["FORMULA_PATH"]
arch = os.environ["ARCH"]
libc = os.environ["LIBC"]
flavor = os.environ["FLAVOR"]
image_type = os.environ["TYPE"]

with open(path, "r", encoding="utf-8") as fh:
    data = fh.read()

version_match = re.search(r'version\s+"([^"]+)"', data)
version = version_match.group(1) if version_match else ""

sha_map = {k: v for k, v in re.findall(r'sha256\s+([A-Za-z0-9_]+):\s+"([0-9a-fA-F]+)"', data)}
urls = re.findall(r'url\s+"([^"]+)"', data)

linux_assets = {}
for match in re.finditer(r'url\s+"([^"]+linux-[^"]+)"\s+sha256\s+"([0-9a-fA-F]+)"', data):
    url, sha = match.groups()
    key = None
    if "linux-x64-musl" in url:
        key = ("amd64", "musl")
    elif "linux-aarch64-musl" in url:
        key = ("arm64", "musl")
    elif "linux-x64" in url:
        key = ("amd64", "glibc")
    elif "linux-aarch64" in url:
        key = ("arm64", "glibc")
    if key and key not in linux_assets:
        linux_assets[key] = (url, sha)

selected_url = None
selected_sha = None

if (arch, libc) in linux_assets:
    selected_url, selected_sha = linux_assets[(arch, libc)]
elif libc == "musl" and (arch, "glibc") in linux_assets:
    selected_url, selected_sha = linux_assets[(arch, "glibc")]

if not selected_url or not selected_sha:
    if arch == "amd64":
        url_order = ["linux-x64-musl", "linux-x64"] if libc == "musl" else ["linux-x64"]
        sha_order = ["x86_64_linux_musl", "x86_64_linux"] if libc == "musl" else ["x86_64_linux"]
    else:
        url_order = ["linux-aarch64-musl", "linux-aarch64"] if libc == "musl" else ["linux-aarch64"]
        sha_order = ["aarch64_linux_musl", "arm64_linux_musl", "aarch64_linux", "arm64_linux"] if libc == "musl" else ["aarch64_linux", "arm64_linux"]

    for keyword in url_order:
        for candidate in urls:
            if keyword in candidate:
                selected_url = candidate
                break
        if selected_url:
            break

    if not selected_url and libc == "musl":
        fallback_urls = ["linux-x64"] if arch == "amd64" else ["linux-aarch64"]
        for keyword in fallback_urls:
            for candidate in urls:
                if keyword in candidate:
                    selected_url = candidate
                    break
            if selected_url:
                break

    for key in sha_order:
        if key in sha_map:
            selected_sha = sha_map[key]
            break

    if not selected_sha and libc == "musl":
        fallback_sha = ["x86_64_linux"] if arch == "amd64" else ["aarch64_linux", "arm64_linux"]
        for key in fallback_sha:
            if key in sha_map:
                selected_sha = sha_map[key]
                break

if not selected_url:
    raise SystemExit("No matching download URL found for given arch/libc")

if not selected_sha:
    raise SystemExit("No matching sha256 found for given arch/libc")

signature_url = selected_url + ".sig" if selected_url.endswith(".tar.gz") else ""

print(f"FLAVOR={flavor}")
print(f"VERSION={version}")
print(f"JDK_URL={selected_url}")
print(f"JDK_SHA256={selected_sha}")
if signature_url:
    print(f"SIGNATURE_URL={signature_url}")
print(f"ARCH={arch}")
print(f"LIBC={libc}")
print(f"TYPE={image_type}")
PY

  rm -f "$tmpfile"
else
  if [[ "$ARCH" == "amd64" ]]; then
    arch_param="x64"
  else
    arch_param="aarch64"
  fi
  if [[ "$LIBC" == "musl" ]]; then
    api_os="alpine-linux"
  else
    api_os="linux"
  fi
  api="https://api.adoptium.net/v3/assets/feature_releases/25/ga"
  query="?architecture=${arch_param}&os=${api_os}&image_type=jdk&package_type=jdk&vendor=eclipse&jvm_impl=hotspot"
  if ! response="$(curl -fsSL "${api}${query}" 2>/dev/null)"; then
    echo "Failed to resolve JDK 25 metadata" >&2
    exit 1
  fi
  ARCH="$ARCH" LIBC="$LIBC" TYPE="$TYPE" RESPONSE="$response" API_OS="$api_os" ARCH_PARAM="$arch_param" \
  python3 <<'PY' | emit_env
import json, os, sys

resp = os.environ["RESPONSE"]
data = json.loads(resp)
if not data:
    raise SystemExit("No Adoptium assets returned")

arch = os.environ["ARCH"]
arch_param = os.environ["ARCH_PARAM"]
api_os = os.environ["API_OS"]

binary = None
version = ""
for release in data:
    for candidate in release.get("binaries", []):
        if candidate.get("os") == api_os and candidate.get("image_type") == "jdk" and candidate.get("architecture") in (arch, arch_param):
            binary = candidate
            version = release.get("release_name", "")
            break
    if binary:
        break

if binary is None:
    raise SystemExit("No matching binary found for requested architecture/libc")

pkg = binary.get("package", {})
sig = pkg.get("signature_link", "")

print("FLAVOR=jdk25")
print(f"VERSION={version}")
print(f"JDK_URL={pkg.get('link','')}")
print(f"JDK_SHA256={pkg.get('checksum','')}")
if pkg.get('checksum_link'):
    print(f"CHECKSUM_URL={pkg['checksum_link']}")
if sig:
    print(f"SIGNATURE_URL={sig}")
print(f"ARCH={os.environ['ARCH']}")
print(f"LIBC={os.environ['LIBC']}")
print(f"TYPE={os.environ['TYPE']}")
PY
fi
