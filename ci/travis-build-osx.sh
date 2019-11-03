#!/usr/bin/env bash

#
# Build the Travis OSX artifacts 
#
# As of travis-ci-macos-10.13-xcode9.4.1-1529955246, the travis osx image
# contains a broken homebrew. Walk-around by reinstalling:
if [ -n "$TRAVIS" ]; then
    curl -fsSL \
        https://raw.githubusercontent.com/Homebrew/install/master/uninstall \
        > uninstall
    chmod 755 uninstall
    ./uninstall -f
    inst="https://raw.githubusercontent.com/Homebrew/install/master/install"
    /usr/bin/ruby -e "$(curl -fsSL $inst)"
fi
# bailout on errors and echo commands
set -xe
# brew update
# HOMEBREW_NO_AUTO_UPDATE=1 brew install cairo libexif xz
brew install cairo libexif xz
export MACOSX_DEPLOYMENT_TARGET=10.9
# We need to build own libarchive
wget https://libarchive.org/downloads/libarchive-3.3.3.tar.gz
tar zxf libarchive-3.3.3.tar.gz
cd libarchive-3.3.3
./configure --without-lzo2 --without-nettle --without-xml2 --without-openssl --with-expat
make
make install
cd ..

wget http://opencpn.navnux.org/build_deps/wx312_opencpn50_macos109.tar.xz
tar xJf wx312_opencpn50_macos109.tar.xz -C /tmp
export PATH="/usr/local/opt/gettext/bin:$PATH"
echo 'export PATH="/usr/local/opt/gettext/bin:$PATH"' >> ~/.bash_profile

mkdir build
cd build
test -n "$TRAVIS_TAG" && CI_BUILD=OFF || CI_BUILD=ON

cmake -DOCPN_CI_BUILD=$CI_BUILD \
  -DwxWidgets_CONFIG_EXECUTABLE=/tmp/wx312_opencpn50_macos109/bin/wx-config \
  -DwxWidgets_CONFIG_OPTIONS="--prefix=/tmp/wx312_opencpn50_macos109" \
  -DCMAKE_INSTALL_PREFIX=/tmp/opencpn \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 \
  ..
  
make -sj2
mkdir -p /tmp/opencpn/bin/tactics_pi.app/Contents/MacOS
mkdir -p /tmp/opencpn/bin/tactics_pi.app/Contents/SharedSupport/plugins
chmod 644 /usr/local/lib/lib*.dylib
make install
make create-dmg

wget http://opencpn.navnux.org/build_deps/Packages.dmg;
hdiutil attach Packages.dmg;
sudo installer -pkg "/Volumes/Packages 1.2.5/Install Packages.pkg" -target "/";

make create-pkg

# As of travis-ci-macos-10.13-xcode9.4.1-1529955246, the travis osx image
# contains a broken ruby setup used by deployment code. Walk around by
# reinstalling:
if [ -n "$TRAVIS" ]; then
    rm -rf /usr/local/lib/ruby/gems/ && brew reinstall ruby
fi