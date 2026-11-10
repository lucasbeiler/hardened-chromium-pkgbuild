#!/usr/bin/env bash
set -euo pipefail

REPO="secureblue/Trivalent"
PKGBUILD="${1:-PKGBUILD}"
PKGDIR="$(dirname "$PKGBUILD")"
API="https://api.github.com/repos/$REPO"

# Extract a variable's value from a Python file's contents.
# Handles both KEY = 'value' and KEY = 123 (with or without spaces/quotes).
get_py_var() {
  local content="$1" key="$2"
  sed -n -E "/^${key}[[:space:]]*=/{s/^${key}[[:space:]]*=[[:space:]]*['\"]?([^'\"#[:space:]]+).*/\1/p;q}" <<< "$content"
}

# Latest release tag
TAG=$(curl -fsS "$API/releases/latest" | jq -r .tag_name)
VERSION=${TAG%%-*}
VERSION=${VERSION#v}

# Validate Chrome-style version: MAJOR.MINOR.BUILD.PATCH (e.g. 157.0.8103.38)
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: invalid version '$VERSION' (tag: '$TAG')" >&2
  exit 1
fi

# Commit hash the tag points to
COMMIT=$(curl -fsS "$API/commits/$TAG" | jq -r .sha)

# Validate commit hash: 40 hex characters
if [[ ! "$COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Error: invalid commit '$COMMIT'" >&2
  exit 1
fi

# Current version in the PKGBUILD
CURRENT=$(sed -n 's/^pkgver=//p' "$PKGBUILD")

if [[ "$CURRENT" == "$VERSION" ]]; then
  echo "PKGBUILD is already at version $VERSION, nothing to do."
  exit 0
fi

# Fetch Clang and Rust revisions from the Chromium tag
CHROMIUM_RAW="https://raw.githubusercontent.com/chromium/chromium/refs/tags/$VERSION/tools"
CLANG_PY=$(curl -fsS "$CHROMIUM_RAW/clang/scripts/update.py")
RUST_PY=$(curl -fsS "$CHROMIUM_RAW/rust/update_rust.py")

CLANG_REV=$(get_py_var "$CLANG_PY" CLANG_REVISION)
CLANG_SUB=$(get_py_var "$CLANG_PY" CLANG_SUB_REVISION)
RUST_REV=$(get_py_var "$RUST_PY" RUST_REVISION)
RUST_SUB=$(get_py_var "$RUST_PY" RUST_SUB_REVISION)

# Validate revisions (non-empty, sane charset) and sub-revisions (numeric)
for rev in "$CLANG_REV" "$RUST_REV"; do
  if [[ ! "$rev" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Error: invalid revision '$rev'" >&2
    exit 1
  fi
done

for sub in "$CLANG_SUB" "$RUST_SUB"; do
  if [[ ! "$sub" =~ ^[0-9]+$ ]]; then
    echo "Error: invalid sub-revision '$sub'" >&2
    exit 1
  fi
done

echo "Updating $CURRENT -> $VERSION ($COMMIT)"
echo "  clang: $CLANG_REV (sub $CLANG_SUB)"
echo "  rust:  $RUST_REV (sub $RUST_SUB)"

# Toolchain tarball names and URLs (Chromium's prebuilt toolchain storage)
TOOLCHAIN_BASE="https://commondatastorage.googleapis.com/chromium-browser-clang/Linux_x64"
RUST_FILE="rust-toolchain-${RUST_REV}-${RUST_SUB}-${CLANG_REV}.tar.xz"
CLANG_FILE="clang-${CLANG_REV}-${CLANG_SUB}.tar.xz"

# Make sure both tarballs actually exist before touching any file
for file in "$RUST_FILE" "$CLANG_FILE"; do
  if ! curl -fsSI "$TOOLCHAIN_BASE/$file" > /dev/null; then
    echo "Error: toolchain tarball not found: $TOOLCHAIN_BASE/$file" >&2
    exit 1
  fi
done

# Update pkgver, reset pkgrel, set the new commit and toolchain revisions
sed -i \
  -e "s/^pkgver=.*/pkgver=$VERSION/" \
  -e "s/^pkgrel=.*/pkgrel=1/" \
  -e "s/^_trivalent_commit=.*/_trivalent_commit=$COMMIT/" \
  -e "s/^_clang_rev=.*/_clang_rev=$CLANG_REV/" \
  -e "s/^_clang_sub=.*/_clang_sub=$CLANG_SUB/" \
  -e "s/^_rust_rev=.*/_rust_rev=$RUST_REV/" \
  -e "s/^_rust_sub=.*/_rust_sub=$RUST_SUB/" \
  "$PKGBUILD"

# Generate the _service file
cat > "$PKGDIR/_service" << EOF
<services>
  <service name="download_url">
    <param name="url">$TOOLCHAIN_BASE/$RUST_FILE</param>
    <param name="filename">$RUST_FILE</param>
  </service>
  <service name="download_url">
    <param name="url">$TOOLCHAIN_BASE/$CLANG_FILE</param>
    <param name="filename">$CLANG_FILE</param>
  </service>
</services>
EOF

curl -LO --url "$TOOLCHAIN_BASE/$CLANG_FILE"
curl -LO --url "$TOOLCHAIN_BASE/$RUST_FILE"

# Update checksums and .SRCINFO, then commit (requires pacman-contrib)
(cd "$PKGDIR" && updpkgsums && rm -f *.tar.xz && makepkg --printsrcinfo > .SRCINFO && git add . && git commit -a -m "Update to ${VERSION}")

echo "Done."
