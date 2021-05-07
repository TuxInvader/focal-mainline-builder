#!/bin/bash

export LANG=C

update=no

args=( $@ );
for (( i=0; $i < $# ; i++ ))
do
  [[ "${args[$i]}" =~ --update.* ]] && update=${args[$i]#*=} && continue
done

cd $ksrc

if [ "$update" == "yes" ]
then
  git checkout master
  git pull
fi

git checkout "cod/mainline/${kver}"
fakeroot debian/rules clean
dpkg-buildpackage -uc -ui -aamd64 -b -d

mv "$ksrc/../*.deb" "$kdeb"


