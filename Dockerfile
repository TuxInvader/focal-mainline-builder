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
    cmake libbpfcc-dev elfutils libdw-dev libdw1 pkg-config git-buildpackage \
  && apt-get remove --purge --auto-remove -y && rm -rf /var/lib/apt/lists/*

# Build dwarves 1.21 with ftrace patch for 5.13 compatability
RUN mkdir /dwarves && cd /dwarves \
  && wget http://mirrors.kernel.org/ubuntu/pool/universe/libb/libbpf/libbpf-dev_0.1.0-1_amd64.deb \
  && wget http://mirrors.kernel.org/ubuntu/pool/universe/libb/libbpf/libbpf0_0.1.0-1_amd64.deb \
  && dpkg -i libbpf-dev_0.1.0-1_amd64.deb libbpf0_0.1.0-1_amd64.deb\
  && rm libbpf-dev_0.1.0-1_amd64.deb libbpf0_0.1.0-1_amd64.deb \
  && wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/dwarves-dfsg/1.21-0ubuntu1/dwarves-dfsg_1.21.orig.tar.xz \
  && wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/dwarves-dfsg/1.21-0ubuntu1/dwarves-dfsg_1.21-0ubuntu1.debian.tar.xz \
  && wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/dwarves-dfsg/1.21-0ubuntu1/dwarves-dfsg_1.21-0ubuntu1.dsc \
  && dpkg-source -x dwarves-dfsg_1.21-0ubuntu1.dsc \
  && cd dwarves-dfsg-1.21/ \
  && sed -i -re 's/Build-Depends:.*/Build-Depends: debhelper-compat (= 12), cmake (>= 2.4.8), zlib1g-dev, libelf-dev, libdw-dev (>= 0.141), pkg-config,/' debian/control \
  && dpkg-buildpackage \
  && dpkg -i /dwarves/dwarves_1.21-0ubuntu1_amd64.deb \
  && rm -rf dwarves-dfsg-1.21 dwarves_1.21-0ubuntu1_amd64.deb

COPY build.sh /build.sh

ENTRYPOINT ["/build.sh"]
CMD ["--update=yes", "--btype=binary"]
