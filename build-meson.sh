#!/bin/bash
# Flashrom meson build script
#
# Pins libpci 3.7.0 under deps/ for older-distro ABI compatibility (internal
# programmer and other PCI-based programmers). Prefer that over a newer system
# or /usr/local libpci. ECAM (libpci >= 3.13) is intentionally unavailable.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Reasonable target: Debian bullseye / Ubuntu 20.04–22.04 era.
# Flashrom requires >= 2.2.0; SONAME remains libpci.so.3.
PCIUTILS_VERSION="3.7.0"
PCIUTILS_TAG="v${PCIUTILS_VERSION}"
PCIUTILS_PREFIX="${SCRIPT_DIR}/deps/pciutils-${PCIUTILS_VERSION}"
PCIUTILS_SRC="${SCRIPT_DIR}/deps/pciutils-src"
PCIUTILS_PC="${PCIUTILS_PREFIX}/lib/pkgconfig"

ensure_pinned_libpci() {
	local version
	if [ -x "${PCIUTILS_PREFIX}/lib/libpci.so" ] || [ -e "${PCIUTILS_PREFIX}/lib/libpci.so.3" ]; then
		if [ -f "${PCIUTILS_PC}/libpci.pc" ]; then
			version="$(PKG_CONFIG_PATH="${PCIUTILS_PC}" pkg-config --modversion libpci 2>/dev/null || true)"
			if [ "$version" = "$PCIUTILS_VERSION" ]; then
				echo "Using pinned libpci ${version} at ${PCIUTILS_PREFIX}"
				return 0
			fi
		fi
	fi

	echo "Building pinned pciutils ${PCIUTILS_VERSION} into ${PCIUTILS_PREFIX}..."
	mkdir -p "$(dirname "$PCIUTILS_SRC")" "$(dirname "$PCIUTILS_PREFIX")"

	if [ ! -d "${PCIUTILS_SRC}/.git" ]; then
		rm -rf "$PCIUTILS_SRC"
		git clone --depth 1 --branch "$PCIUTILS_TAG" \
			https://github.com/pciutils/pciutils.git "$PCIUTILS_SRC"
	else
		git -C "$PCIUTILS_SRC" fetch --depth 1 origin "refs/tags/${PCIUTILS_TAG}:refs/tags/${PCIUTILS_TAG}" 2>/dev/null || true
		git -C "$PCIUTILS_SRC" checkout -f "$PCIUTILS_TAG"
	fi

	# Shared lib, no hwdb/kmod — fewer host deps and cleaner for redistribution.
	make -C "$PCIUTILS_SRC" clean >/dev/null 2>&1 || true
	make -C "$PCIUTILS_SRC" -j"$(nproc)" \
		SHARED=yes \
		ZLIB=yes \
		DNS=no \
		HWDB=no \
		LIBKMOD=no \
		PREFIX="$PCIUTILS_PREFIX" \
		OPT="-O2 -fPIC"
	make -C "$PCIUTILS_SRC" install-lib \
		SHARED=yes \
		ZLIB=yes \
		DNS=no \
		HWDB=no \
		LIBKMOD=no \
		PREFIX="$PCIUTILS_PREFIX"

	# Also install pci.ids / tools for a complete prefix (optional but useful)
	make -C "$PCIUTILS_SRC" install \
		SHARED=yes \
		ZLIB=yes \
		DNS=no \
		HWDB=no \
		LIBKMOD=no \
		PREFIX="$PCIUTILS_PREFIX"

	version="$(PKG_CONFIG_PATH="${PCIUTILS_PC}" pkg-config --modversion libpci)"
	echo "Installed pinned libpci ${version}"
}

# Prefer pinned libpci; keep system paths for other deps; put /usr/local last.
ensure_pinned_libpci
export PKG_CONFIG_PATH="${PCIUTILS_PC}:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/local/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH="${PCIUTILS_PREFIX}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Parse command line arguments
CLEAN=false
PROGRAMMER_LIST=""

show_usage() {
	echo "Usage: $0 [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  -p, --programmer <list>   Comma-separated list of programmers to enable"
	echo "                            Examples: internal,raiden_debug_spi,ch341a_spi"
	echo "                            Special values: auto, all, group_internal, group_external"
	echo "  -c, --clean               Clean build directory before building"
	echo "  -h, --help                Show this help message"
	echo ""
	echo "Pinned libpci: ${PCIUTILS_VERSION} -> ${PCIUTILS_PREFIX}"
	echo ""
	echo "Examples:"
	echo "  $0 -p internal"
	echo "  $0 -p internal,raiden_debug_spi"
	echo "  $0 --clean -p internal,ch341a_spi,ft2232_spi"
	echo "  $0 -p group_internal"
	echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
		-p|--programmer)
			PROGRAMMER_LIST="$2"
			shift 2
			;;
		-c|--clean|clean)
			CLEAN=true
			shift
			;;
		-h|--help|help)
			show_usage
			exit 0
			;;
		*)
			echo "Unknown option: $1"
			show_usage
			exit 1
			;;
	esac
done

# Clean if requested
if [ "$CLEAN" = true ]; then
	echo "Cleaning build directory..."
	rm -rf builddir
fi

# rpath $ORIGIN so a shipped flashrom + libpci.so.3 in the same dir work on older hosts
MESON_OPTS=(-Dc_link_args='-Wl,-rpath,$ORIGIN')
if [ -n "$PROGRAMMER_LIST" ]; then
	MESON_OPTS+=("-Dprogrammer=${PROGRAMMER_LIST}")
	echo "Building with programmers: $PROGRAMMER_LIST"
fi

echo "libpci via pkg-config: $(pkg-config --modversion libpci) ($(pkg-config --libs libpci))"

# Setup meson
if [ ! -d "builddir" ]; then
	echo "Setting up meson build..."
	meson setup builddir "${MESON_OPTS[@]}"
else
	echo "Build directory exists, reconfiguring..."
	meson setup builddir --reconfigure "${MESON_OPTS[@]}"
fi

# Compile
echo "Compiling flashrom..."
meson compile -C builddir

# Ship pinned libpci next to the binary (needed for $ORIGIN rpath / redistribution)
cp -a "${PCIUTILS_PREFIX}/lib/libpci.so"* builddir/

echo ""
echo "Build successful!"
echo "  libpci: $(pkg-config --modversion libpci) (pinned ${PCIUTILS_VERSION})"
echo "Binaries located at:"
echo "  - builddir/flashrom"
echo "  - builddir/libflashrom.so"
echo "  - builddir/libpci.so* (pinned ${PCIUTILS_VERSION}; ship with flashrom)"
echo ""
echo "Verify: ldd builddir/flashrom | grep libpci"
