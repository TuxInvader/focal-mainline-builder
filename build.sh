#!/bin/bash

export LANG=C

update=yes
btype=binary
shell=no
custom=no
sign=no
buildargs="-aamd64 -d"

args=( $@ );
for (( i=0; $i < $# ; i++ ))
do
  [[ "${args[$i]}" =~ --update.* ]] && update=${args[$i]#*=} && continue
  [[ "${args[$i]}" =~ --btype.* ]] && btype=${args[$i]#*=} && continue
  [[ "${args[$i]}" =~ --shell.* ]] && shell=${args[$i]#*=} && continue
  [[ "${args[$i]}" =~ --custom.* ]] && custom=${args[$i]#*=} && continue
  [[ "${args[$i]}" =~ --sign.* ]] && sign=${args[$i]#*=} && continue
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

if [ "$shell" == "yes" ]
then
  echo -e "********\n\nPre-build shell, exit or ctrl-d to continue build\n\n********"
  bash
fi

echo -e "********\n\nCleaning git source tree\n\n********"
git clean -fdx
git reset --hard HEAD

if [ "$update" == "yes" ]
then
  echo -e "********\n\nUpdating git source tree\n\n********"
  git checkout master
  git fetch --tags origin 
  git pull
fi

# checkout the kver
echo -e "********\n\nSwitching to cod/mainline/${kver} branch\n\n********"
git checkout "cod/mainline/${kver}"

# prep
echo -e "********\n\nApplying default configs\n\n********"
sed -i -re 's/hirsute/focal/g' debian.master/changelog
sed -i -re 's/dwarves/dwarves (>=1.17-1)/g' debian.master/control.stub.in
fakeroot debian/rules clean defaultconfigs
fakeroot debian/rules clean


if [ "$custom" == "yes" ]
then
  echo -e "********\n\nYou have asked for a custom build.\nYou will be given the chance to makemenuconfig next.\n\n********"
  read -p 'Press return to continue...' foo
  fakeroot debian/rules editconfigs
fi

# Build
echo -e "********\n\nBuilding packages\nCommand: dpkg-buildpackage --build=$btype $buildargs\n\n********"
dpkg-buildpackage --build=$btype $buildargs
#AUTOBUILD=1 fakeroot debian/rules binary-debs
#AUTOBUILD=1 NOEXTRAS=1 fakeroot debian/rules binary-FLAVOUR

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
git checkout master

