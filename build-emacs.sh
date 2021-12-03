#!/bin/sh

## Derived from https://github.com/renard/emacs-build-macosx
## Patches from https://github.com/d12frosted/homebrew-emacs-plus
## See also https://github.com/jimeh/build-emacs-for-macos

set -e

ROOT_DIR="`pwd`"
BUILD_DIR=/tmp/emacs-build
SRC_DIR=emacs-git

## Use Homebrew libxml
export LDFLAGS="-L/opt/homebrew/opt/libxml2/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libxml2/include"

## Start with a clean build
rm -rf ${BUILD_DIR}
mkdir ${BUILD_DIR}

cd ${SRC_DIR}

## Input for version otherwise default to master
if test -n "$1"; then
    commit="$1"
else
    commit="origin/master"
    git pull
fi

git archive --format tar $commit | tar -C ${BUILD_DIR} -xvf -

REV=`git log -n 1 --no-color --pretty='format:%h' ${commit}`
TIMESTAMP=`git log -n 1 --no-color --pretty='format:%at' ${commit}`
PATCH_LIST=`find ${ROOT_DIR}/patches/ -name '*.patch'`
cd ${BUILD_DIR}

## Apply Patches
echo "######### Applying patches #########"
for f in ${PATCH_LIST}; do
    echo "Applying patch `basename $f`"
    patch -p1 -i $f
done

STRINGS="
  nextstep/templates/Emacs.desktop.in
  nextstep/templates/Info-gnustep.plist.in
  nextstep/templates/Info.plist.in
  nextstep/templates/InfoPlist.strings.in"

DAY=`date -u -r $TIMESTAMP +"%Y-%m-%d_%H-%M-%S"`
ORIG=`grep ^AC_INIT configure.ac`
VNUM=`echo $ORIG | sed 's#^AC_INIT(\(.*\))#\1#; s/ //g' | cut -f2 -d,`
VERS="$DAY Git $REV"
DESCR="Emacs_Cocoa_${VNUM}_${DAY}_Git_${REV}"

## Autogen/copy_autogen
echo "######### Run autogen.sh #########"
./autogen.sh

## Use Homebrew libxml pkgconfig
export PKG_CONFIG_PATH="/opt/homebrew/opt/libxml2/lib/pkgconfig"

for f in $STRINGS; do
    sed -e "s/@version@/@version@ $VERS/" -i '' $f
done

## Configure emacs
echo "######### Configure Emacs build flags #########"
./configure \
    --without-dbus \
    --with-native-compilation \
    --with-xwidgets \
    --with-mailutils \


## Build and install everything
echo "####### Build and install everything ########"
make
make install
trash /Applications/Emacs.app # trash old emacs
mv ${BUILD_DIR}/nextstep/Emacs.app /Applications # move to applications folder

echo "## Change icon"
cp ~/Pictures/emacs-icons/emacs-big-sur.icns /Applications/Emacs.app/Contents/Resources/Emacs.icns
# cp ~/Pictures/emacs-icons/info.plist /Applications/Emacs.app/Contents/Info.plist

echo "####### Open new emacs #######"
open /Applications/Emacs.app

echo "######## Cleanup ########"
rm -rf ${BUILD_DIR}
rm -rf tmp.dmg
