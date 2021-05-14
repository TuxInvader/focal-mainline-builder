#!/bin/bash

export LANG=C

update=yes
btype=binary
shell=no
custom=no
sign=no
flavour=none
exclude=none
rename=no
buildargs="-aamd64 -d"

args=( $@ );
for (( i=0; $i < $# ; i++ ))
do
  [[ "${args[$i]}" =~ --update.* ]] && update=${args[$i]#*=} && continue
  [[ "${args[$i]}" =~ --btype.* ]] && btype=${args[$i]#*=} && continue
  [[ "${args[$i]}" =~ --shell.* ]] && shell=${args[$i]#*=} && continue
  [[ "${args[$i]}" =~ --custom.* ]] && custom=${args[$i]#*=} && continue
  [[ "${args[$i]}" =~ --sign.* ]] && sign=${args[$i]#*=} && continue
  [[ "${args[$i]}" =~ --flavour.* ]] && flavour=${args[$i]#*=} && continue
  [[ "${args[$i]}" =~ --exclude.* ]] && exclude=${args[$i]#*=} && continue
  [[ "${args[$i]}" =~ --rename.* ]] && rename=${args[$i]#*=} && continue
done

if [ "$sign" == "no" ]
then
  buildargs="$buildargs -uc -ui -us"
else
  buildargs="$buildargs -sa --sign-key=${sign}"
  cp -rp /root/keys /root/.gnupg
  chown -R root:root /root/.gnupg
  chmod 700 /root/.gnupg
fi

cd $ksrc

echo -e "********\n\nCleaning git source tree\n\n********"
git clean -fdx
git reset --hard HEAD

if [ "$update" == "yes" ]
then
  echo -e "********\n\nUpdating git source tree\n\n********"
  git fetch --tags origin 
fi

# checkout the kver
echo -e "********\n\nSwitching to cod/mainline/${kver} branch\n\n********"
git checkout "cod/mainline/${kver}"

# prep
echo -e "********\n\nRenaming source package and updating control files\n\n********"
debversion=$(date +%Y%m%d%H%M)
if [ "$rename" == "yes" ]
then
  sed -i -re "s/(^linux) \(([0-9]+\.[0-9]+\.[0-9]+)-([0-9]+)\.[0-9]+\) ([^;]*)(.*)/linux-${kver:1} (\2-\3.${debversion}) focal\5/" debian.master/changelog
  sed -i -re 's/SRCPKGNAME/linux/g' debian.master/control.stub.in
  sed -i -re 's/SRCPKGNAME/linux/g' debian.master/control.d/flavour-control.stub
  sed -i -re "s/Source: linux/Source: linux-${kver:1}/" debian.master/control.stub.in
  sed -i -re "s/^(Package:\s+)(linux(-cloud[-tools]*|-tools)(-common|-host))$/\1\2-PKGVER/" debian.master/control.stub.in
  sed -i -re "s/^(Depends:\s+.*, )(linux(-cloud[-tools]*|-tools)(-common|-host))$/\1\2-PKGVER/" debian.master/control.stub.in
else
  sed -i -re "s/(^linux) \(([0-9]+\.[0-9]+\.[0-9]+)-([0-9]+)\.[0-9]+\) ([^;]*)(.*)/linux (\2-\3.${debversion}) focal\5/" debian.master/changelog
fi
sed -i -re 's/dwarves/dwarves (>=1.17-1)/g' debian.master/control.stub.in


if [ "$flavour" != "none" ]
then
  sed -i -re "s/(flavours\s+=).*/\1 $flavour/" debian.master/rules.d/amd64.mk
fi

if [ "$exclude" != "none" ]
then
  IFS=',' read -ra pkgs <<< "$exclude"
  for pkg in "${pkgs[@]}"
  do
    if [ "$pkg" == "cloud-tools" ]
    then
      sed -i -re "s/(do_tools_hyperv\s+=).*/\1 false/" debian.master/rules.d/amd64.mk
    elif [ "$pkg" == "tools" ]
    then
      # This doesn't work. We'll rename tools packages instead
      sed -i -re "s/^(do_tools_)((common|host)\s+=).*/\1\2 false/" debian.master/rules.d/amd64.mk
      echo "do_linux_tools  = false" >> debian.master/rules.d/amd64.mk
    elif [ "$pkg" == "udebs" ]
    then
      echo "disable_d_i     = true" >> debian.master/rules.d/amd64.mk
    fi
  done
fi

echo -e "********\n\nApplying default configs\n\n********"
fakeroot debian/rules clean defaultconfigs
fakeroot debian/rules clean

if [ "$shell" == "yes" ]
then
  echo -e "********\n\nPre-build shell, exit or ctrl-d to continue build\n\n********"
  bash
fi

if [ "$custom" == "yes" ]
then
  echo -e "********\n\nYou have asked for a custom build.\nYou will be given the chance to makemenuconfig next.\n\n********"
  read -p 'Press return to continue...' foo
  fakeroot debian/rules editconfigs
fi

# Build
echo -e "********\n\nBuilding packages\nCommand: dpkg-buildpackage --build=$btype $buildargs\n\n********"
dpkg-buildpackage --build=$btype $buildargs

echo -e "********\n\nMoving packages to debs folder\n\n********"
[ -d "$kdeb/$kver" ] || mkdir $kdeb/$kver
mv $ksrc/../*.* $kdeb/$kver

if [ "$shell" == "yes" ]
then
  echo -e "********\n\nPost-build shell, exit or ctrl-d to finish\n\n********"
  bash
fi

echo -e "********\n\nCleaning git source tree\n\n********"
git clean -fdx
git reset --hard HEAD

