# Builder for Ubuntu Mainline kernels

This container will build a mainline kernel from the Ubuntu source tree.

## Usage

1. Checkout the Mainline kernel from Ubuntu
```
sudo mkdir -p /usr/local/src/cod/
sudo chown $(whoami) /usr/local/src/cod
git clone git://git.launchpad.net/~ubuntu-kernel-test/ubuntu/+source/linux/+git/mainline-crack \
    /usr/local/src/cod/mainline
```

2. Create a directory to receive the debian packages
```
mkdir /usr/local/src/cod/debs
```

3. Run the container

Launch the container with two volume mounts, one to the source code downloaded above, and the
other for the deb packages to be copied into.

```
sudo docker run -ti -e kver=v5.12.1 -v /usr/local/src/cod/mainline:/home/source \
     -v /usr/local/src/cod/debs:/home/debs --rm tuxinvader/focal-mainline-builder:latest
```

Or if you want to build a signed source package:

```
sudo docker run -ti -e kver=v5.12.1 -v /usr/local/src/cod/mainline:/home/source \
     -v /usr/local/src/cod/debs:/home/debs -v ~/.gnupg:/root/keys \
     --rm tuxinvader/focal-mainline-builder:latest --btype=source --sign=<SECRET_KEY_ID>
```

Go and make a nice cup-of-tea while your kernel is built. 

Set the `kver` variable to the version of the kernel you want to build
(from here: https://kernel.ubuntu.com/~kernel-ppa/mainline/?C=N;O=D)

The built packages will be placed in the mounted volume at `/home/debs`, which
is `/usr/local/src/cod/debs` if you've followed the example.

The container will do an update in the source code repository when it runs,
if the tree is already up-to-date then you can append `--update=no` to the
`docker run` command to skip that step.

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
to a PPA. Default is `no`. You'll also need to mount your GPG keys into the cotainer.
Eg: `-v ~/.gnupg:/root/keys` and specify `--btype=source`


