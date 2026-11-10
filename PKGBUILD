# Maintainer: Lucas Beiler <lucasbeiler@protonmail.com>
#
# Based on the official Arch Linux chromium PKGBUILD:
#   https://gitlab.archlinux.org/archlinux/packaging/packages/chromium
# See the link above for the list of Arch Linux maintainers, contributors and the full commit history.
# This is an unofficial derivative. Do not report issues with it to them.
#
# Hardening patches from Trivalent: https://github.com/secureblue/Trivalent

pkgname=chromium
pkgver=157.0.8103.38
pkgrel=1
_launcher_ver=8

# Official Chromium toolchain revisions:
#   tools/clang/scripts/update.py -> CLANG_REVISION / CLANG_SUB_REVISION
#   tools/rust/update_rust.py     -> RUST_REVISION  / RUST_SUB_REVISION
_clang_rev=llvmorg-24-init-7747-g62397f8b
_clang_sub=67
_rust_rev=1edd55dcfcd573872c727fa3e086369a71661ee0
_rust_sub=1125
_clang_pkg="${_clang_rev}-${_clang_sub}"
_rust_pkg="${_rust_rev}-${_rust_sub}-${_clang_rev}"
_clang_tarball="clang-${_clang_pkg}.tar.xz"
_rust_tarball="rust-toolchain-${_rust_pkg}.tar.xz"

# Trivalent hardening patches (https://github.com/secureblue/Trivalent)
_trivalent_commit=b459f266f36334b1961f1712b2dd49e6e7adb321

pkgdesc="A web browser built for speed, simplicity, and security"
arch=('x86_64')
url="https://www.chromium.org/Home"
license=('BSD-3-Clause')
depends=(
  'alsa-lib'
  'at-spi2-core'
  'cairo'
  'dbus'
  'desktop-file-utils'
  'expat'
  'glib2'
  'glibc'
  'gtk3'
  'hicolor-icon-theme'
  'libcups'
  'libffi'
  'libgcc'
  'libgcrypt'
  'libpulse'
  'libstdc++'
  'libva'
  'libx11'
  'libxcb'
  'libxcomposite'
  'libxdamage'
  'libxext'
  'libxfixes'
  'libxkbcommon'
  'libxrandr'
  'libxss'
  'mesa'
  'nspr'
  'nss'
  'pango'
  'pciutils'
  'systemd'
  'systemd-libs'
  'ttf-liberation'
  'xdg-utils'
  'zlib'
)
makedepends=(
  'git'
  'gn'
  'go'
  'gperf'
  'java-runtime-headless'
  'ninja'
  'nodejs'
  'pipewire'
  'python'
  'qt6-base'
  'vulkan-headers'
)
optdepends=('pipewire: WebRTC desktop sharing under Wayland'
            'kdialog: support for native dialogs in Plasma'
            'gtk4: for --gtk-version=4 (GTK4 IME might work better on Wayland)'
            'qt6-base: Qt support'
            'org.freedesktop.secrets: password storage backend on GNOME, KDE and Xfce'
            'upower: Battery Status API support')
options=('!lto') # Chromium adds its own flags for ThinLTO

# The toolchain tarballs have no top-level directory: extract them manually
noextract=("$_clang_tarball"
           "$_rust_tarball")

source=(https://commondatastorage.googleapis.com/chromium-browser-official/chromium-$pkgver-lite.tar.xz
        "$_clang_tarball"
        "$_rust_tarball"
        https://github.com/foutrelis/chromium-launcher/archive/v$_launcher_ver/chromium-launcher-$_launcher_ver.tar.gz
        https://github.com/secureblue/Trivalent/archive/$_trivalent_commit.tar.gz
        chromium-138-nodejs-version-check.patch
        chromium-145-fix-SYS_SECCOMP.patch
        chromium-149-use-of-undeclared-identifier-ERROR.patch
        chromium-153-hermetic-python.patch
        chromium-157-revert-gn-check-includes.patch
        glibc-2.42-baud-rate-fix.patch)
sha256sums=('6f7f34ef0f249374ee959c701a139e5d19860c1c02bc2e04f010e437cc744863'
            'ab8ec1e75c7f74565e9f893212262780abc9174363ce5f1ff670c415e9cd4147'
            '6287ecced3bc5113122a88dbe15c910edec0828718423a67529c24de0f060e98'
            '213e50f48b67feb4441078d50b0fd431df34323be15be97c55302d3fdac4483a'
            'a84fb228bc89ad41f836ae1504117cc8e876b2811b3475427e8ba7a70323e781'
            '11a96ffa21448ec4c63dd5c8d6795a1998d8e5cd5a689d91aea4d2bdd13fb06e'
            '4fc040a0656a0a524dd8ad090cd129fc5b6cb21adcc66be82080165789e8c13e'
            '951514535be65f0e2f84e82305d96292be1da353c1427ba1048ea24be70003c4'
            'ebf74154266d0b6d6cc957c413f845052c5fcfce7745befb8821595cdf3f7d49'
            '3b663878c6b05e612ba103152c48f91dde27cabe7d55ba48427a72829ff4922f'
            '1c1898f263eaacbc069a8e1a3e732852350350d1dad4cb1a6bba430e3b796cd0')

# Possible replacements are listed in build/linux/unbundle/replace_gn_files.py
declare -gA _system_libs=()
_unwanted_bundled_libs=(
  $(printf "%s\n" ${!_system_libs[@]} | sed 's/^libjpeg$/&_turbo/')
)
depends+=(${_system_libs[@]})

# Google API keys (see https://www.chromium.org/developers/how-tos/api-keys)
# Note: These are for Arch Linux use ONLY. For your own distribution, please
# get your own set of keys.
_google_api_key=AIzaSyDwr302FpOSkGRpLlUpPThNTDPbXcIn_FM

prepare() {
  cd chromium-$pkgver

  # Allow building against system libraries in official builds
  sed -i 's/OFFICIAL_BUILD/GOOGLE_CHROME_BUILD/' \
    tools/generate_shim_headers/generate_shim_headers.py

  # https://crbug.com/893950
  sed -i -e 's/\<xmlMalloc\>/malloc/' -e 's/\<xmlFree\>/free/' \
         -e '1i #include <cstdlib>' \
    third_party/blink/renderer/core/xml/*.cc \
    third_party/blink/renderer/core/xml/parser/xml_document_parser.cc \
    third_party/libxml/chromium/*.cc

  # Fixes from Gentoo
  patch -Np1 -i ../chromium-138-nodejs-version-check.patch

  # https://crbug.com/456218403
  patch -Np1 -i ../chromium-145-fix-SYS_SECCOMP.patch

  # https://crbug.com/456677057
  patch -Np1 -i ../glibc-2.42-baud-rate-fix.patch

  patch -Np1 -i ../chromium-149-use-of-undeclared-identifier-ERROR.patch

  # Use system python3 instead of the hermetic cpython3 interpreter
  # https://github.com/ungoogled-software/ungoogled-chromium/pull/3946
  patch -Np1 -i ../chromium-153-hermetic-python.patch

  patch -Np1 -i ../chromium-157-revert-gn-check-includes.patch

  # Trivalent hardening patches (https://github.com/secureblue/Trivalent)
  # Apply every *.patch under patches/, skipping anything that lives inside a
  # directory named "fixes", "fedora" or "branding" (those are specific to
  # Trivalent's own Fedora/RPM packaging and UI branding, not relevant here).
  local _trivalent_dir="$srcdir/Trivalent-$_trivalent_commit"
  local _trivalent_patch
  while IFS= read -r -d '' _trivalent_patch; do
    echo "==> Applying Trivalent patch: ${_trivalent_patch#"$_trivalent_dir/patches/"}"
    patch -Np1 -i "$_trivalent_patch"
  done < <(find "$_trivalent_dir/patches" -type f -name '*.patch' \
             -not -path '*/fedora/*' \
             -not -path '*/fixes/*' \
             -not -path '*/branding/*' \
             -print0 | sort -z)

  # ---------------------------------------------------------------------
  # Official Chromium toolchain (Clang + Rust + crubit + bindgen), extracted
  # from the pre-downloaded tarballs (equivalent to update.py/update_rust.py)
  # ---------------------------------------------------------------------
  mkdir -p third_party/llvm-build/Release+Asserts
  tar -xf "$srcdir/$_clang_tarball" \
    -C third_party/llvm-build/Release+Asserts
  echo "$_clang_pkg" > third_party/llvm-build/Release+Asserts/cr_build_revision

  rm -rf third_party/rust-toolchain
  mkdir -p third_party/rust-toolchain
  tar -xf "$srcdir/$_rust_tarball" \
    -C third_party/rust-toolchain

  # Sanity check: the bundled rustc and crubit must be present
  [[ -x third_party/rust-toolchain/bin/rustc ]] || { echo "rustc missing from tarball"; return 1; }
  [[ -e third_party/rust-toolchain/bin/cc_bindings_from_rs ]] \
    || echo "WARNING: cc_bindings_from_rs not found in rust-toolchain/bin"

  # Ensure required build tools are available (no Rust here)
  mkdir -p third_party/node/linux/node-linux-x64/bin \
           third_party/jdk/current/bin \
           third_party/dawn/tools/golang/linux-amd64/bin \
           third_party/gperf/cipd/bin

  # Prefer tools shipped in the source tarball; the host tools are fallbacks
  # for binaries omitted from Chromium's lite archive.
  [[ -x third_party/node/linux/node-linux-x64/bin/node ]] ||
    ln -sf /usr/bin/node third_party/node/linux/node-linux-x64/bin/node
  [[ -x third_party/jdk/current/bin/java ]] ||
    ln -sf /usr/bin/java third_party/jdk/current/bin/java
  [[ -x third_party/dawn/tools/golang/linux-amd64/bin/go ]] ||
    ln -sf /usr/bin/go third_party/dawn/tools/golang/linux-amd64/bin/go
  [[ -x third_party/gperf/cipd/bin/gperf ]] ||
    ln -sf /usr/bin/gperf third_party/gperf/cipd/bin/gperf

  # Remove bundled libraries for which we will use the system copies; this
  # *should* do what the remove_bundled_libraries.py script does, with the
  # added benefit of not having to list all the remaining libraries
  local _lib
  for _lib in ${_unwanted_bundled_libs[@]}; do
    # Most bundled libraries live under `third_party/<lib>`, but
    # `double-conversion` is located under `base/third_party/double_conversion`
    local _dir="third_party/$_lib"
    if [[ ! -d "${_dir}" ]]; then
      _dir="base/third_party/${_lib//-/_}"
    fi

    find "$_dir" -type f \
      \! -path "$_dir/chromium/*" \
      \! -path "$_dir/google/*" \
      \! -path "third_party/harfbuzz-ng/utils/hb_scoped.h" \
      \! -regex '.*\.\(gn\|gni\|isolate\)' \
      -delete
  done

  ./build/linux/unbundle/replace_gn_files.py \
    --system-libraries "${!_system_libs[@]}"
}

build() {
  make -C chromium-launcher-$_launcher_ver

  cd chromium-$pkgver

  # Chromium's bundled Clang (same LLVM that was used to build its Rust)
  local _clang_path="$PWD/third_party/llvm-build/Release+Asserts/bin"
  export CC=$_clang_path/clang
  export CXX=$_clang_path/clang++
  export AR=$_clang_path/llvm-ar
  export NM=$_clang_path/llvm-nm

  local _flags=(
    'is_official_build=true' # implies is_cfi=true on x86_64
    'symbol_level=0' # sufficient for backtraces on x86(_64)
    'treat_warnings_as_errors=false'
    'fatal_linker_warnings=false'
    'disable_fieldtrial_testing_config=true'
    'blink_enable_generated_code_formatting=false'
    'ffmpeg_branding="Chrome"'
    'proprietary_codecs=true'
    'rtc_use_pipewire=true'
    'link_pulseaudio=true'
    'use_custom_libcxx=true'
    'use_sysroot=false'
    'use_system_libffi=true'
    'enable_hangout_services_extension=true'
    'enable_widevine=true'
    'use_qt5=false'
    'use_qt6=true'
    'moc_qt6_path="/usr/lib/qt6"'
    "google_api_key=\"$_google_api_key\""
    'use_clang_modules=false'
    'is_clang=true'
    'clang_use_chrome_plugins=false'
    'chrome_pgo_phase=0' # the PGO profile would need a download (no network on OBS)
    'v8_enable_drumbrake=true'
    'enable_reporting=false'
    'enable_remoting=false'
    'enable_vr=false'
    'safe_browsing_use_unrar=false'
    'is_cfi=true'
    'use_cfi_cast=true'
    'use_static_angle=true'
    'angle_shared_libvulkan=false'
    'enable_swiftshader=false'
    'enable_swiftshader_vulkan=false'
    'dawn_use_swiftshader=false'
    'angle_enable_swiftshader=false'
    'angle_has_histograms=false'
  )

  if [[ -n ${_system_libs[icu]+set} ]]; then
    _flags+=('icu_use_data_file=false')
  fi

  # Facilitate deterministic builds (taken from build/config/compiler/BUILD.gn)
  CFLAGS+='   -Wno-builtin-macro-redefined'
  CXXFLAGS+=' -Wno-builtin-macro-redefined'
  CPPFLAGS+=' -D__DATE__=  -D__TIME__=  -D__TIMESTAMP__='

  # Do not warn about unknown warning options
  CFLAGS+='   -Wno-unknown-warning-option'
  CXXFLAGS+=' -Wno-unknown-warning-option'

  # Let Chromium set its own symbol level
  CFLAGS=${CFLAGS/-g }
  CXXFLAGS=${CXXFLAGS/-g }

  # https://github.com/ungoogled-software/ungoogled-chromium-archlinux/issues/123
  CFLAGS=${CFLAGS/-fexceptions}
  CXXFLAGS=${CXXFLAGS/-fexceptions}

  # https://crbug.com/957519#c122
  CXXFLAGS=${CXXFLAGS/-Wp,-D_GLIBCXX_ASSERTIONS}

  gn gen out/Release --args="${_flags[*]}"
  ninja -C out/Release chrome chrome_sandbox chromedriver.unstripped
}

package() {
  cd chromium-launcher-$_launcher_ver
  make PREFIX=/usr DESTDIR="$pkgdir" install
  install -Dvm644 LICENSE \
    "$pkgdir/usr/share/licenses/chromium/LICENSE.launcher"

  cd ../chromium-$pkgver

  install -Dv out/Release/chrome "$pkgdir/usr/lib/chromium/chromium"
  install -Dv out/Release/chromedriver.unstripped "$pkgdir/usr/bin/chromedriver"
  install -Dvm4755 out/Release/chrome_sandbox "$pkgdir/usr/lib/chromium/chrome-sandbox"

  install -Dvm644 chrome/installer/linux/common/desktop.template \
    "$pkgdir/usr/share/applications/chromium.desktop"
  install -Dvm644 chrome/app/resources/manpage.1.in \
    "$pkgdir/usr/share/man/man1/chromium.1"
  sed -i \
    -e 's/@@MENUNAME/Chromium/g' \
    -e 's/@@PACKAGE/chromium/g' \
    -e 's/@@desktop_exec/chromium/g' \
    -e 's/@@desktop_icon/chromium/g' \
    -e 's/@@startup_wm_class/chromium/g' \
    -e 's|@@uri_scheme|x-scheme-handler/chromium;|g' \
    -e 's/@@extra_desktop_entries//g' \
    "$pkgdir/usr/share/applications/chromium.desktop" \
    "$pkgdir/usr/share/man/man1/chromium.1"

  # Fill in common Chrome/Chromium AppData template with Chromium info
  (
    tmpl_file=chrome/installer/linux/common/appdata.xml.template
    info_file=chrome/installer/linux/common/chromium-browser.info
    . $info_file; PACKAGE=chromium
    export $(grep -o '^[A-Z_]*' $info_file)
    sed -E -e 's/@@([A-Z_]*)/\${\1}/g' -e '/<update_contact>/d' $tmpl_file | envsubst
  ) \
  | install -Dvm644 /dev/stdin "$pkgdir/usr/share/metainfo/chromium.appdata.xml"

  local toplevel_files=(
    chrome_100_percent.pak
    chrome_200_percent.pak
    chrome_crashpad_handler
    libqt6_shim.so
    resources.pak
    v8_context_snapshot.bin

    # ANGLE
    libEGL.so
    libGLESv2.so
  )

  if [[ -z ${_system_libs[icu]+set} ]]; then
    toplevel_files+=(icudtl.dat)
  fi

  cp "${toplevel_files[@]/#/out/Release/}" "$pkgdir/usr/lib/chromium/"
  install -Dvm644 -t "$pkgdir/usr/lib/chromium/locales" out/Release/locales/*.pak

  for size in 24 48 64 128 256; do
    install -Dvm644 "chrome/app/theme/chromium/product_logo_$size.png" \
      "$pkgdir/usr/share/icons/hicolor/${size}x${size}/apps/chromium.png"
  done

  for size in 16 32; do
    install -Dvm644 "chrome/app/theme/default_100_percent/chromium/product_logo_$size.png" \
      "$pkgdir/usr/share/icons/hicolor/${size}x${size}/apps/chromium.png"
  done

  install -Dvm644 LICENSE "$pkgdir/usr/share/licenses/chromium/LICENSE"
}

# vim:set ts=2 sw=2 et:
