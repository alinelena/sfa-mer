#!/bin/bash
TOOLDIR="$(dirname $0)"
source "$TOOLDIR/utility-functions.inc"

# Carries the sequence of steps under the Mer SDK.
# - Set up Ubuntu for building CyanogenMod.
#   I'm highly suspicious this step could just as well be done on Mer SDk itself but lets leave it for another time..
# - Set up Scratchbox2 for crosscompiling
# - Build the droid-hal, the middleware & friends, and finally,
# - Build the image!
[ -z "$MERSDK" ] && ${TOOLDIR}/exec-mer.sh $0
[ -z "$MERSDK" ] && exit 0

source ~/.hadk.env
[[ -f $TOOLDIR/proxy ]] && source $TOOLDIR/proxy
[[ ! -z  $http_proxy ]] && proxy="http_proxy=$http_proxy"
mchapter "4.3"
sudo $proxy zypper -n install zip android-tools createrepo || die

minfo "setting up ubuntu chroot"
UBUNTU_CHROOT="$MER_ROOT/sdks/ubuntu"
mkdir -p "$UBUNTU_CHROOT"

mchapter "4.4.1"
pushd "$MER_ROOT"
TARBALL=ubuntu-trusty-android-rootfs.tar.bz2
[ -f $TARBALL  ] || curl -O http://img.merproject.org/images/mer-hybris/ubu/$TARBALL
set -x
minfo "untaring ubuntu..."
[ -f ${TARBALL}.untarred ] || sudo tar --numeric-owner -xjf $TARBALL -C "$UBUNTU_CHROOT" || die
touch ${TARBALL}.untarred

mchapter "4.4.2"
grep $(hostname) "$UBUNTU_CHROOT/etc/hosts" || sudo sh -c "echo 127.0.0.2 $(hostname) >> \"$UBUNTU_CHROOT/etc/hosts\""

popd

cd ${TOOLDIR}
# replace the shoddy ubu-chroot script
sudo cp $TOOLDIR/ubu-chroot-fixed-cmd-mode `which ubu-chroot` || die
sudo chmod +x `which ubu-chroot` || die

minfo "diving into ubuntu chroot"
ubu-chroot -r "$MER_ROOT/sdks/ubuntu" `pwd`/task-ubu.sh || die
minfo "done ubuntu"

mchapter "6. sb2 setup"
./sb-setup.sh || die

./ahal.sh || die

./build-img.sh || die

