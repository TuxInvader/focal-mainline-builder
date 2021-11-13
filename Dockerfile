FROM ubuntu:focal

# Version of kernel to build. We'll checkout cod/mainline/$kver
ENV kver=v5.12.1

# The source tree from git://git.launchpad.net/~ubuntu-kernel-test/ubuntu/+source/linux/+git/mainline-crack
ENV ksrc=/home/source

# The packages will be placed here
ENV kdeb=/home/debs

ARG DEBIAN_FRONTEND=noninteractive

# Install Build Dependencies
RUN set -x \
  && apt-get update && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
    autoconf automake autopoint autotools-dev bsdmainutils debhelper dh-autoreconf git fakeroot\
    dh-strip-nondeterminism distro-info-data dwz file gettext gettext-base groff-base \
    intltool-debian libarchive-zip-perl libbsd0 libcroco3 libdebhelper-perl libelf1 libexpat1 \
    libfile-stripnondeterminism-perl libglib2.0-0 libicu66 libmagic-mgc libmagic1 libmpdec2 \
    libpipeline1 libpython3-stdlib libpython3.8-minimal libpython3.8-stdlib libsigsegv2 \
    libssl1.1 libsub-override-perl libtool libuchardet0 libxml2 \
    lsb-release m4 man-db mime-support po-debconf python-apt-common python3 python3-apt \
    python3-minimal python3.8 python3.8-minimal sbsigntool tzdata dctrl-tools kernel-wedge \
    libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev \
    libiberty-dev autoconf bc build-essential libusb-1.0-0-dev libhidapi-dev curl wget \
    cpio makedumpfile libcap-dev libnewt-dev libdw-dev rsync gnupg2 ca-certificates\
    libunwind8-dev liblzma-dev libaudit-dev uuid-dev libnuma-dev lz4 xmlto equivs \
    cmake pkg-config zstd dwarves

COPY build.sh /build.sh

ENTRYPOINT ["/build.sh"]
CMD ["--update=yes", "--btype=binary"]
