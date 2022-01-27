#!/bin/sh

## Derived from https://github.com/renard/emacs-build-macosx
## Patches from https://github.com/d12frosted/homebrew-emacs-plus
## See also https://github.com/jimeh/build-emacs-for-macos

# ======================================================
# Uncomment `set -e' if you want script to exit
# on non-zero status
# See https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# ======================================================

# set -e

# ======================================================
# Set Variables
# ======================================================

ROOT_DIR="`pwd`"
BUILD_DIR=/tmp/emacs-build
SRC_DIR=emacs-git
GIT_VERSION=emacs-git-version.el
SITELISP=/Applications/Emacs.app/Contents/Resources/site-lisp
BREW=$(brew --prefix)

echo "
# ======================================================
# Use Homebrew libxml & image libraries
# ======================================================
"

# Check for Homebrew,
if ! command -v brew </dev/null 2>&1
then
   echo "Please install homebrew -- see bemacs-requirements.sh"
else
    echo "Homebrew installed!"
fi

export LDFLAGS="-L${BREW}opt/libxml2/lib -L${BREW}/opt/giflib/lib -L${BREW}/opt/jpeg/lib -L${BREW}/opt/libtiff/lib"

export CPPFLAGS="-I${BREW}/opt/libxml2/include -I${BREW}/opt/jpeg/include -I${BREW}/opt/libtiff/include -I${BREW}/opt/giflib/include"

echo "
# ======================================================
# Use Homebrew libxml pkgconfig
# ======================================================
"

export PKG_CONFIG_PATH="${BREW}/opt/libxml2/lib/pkgconfig"

echo "
# ======================================================
# Start with a clean build
# ======================================================
"

rm -rf ${BUILD_DIR}
mkdir ${BUILD_DIR}

cd ${SRC_DIR}

# ======================================================
# Input for version otherwise default to master
# ======================================================

if test -n "$1"; then
    commit="$1"
else
    commit="origin/master"
    git checkout master
    git pull
fi

git archive --format tar $commit | tar -C ${BUILD_DIR} -xvf -

# ======================================================
# Set variables for git, time, & patches
# ======================================================

REV=`git log -n 1 --no-color --pretty='format:%h' ${commit}`
TIMESTAMP=`git log -n 1 --no-color --pretty='format:%at' ${commit}`
PATCH_LIST=`find ${ROOT_DIR}/patches/ -name '*.patch'`
cd ${BUILD_DIR}

echo "
# ======================================================
# Apply Patches
# ======================================================
"

# Note that this applies all patches in 'patches' dir
for f in ${PATCH_LIST}; do
    echo "Applying patch `basename $f`"
    patch -p1 -i $f
done

# ======================================================
# Info settings
# ======================================================

# Here we set infofiles and variables for versioning

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

echo "
# ======================================================
# Autogen/copy_autogen
# ======================================================
"

# Generate config files
./autogen.sh

# ======================================================
# Set Compile Flags
# ======================================================

# Use Clang for slightly faster builds
# See https://leeifrankjaw.github.io/articles/clang_vs_gcc_for_emacs.html
# See https://alibabatech.medium.com/gcc-vs-clang-llvm-an-in-depth-comparison-of-c-c-compilers-899ede2be378
# See https://docs.oracle.com/cd/E19957-01/806-3567/cc_options.html for CFLAG option explanations
CFLAGS="-g -O2"
export CC=clang
export OBJC=clang

# ======================================================
# Inscribe Version in Info files
# ======================================================

for f in $STRINGS; do
    sed -e "s/@version@/@version@ $VERS/" -i '' $f
done

echo "
# ======================================================
# Configure emacs
# ======================================================
"

# Here we set config options for emacs For more info see config-options.txt.
# Note that this renames ctags in emacs so that it doesn't conflict with other
# installed ctags; see and don't compress info files, etc
# https://www.topbug.net/blog/2016/11/10/installing-emacs-from-source-avoid-the-conflict-of-ctags/
./configure \
    --with-ns \
    --with-native-compilation \
    --with-xwidgets \
    --with-mailutils \
    --with-json \
    --without-dbus \
    --without-compress-install \
    --program-transform-name='s/^ctags$/emctags/' \

echo "
# ======================================================
# Build and install everything
# ======================================================
"

## Check number of processors & use as many as we can!
NCPU=$(getconf _NPROCESSORS_ONLN)

## Send output to log file using tee
## See https://stackoverflow.com/a/60432203/6277148
make bootstrap -j$NCPU | tee bootstrap-log.txt || exit 1 && make install -j$NCPU | tee build-log.txt

echo "DONE!"

echo "
# ======================================================
# Delete old app & Move new app
# ======================================================
"

# Close any emacs sessions
pkill -i emacs

# Remove old emacs
# See https://stackoverflow.com/a/677212/6277148
# and https://stackoverflow.com/a/638980/6277148
# for discussion of confitional checks for files

if [ -e /Applications/Emacs.app ]
then
   if command -v trash </dev/null 2>&1
   then
    echo "Trashing old emacs..."
    trash /Applications/Emacs.app
   else
    echo "Removing old emacs..."
    rm -rf /Applications/Emacs.app
   fi
fi

# Move build to applications folder
mv ${BUILD_DIR}/nextstep/Emacs.app /Applications

echo "DONE!"

echo "
# ======================================================
# Record Git SHA
# ======================================================
"

# This records the Git SHA to an elisp file and
# moves it to the site-lisp dir in the emacs build

cp ${ROOT_DIR}/materials/${GIT_VERSION} ${BUILD_DIR}/
sed -e "s/@@GIT_COMMIT@@/$REV/" -i '' ${BUILD_DIR}/${GIT_VERSION}
mv -f ${BUILD_DIR}/${GIT_VERSION} ${SITELISP}/${GIT_VERSION}

echo "DONE!"

echo "
# ======================================================
# Change icon
# ======================================================
"

# Copy new icon to emacs (currently using a big sur icon)
# See https://github.com/d12frosted/homebrew-emacs-plus/issues/419
cp ${ROOT_DIR}/materials/emacs-big-sur.icns /Applications/Emacs.app/Contents/Resources/Emacs.icns

echo "DONE!"

echo "
# ======================================================
# Copy C Source Code
# ======================================================
"

# Copy C source files to Emacs
cp -r ${ROOT_DIR}/${SRC_DIR}/src /Applications/Emacs.app/Contents/Resources/

echo "DONE!"

echo "
# ======================================================
# Create Log files
# ======================================================"

# Make a directory for the build's log files and move them there
# Note that this removes a previous identical dir if making multiple similar builds
rm -rf ${ROOT_DIR}/build-logs/${DESCR}; mkdir ${ROOT_DIR}/build-logs/${DESCR}
mv ${BUILD_DIR}/config.log ${ROOT_DIR}/build-logs/${DESCR}/${DESCR}-config.log
mv ${BUILD_DIR}/build-log.txt ${ROOT_DIR}/build-logs/${DESCR}/${DESCR}-build-log.txt
mv ${BUILD_DIR}/bootstrap-log.txt ${ROOT_DIR}/build-logs/${DESCR}/${DESCR}-bootstrap-log.txt

echo "DONE!"

echo "
# ======================================================
# Cleanup
# ======================================================
"

# Deletebuild dir
rm -rf ${BUILD_DIR}

echo "DONE!"

echo "
# ======================================================
# Add executables to path
#
# Be sure to add /Applications/Emacs.app/Contents/MacOS/bin
# to your .zshrc or .profile path like so:
# export PATH=\$PATH:/Applications/Emacs.app/Contents/MacOS
# export PATH=\$PATH:/Applications/Emacs.app/Contents/MacOS/bin
# ======================================================"

export PATH=$PATH:/Applications/Emacs.app/Contents/MacOS
export PATH=$PATH:/Applications/Emacs.app/Contents/MacOS/bin

echo "execs added to this terminal session -- please
modify your .zshrc or .zprofile file accordingly"

echo "
# ======================================================
# Open new emacs
# ======================================================
"

open /Applications/Emacs.app

echo "Build script finished!"
