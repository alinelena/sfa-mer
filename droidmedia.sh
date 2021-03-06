#!/bin/bash

# Build droid-hal and other middleware
# To be executed under the Mer SDK


[ -z "$MERSDK" ] && $(dirname $0)/exec-mer.sh $0
[ -z "$MERSDK" ] && exit 0

source ~/.hadk.env
[[ -z $1 ]] && ver=0.0.0 || ver=$1
cd $ANDROID_ROOT
echo "building droidmedia version $ver"
sh pack-droidmedia.sh $ver

    PKG=droidmedia
    echo -e "\e[01;32m Info: build $PKG\e[00m"
    SPEC=$PKG
    mkdir -p $MER_ROOT/devel/droidmedia
    mkdir -p $MER_ROOT/devel/droidmedia/rpm
    
    cd $MER_ROOT/devel/droidmedia
    cp $ANDROID_ROOT/${PKG}-$ver.tgz .
    cp $ANDROID_ROOT/external/droidmedia/rpm/$PKG.spec rpm/
    sed -i "s;armv7hl;$ARCH;g" rpm/$PKG.spec
    sed -i "s;XXX;$ver;g" rpm/$PKG.spec

    echo -e "\e[01;32m Info: mb2 -s rpm/$PKG.spec -t $VENDOR-$DEVICE-$ARCH build &> $PKG.log \e[00m"
    mb2 -s rpm/$PKG.spec -t $VENDOR-$DEVICE-$ARCH build &> $ANDROID_ROOT/$PKG.log 
    cd $ANDROID_ROOT
    mkdir -p droid-local-repo/$DEVICE
    rm -f droid-local-repo/$DEVICE/$PKG-*.rpm
    cp $MER_ROOT/devel/droidmedia/RPMS/*.rpm droid-local-repo/$DEVICE/
