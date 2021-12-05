# Install build requirements for emacs
# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Install xcode command line tools
xcode-select --install

# Check for Homebrew,
# Install if we don't have it
if test ! $(which brew); then
  echo "Installing homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
  gnutls
  jansson
  jpeg
  libgccjit
  pkg-config
  texinfo
  )

echo "installing binaries..."
brew install ${binaries[@]}

echo "build requirements installed"
