# Builder for Ubuntu Mainline kernels

This container will build a mainline kernel from the Ubuntu source tree.
By default the container will build binary packages which you can then install
on your systems. You can optionally build a metapackage to track a build flavour,
and major release of kernel (eg 5.12.x).

If you build the metapackage it will have a name like: 
`linux-generic-5.12` and will depend on the version of `5.12.x` you are building.

Alternatively it can build signed source packages for uploading to a PPA.

I upload my mainline kernels to these PPAs

| Kernel Version | Series | PPA Link | Packages |
|----------------|--------|----------|----------|
| mainline/stable | focal |[lts-mainline PPA](https://launchpad.net/~tuxinvader/+archive/ubuntu/lts-mainline)|[lts-mainline Packages](https://launchpad.net/~tuxinvader/+archive/ubuntu/lts-mainline/+packages)|
| mainline/stable | jammy |[jammy-mainline PPA](https://launchpad.net/~tuxinvader/+archive/ubuntu/jammy-mainline)|[lts-mainline Packages](https://launchpad.net/~tuxinvader/+archive/ubuntu/jammy-mainline/+packages)|
|longterm | focal |[lts-mainline-longterm PPA](https://launchpad.net/~tuxinvader/+archive/ubuntu/lts-mainline-longterm)|[lts-mainline-longterm Packages](https://launchpad.net/~tuxinvader/+archive/ubuntu/lts-mainline-longterm/+packages)|

## building the container

To build the container with `docker` you would use:
```
docker build -t <org>/<image>:<tag> -f Dockerfile.<series> .
```

I build and push the Jammy series image using:

```
docker build -t tuxinvader/jammy-mainline-builder:latest -f Dockerfile.jammy .
docker push tuxinvader/jammy-mainline-builder:latest
```

and focal with:
```
docker build -t tuxinvader/focal-mainline-builder:latest -f Dockerfile.focal .
docker push tuxinvader/focal-mainline-builder:latest
```

## Usage

1. Checkout the Mainline kernel from Ubuntu
```
sudo mkdir -p /usr/local/src/cod/
sudo chown $(whoami) /usr/local/src/cod
```

  * Download the full source tree, if you want to be able to build any kernel (including previous releases)
  ```
  git clone git://git.launchpad.net/~ubuntu-kernel-test/ubuntu/+source/linux/+git/mainline-crack \
    /usr/local/src/cod/mainline
  ```

  * Download a specific kernel version if you only need to build this version. Eg v5.12.4:
  ```
  git clone --depth=1 -b cod/mainline/v5.12.4 \
    git://git.launchpad.net/~ubuntu-kernel-test/ubuntu/+source/linux/+git/mainline-crack \
    /usr/local/src/cod/mainline
  ```
  You should also pass `--update=no` when checking out only a single release.

2. Create a directory to receive the Debian packages
```
mkdir /usr/local/src/cod/debs
```

3. Run the container

Launch the container with two volume mounts, one to the source code downloaded above, and the
other for the deb packages to be copied into.

*Binary debs*
```
sudo docker run -ti -e kver=v5.12.1 -v /usr/local/src/cod/mainline:/home/source \
     -v /usr/local/src/cod/debs:/home/debs --rm tuxinvader/focal-mainline-builder:latest
```
Go and make a nice cup-of-tea while your kernel is built. 

If you want to build a signed source package, you need to also provide your GPG keyring:

*Signed Source package*
```
sudo docker run -ti -e kver=v5.12.1 -v /usr/local/src/cod/mainline:/home/source \
     -v /usr/local/src/cod/debs:/home/debs -v ~/.gnupg:/root/keys \
     --rm tuxinvader/focal-mainline-builder:latest --btype=source --sign=<SECRET_KEY_ID> \
     --flavour=generic --exclude=cloud-tools,udebs --rename=yes
```

*Build and sign metapackage*
```
sudo docker run -ti -e kver=v5.12.1 -v /usr/local/src/cod/mainline:/home/source \
     -v /usr/local/src/cod/debs:/home/debs -v ~/.gnupg:/root/keys \
     --rm tuxinvader/focal-mainline-builder:latest --btype=source --sign=<SECRET_KEY_ID> \
     --flavour=generic --exclude=cloud-tools,udebs --rename=yes --buildmeta=yes \
     --maintainer="Zaphod <zaphod@betelgeuse-seven.western-spiral-arm.milkyway>"
```

The Linux source package builds some debs which are linked (by name) against the kernel and some
which are common. Using `--rename=yes` allows us to store multiple kernels in the same PPA by changing
the name of the source package and the linking all binaries (by name) to a specific kernel.

### Notes

Set the `kver` variable to the version of the kernel you want to build
(from here: https://kernel.ubuntu.com/~kernel-ppa/mainline/?C=N;O=D)

The built packages or source files will be placed in the mounted volume at `/home/debs`,
which is `/usr/local/src/cod/debs` if you've followed the example.

The container will do an update in the source code repository when it runs,
if the tree is already up-to-date then you can append `--update=no` to the
`docker run` command to skip that step.

## Flavour lowlatency removed

With kernel 5.16.12 the mainline kernel discontinued the lowlatency flavour. So, the default build now
only builds the `generic` flavour on 5.16.12+. The build script has been updated to recreate lowlatency
options, but only if you specify that with `--flavour=lowlatency`.

## Additional options

* Update: You can pass `--update=[yes|no]` to have the container perform a 
`git pull` before building the kernel. Default is `yes`

* Shell: You can pass `--shell=[yes|no]` to launch a bash shell before and
after the build process. Default is `no`

* Build Type: You can pass `--btype=[binary,source,any,all,full]` to chose
the type of build performed. Default is `binary`.

* Customize: You can pass `--custom=[yes|no]` to run `make menuconfig` before the
the build process. Default is `no`

* Sign: You can pass `--sign=<secret-key-id>` to sign source packages ready for uploading
to a PPA. Default is `no`. You'll also need to mount your GPG keys into the container.
Eg: `-v ~/.gnupg:/root/keys` and specify `--btype=source`

* Flavour: You can pass `--flavour=[generic|lowlatency]` if you want to select the build
flavour. The default is `none`, and we build the generic flavour (since 5.16.12+).

* Exclude: You can pass `--exclude=[cloud-tools,udebs]` to exclude one or more packages.
Default is `none`.

* Rename: You can pass `--rename=[yes|no]` to rename the source package to be kernel release specific.
This enables hosting multiple kernels in the same PPA. Use with `--exclude=tools,udebs` to stop
duplicate packages being built. Default is `no`

* Series: You can pass `--series=[focal|groovy|...]` to set the ubuntu version you're building
  for. Default is `focal`

* Patch: You can pass a patch version to apply upstream patch to the ubuntu kernel.
  Eg `--patch=v5.11.21` to patch v5.11.20 upto v5.11.21. Default is `no`

* Check bugs: You can pass `--checkbugs=yes` to work around any known bugs, currently this is required
to build older 5.10.x and 5.11.x kernels see bug #4

* Maintainer: If you want to sign the metapackage (for PPA upload), then you need to provide the details of your
signing key by passing `--maintainer="Me <me@mine.org>"`

* Debug Symbols: If you want to package a version of the kernel which includes debug-symbols,
then pass `--debug=yes` to the binary build.

* Build metapackage: You can pass `--buildmeta=[yes|no]` to build a metapackage named `linux-<flavour>-<major version>`
that will depend on the kernel you are building. This makes it easy to track the latest release and auto-update
using apt.

* Meta Only: You can decide to just rebuild the metapackage by passing `--metaonly=yes`, useful for rolling back a release
  should it fail to build.

* Meta Time: The source (orig.tar.gz) tarball is immutable on launchpad, so we need to ensure the ordering, contents, and
  modification times match on every build. The timestamp defaults to "2023-01-01 00:00:00", but you can override it with
  `--metatime=<epoch-seconds>`

* Meta Version: We now append `-n` to meta-packages so that we can republish/rebuild them on launchpad by incrementing
  the version. You also need to ensure the metatime is consistent, else the orig.tar.gz will be rejected. The version
  defaults to 0, eg linux 6.1.0 would be linux-generic-6.01_6.1.0-0, passing `--metaver=1` would result in 
  linux-generic-6.01_6.1.0-1
