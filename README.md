# Builder for Ubuntu Mainline kernels

This container will build a mainline kernel using a supplied Ubuntu source tree.

## Usage

1. Checkout the Mainline kernel from Ubuntu
```
sudo mkdir -p /usr/local/src/cod/
sudo chown $(whoami) /usr/local/src/cod
git clone git://git.launchpad.net/~ubuntu-kernel-test/ubuntu/+source/linux/+git/mainline-crack /usr/local/src/cod/mainline
```

2. Create a directory to receive the debian packages
```
mkdir /usr/local/src/cod/debs
```

3. Run the container
```
sudo docker run -ti -e kver=v5.12.1 -v /usr/local/src/cod/mainline:/home/source -v /usr/local/src/cod/debs:/home/debs tuxinvader/focal-mainline-builder:latest
```

Go and make a nice cup-of-tea while your kernel is built.

