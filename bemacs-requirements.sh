#!/bin/sh

# Install build requirements for emacs
# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Install xcode command line tools
xcode-select --install

# Check for Homebrew,
# Install if we don't have it
if ! command -v brew </dev/null 2>&1
then
   echo "Installing homebrew..."
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew already installed!"
fi

# Update homebrew recipes
brew update

# Upgrade any already-installed formulae.
brew upgrade

binaries=(
  autoconf
  automake
  gcc
  git
  giflib
  gnutls
  jansson
  jpeg
  libgccjit
  libtiff
  libxml2
  pkg-config
  texinfo
  )

echo "installing binaries..."
brew install ${binaries[@]}

echo "build requirements installed"
