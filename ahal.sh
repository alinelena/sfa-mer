#!/bin/bash
TOOLDIR="$(dirname `which $0`)"
source "$TOOLDIR/utility-functions.inc"

# Build droid-hal and other middleware
# To be executed under the Mer SDK


[ -z "$MERSDK" ] && ${TOOLDIR}/exec-mer.sh $0
[ -z "$MERSDK" ] && exit 0

source ~/.hadk.env
[[ -f $TOOLDIR/proxy ]] && source $TOOLDIR/proxy
[[ ! -z  $http_proxy ]] && proxy="http_proxy=$http_proxy"

mchapter "5.1 version b"
if [ ! -d "$ANDROID_ROOT/rpm" ]; then
  pushd "$ANDROID_ROOT"
  modular=$(git ls-remote git://github.com/mer-hybris/droid-hal-$DEVICE | grep "HEAD" | awk '{print $2}')
  if [[ x"$modular" == "xHEAD" ]]; then
    git clone git://github.com/mer-hybris/droid-hal-$DEVICE rpm
  else
    git clone git://github.com/mer-hybris/droid-hal-device rpm
  fi
  popd
else
  pushd "$ANDROID_ROOT/rpm"
  git pull
  popd
fi

cd $ANDROID_ROOT

mchapter "7.1.1"

minfo "updating mer sdk"
sudo $proxy zypper ref -f ; sudo $proxy zypper -n dup

if repo_is_set "$EXTRA_REPO"; then
  minfo "Add remote extra repo"
  sb2 -t $VENDOR-$DEVICE-$ARCH -R -m sdk-install ssu ar extra-$DEVICE $EXTRA_REPO
fi
if repo_is_set "$MW_REPO"; then
  minfo "Add remote mw repo"
  sb2 -t $VENDOR-$DEVICE-$ARCH -R -m sdk-install ssu ar mw-$DEVICE-hal $MW_REPO
fi
set -x
if repo_is_set "$DHD_REPO"; then
  minfo "Add remote dhd repo"
  sb2 -t $VENDOR-$DEVICE-$ARCH -R -m sdk-install ssu ar dhd-$DEVICE-hal $DHD_REPO
  sb2 -t $VENDOR-$DEVICE-$ARCH -R -m sdk-install zypper clean -a 
  sb2 -t $VENDOR-$DEVICE-$ARCH -R -m sdk-install zypper ref -f
  sb2 -t $VENDOR-$DEVICE-$ARCH -R -m sdk-install zypper -n install droid-config-$DEVICE-ssu-kickstarts
else
  if [[ ! -d rpm/dhd ]]; then 
    if [[ -d hybris/dhd2modular ]] ; then 
        pushd hybris/dhd2modular
        git pull 
        popd
    else
        pushd hybris
        git clone https://github.com/mer-hybris/dhd2modular
        popd
    fi  
    hybris/dhd2modular/dhd2modular.sh migrate 2>&1 | tee $ANDROID_ROOT/dhd.migrate.log
  fi
  cp $TOOLDIR/pack-droidmedia.sh $ANDROID_ROOT/
  cp $TOOLDIR/droidmedia.spec $ANDROID_ROOT/external/droidmedia/rpm/
  sh  $TOOLDIR/droidmedia.sh 0.0.0.$(date +%Y%m%d%H%M)
  mkdir -p droid-local-repo/$DEVICE
  pushd rpm/dhd; git stash; git pull github master; popd
  sed -i "/rm \-rf \$RPM_BUILD_ROOT$/a rm -f out/target/product/*/system/lib/libdroidmedia.so" rpm/dhd/droid-hal-device.inc
  sed -i "/rm \-rf \$RPM_BUILD_ROOT$/a rm -f out/target/product/*/system/bin/minimediaservice" rpm/dhd/droid-hal-device.inc
  sed -i "/rm \-rf \$RPM_BUILD_ROOT$/a rm -f out/target/product/*/system/bin/minisfservice" rpm/dhd/droid-hal-device.inc

  cp $TOOLDIR/pack-audioflingerglue.sh $ANDROID_ROOT/
  cp $TOOLDIR/audioflingerglue.spec $ANDROID_ROOT/external/audioflingerglue/rpm/
  sh  $TOOLDIR/af.sh 0.0.1.$(date +%Y%m%d%H%M)
  sed -i "/rm \-rf \$RPM_BUILD_ROOT$/a rm -f out/target/product/*/system/lib/libaudioflingerglue.so" rpm/dhd/droid-hal-device.inc
  sed -i "/rm \-rf \$RPM_BUILD_ROOT$/a rm -f out/target/product/*/system/bin/miniafservice" rpm/dhd/droid-hal-device.inc

  sed -i "/local_hadk_build_project/d" rpm/droid-hal-hammerhead.spec
  sed -i "/enable_kernel_update/a %define local_hadk_build_project 1" rpm/droid-hal-hammerhead.spec
  rpm/dhd/helpers/build_packages.sh 
  pushd $TOOLDIR
  ./gst-droid.sh
  ./pulse.sh
  popd
createrepo $ANDROID_ROOT/droid-local-repo/$DEVICE
sb2 -t $VENDOR-$DEVICE-armv7hl -R -msdk-install zypper ref
fi
