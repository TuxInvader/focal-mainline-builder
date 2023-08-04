DISABLED=(CONFIG_DEBUG_INFO_BTF CONFIG_MODVERSIONS CONFIG_HAVE_GCC_PLUGINS)
ENABLED=(CONFIG_RUST CONFIG_SAMPLES_RUST CONFIG_SAMPLE_RUST_HOSTPROGS)
MODULES=(CONFIG_SAMPLE_RUST_MINIMAL CONFIG_SAMPLE_RUST_PRINT)

annotations=debian.master/config/annotations

for config in ${DISABLED[@]}
do
  egrep "^$config" "$annotations" > /dev/null
  if [ $? -eq 0 ]
  then
    sed -i $annotations -re "s/^$config.*/$config    policy<{'amd64': 'n', 'arm64': 'n', 'armhf': 'n', 'ppc64el': 'n', 'riscv64': 'n', 's390x': 'n'}>"
  else
    echo "$config    policy<{'amd64': 'n', 'arm64': 'n', 'armhf': 'n', 'ppc64el': 'n', 'riscv64': 'n', 's390x': 'n'}>" >> $annotations
  fi
done

for config in ${ENABLED[@]}
do
  egrep "^$config" "$annotations" > /dev/null
  if [ $? -eq 0 ]
  then
    sed -i $annotations -re "s/^$config.*/$config    policy<{'amd64': 'y', 'arm64': 'y', 'armhf': 'y', 'ppc64el': 'y', 'riscv64': 'y', 's390x': 'y'}>"
  else
    echo "$config    policy<{'amd64': 'y', 'arm64': 'y', 'armhf': 'y', 'ppc64el': 'y', 'riscv64': 'y', 's390x': 'y'}>" >> $annotations
  fi
done

for config in ${modules[@]}
do
  egrep "^$config" "$annotations" > /dev/null
  if [ $? -eq 0 ]
  then
    sed -i $annotations -re "s/^$config.*/$config    policy<{'amd64': 'm', 'arm64': 'm', 'armhf': 'm', 'ppc64el': 'm', 'riscv64': 'm', 's390x': 'm'}>"
  else
    echo "$config    policy<{'amd64': 'm', 'arm64': 'm', 'armhf': 'm', 'ppc64el': 'm', 'riscv64': 'm', 's390x': 'm'}>" >> $annotations
  fi
done

