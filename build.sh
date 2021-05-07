#!/bin/bash

export LANG=C

update=yes
btype=binary
shell=no

args=( $@ );
for (( i=0; $i < $# ; i++ ))
do
  [[ "${args[$i]}" =~ --update.* ]] && update=${args[$i]#*=} && continue
  [[ "${args[$i]}" =~ --btype.* ]] && btype=${args[$i]#*=} && continue
  [[ "${args[$i]}" =~ --shell.* ]] && shell=${args[$i]#*=} && continue
done

cd $ksrc

if [ "$shell" == "yes" ]
then
  echo -e "********\n\nPre-build shell, exit or ctrl-d to continue build\n\n********"
  bash
fi

git clean -fdx
git reset --hard HEAD

if [ "$update" == "yes" ]
then
  git checkout master
  git pull
fi

# checkout the kver
git checkout "cod/mainline/${kver}"

# prep
fakeroot debian/rules clean defaultconfigs
fakeroot debian/rules clean

# Build
dpkg-buildpackage -uc -ui -us -aamd64 -d --build=$btype
#AUTOBUILD=1 fakeroot debian/rules binary-debs
#AUTOBUILD=1 NOEXTRAS=1 fakeroot debian/rules binary-FLAVOUR

mv $ksrc/../*.* $kdeb

if [ "$shell" == "yes" ]
then
  echo -e "********\n\nPost-build shell, exit or ctrl-d to finish\n\n********"
  bash
fi


