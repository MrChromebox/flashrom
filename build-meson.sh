#!/bin/bash
# Flashrom meson build script
#
# Pins libpci 3.7.0 under deps/ for older-distro ABI compatibility (internal
# programmer and other PCI-based programmers). Prefer that over a newer system
# or /usr/local libpci. ECAM (libpci >= 3.13) is intentionally unavailable.
#
# Optional --container builds inside an older Ubuntu image so the binary does
# not require a newer glibc than the target host (host builds often need
# GLIBC_2.38+).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Reasonable target: Debian bullseye / Ubuntu 20.04–22.04 era.
# Flashrom requires >= 2.2.0; SONAME remains libpci.so.3.
PCIUTILS_VERSION="3.7.0"
PCIUTILS_TAG="v${PCIUTILS_VERSION}"

# Parse command line arguments first (needed for --container re-exec).
CLEAN=false
PROGRAMMER_LIST=""
CONTAINER=""
FORWARD_ARGS=()

show_usage() {
	echo "Usage: $0 [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  -p, --programmer <list>   Comma-separated list of programmers to enable"
	echo "                            Examples: internal,raiden_debug_spi,ch341a_spi"
	echo "                            Special values: auto, all, group_internal, group_external"
	echo "  -c, --clean               Clean build directory before building"
	echo "  --container <release>     Build in Ubuntu container for older glibc"
	echo "                            Releases: 20.04, 22.04 (default recommendation: 22.04)"
	echo "                            Also accepts a full image name (e.g. ubuntu:22.04)"
	echo "  -h, --help                Show this help message"
	echo ""
	echo "Pinned libpci: ${PCIUTILS_VERSION} under deps/"
	echo ""
	echo "Examples:"
	echo "  $0 -p internal"
	echo "  $0 --container 22.04 -c -p internal,dummy"
	echo "  $0 --container 20.04 -c -p internal,dummy"
	echo "  $0 --clean -p internal,ch341a_spi,ft2232_spi"
	echo ""
}

while [[ $# -gt 0 ]]; do
	case $1 in
		-p|--programmer)
			PROGRAMMER_LIST="$2"
			FORWARD_ARGS+=("$1" "$2")
			shift 2
			;;
		-c|--clean|clean)
			CLEAN=true
			FORWARD_ARGS+=("-c")
			shift
			;;
		--container)
			CONTAINER="$2"
			shift 2
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

resolve_container_image() {
	case "$1" in
		20.04|ubuntu:20.04) echo "ubuntu:20.04" ;;
		22.04|ubuntu:22.04) echo "ubuntu:22.04" ;;
		24.04|ubuntu:24.04) echo "ubuntu:24.04" ;;
		*/*|*:* ) echo "$1" ;;
		*)
			echo "Unsupported --container value: $1 (try 20.04 or 22.04)" >&2
			exit 1
			;;
	esac
}

container_tag_suffix() {
	# Safe path component derived from image name.
	echo "$1" | tr ':/' '--'
}

pick_container_runtime() {
	if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
		echo docker
	elif command -v podman >/dev/null 2>&1; then
		echo podman
	else
		echo "Neither docker nor podman is available/usable." >&2
		exit 1
	fi
}

run_in_container() {
	local image runtime
	image="$(resolve_container_image "$CONTAINER")"
	runtime="$(pick_container_runtime)"

	echo "Building inside ${image} via ${runtime} (older glibc target)..."
	echo "Host args forwarded: ${FORWARD_ARGS[*]:-}"

	# Host-built objects/libs may need a newer glibc — always rebuild in-tree
	# artifacts for the container image. Keep the pciutils git checkout.
	local suffix
	suffix="$(container_tag_suffix "$image")"
	rm -rf "${SCRIPT_DIR}/deps/pciutils-${PCIUTILS_VERSION}-${suffix}" \
		"${SCRIPT_DIR}/builddir"

	local forward
	forward="${FORWARD_ARGS[*]:-}"

	# Install build deps, then re-enter this script without --container.
	# DEBIAN_FRONTEND avoids interactive tzdata prompts.
	"${runtime}" run --rm -i \
		-e DEBIAN_FRONTEND=noninteractive \
		-e FLASHROM_IN_CONTAINER=1 \
		-e FLASHROM_CONTAINER_IMAGE="$image" \
		-e FLASHROM_HOST_UID="$(id -u)" \
		-e FLASHROM_HOST_GID="$(id -g)" \
		-v "${SCRIPT_DIR}:/src" \
		-w /src \
		"$image" \
		bash -lc "
set -euo pipefail
apt-get update -qq
apt-get install -y -qq \
	build-essential pkg-config git ca-certificates \
	zlib1g-dev python3 python3-pip python3-setuptools \
	python3-wheel ninja-build
# Ubuntu 20.04 apt meson is too old for flashrom (>=0.56); use pip.
python3 -m pip install -q 'meson>=0.56' 'ninja'
# Host-mounted deps/ is owned by the user; allow git as root in the container.
git config --global --add safe.directory '*'
# Disable RPMC so we do not link OpenSSL 3 (absent on Ubuntu 20.04).
export FLASHROM_DISABLE_RPMC=1
./build-meson.sh ${forward}
# Container runs as root; restore ownership for the host user.
chown -R \"\${FLASHROM_HOST_UID}:\${FLASHROM_HOST_GID}\" \
	/src/builddir /src/deps || true
"
}

if [ -n "$CONTAINER" ] && [ "${FLASHROM_IN_CONTAINER:-0}" != "1" ]; then
	run_in_container
	exit 0
fi

# Container-specific prefix so host and container builds do not clash.
if [ -n "${FLASHROM_CONTAINER_IMAGE:-}" ]; then
	PCIUTILS_PREFIX="${SCRIPT_DIR}/deps/pciutils-${PCIUTILS_VERSION}-$(container_tag_suffix "$FLASHROM_CONTAINER_IMAGE")"
else
	PCIUTILS_PREFIX="${SCRIPT_DIR}/deps/pciutils-${PCIUTILS_VERSION}"
fi
PCIUTILS_SRC="${SCRIPT_DIR}/deps/pciutils-src"
PCIUTILS_PC="${PCIUTILS_PREFIX}/lib/pkgconfig"

ensure_pinned_libpci() {
	local version
	if [ -e "${PCIUTILS_PREFIX}/lib/libpci.so.3" ] && [ -f "${PCIUTILS_PC}/libpci.pc" ]; then
		version="$(PKG_CONFIG_PATH="${PCIUTILS_PC}" pkg-config --modversion libpci 2>/dev/null || true)"
		if [ "$version" = "$PCIUTILS_VERSION" ]; then
			echo "Using pinned libpci ${version} at ${PCIUTILS_PREFIX}"
			return 0
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

ensure_pinned_libpci
export PKG_CONFIG_PATH="${PCIUTILS_PC}:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/local/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH="${PCIUTILS_PREFIX}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Clean if requested (host path; container path already cleaned before docker run)
if [ "$CLEAN" = true ]; then
	echo "Cleaning build directory..."
	rm -rf builddir
fi

# rpath $ORIGIN so a shipped flashrom + libpci.so.3 in the same dir work on older hosts
MESON_OPTS=(-Dc_link_args='-Wl,-rpath,$ORIGIN')
# Container/redistributable builds: skip RPMC (needs OpenSSL >=3).
if [ "${FLASHROM_DISABLE_RPMC:-0}" = "1" ] || [ -n "${FLASHROM_CONTAINER_IMAGE:-}" ]; then
	MESON_OPTS+=(-Drpmc=disabled)
fi
if [ -n "$PROGRAMMER_LIST" ]; then
	MESON_OPTS+=("-Dprogrammer=${PROGRAMMER_LIST}")
	echo "Building with programmers: $PROGRAMMER_LIST"
fi

echo "libpci via pkg-config: $(pkg-config --modversion libpci) ($(pkg-config --libs libpci))"
if [ -n "${FLASHROM_CONTAINER_IMAGE:-}" ]; then
	echo "Container image: ${FLASHROM_CONTAINER_IMAGE}"
	echo "Host glibc: $(ldd --version 2>&1 | head -1)"
fi

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
if [ -n "${FLASHROM_CONTAINER_IMAGE:-}" ]; then
	echo "  glibc:  $(ldd --version 2>&1 | head -1)"
	echo "  GLIBC symbols required:"
	objdump -T builddir/flashrom | grep -oE 'GLIBC_[0-9.]+' | sort -Vu | sed 's/^/    /'
fi
echo "Binaries located at:"
echo "  - builddir/flashrom"
echo "  - builddir/libflashrom.so"
echo "  - builddir/libpci.so* (pinned ${PCIUTILS_VERSION}; ship with flashrom)"
echo ""
echo "Verify: ldd builddir/flashrom | grep libpci"
