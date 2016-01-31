#!/bin/bash

# Get OS info (mac or linux)
function get_platform() {
  unamestr=`echo $OSTYPE`
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    platform='linux'
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    platform='mac'
  elif [[ "$OSTYPE" == "cygwin" ]]; then
    platform='windows'
  elif [[ "$OSTYPE" == "msys" ]]; then
    platform='windows'
  elif [[ "$OSTYPE" == "win32" ]]; then
    platform='windows'
  elif [[ "$OSTYPE" == "freebsd"* ]]; then
    platform='windows'
  else
    platform='unknown'
  fi
}

# Install given package for platform
function install_package() {
  echo "installing $1 for $platform"
  if [[ "$platform" == 'mac' ]]; then
    brew install $1
  elif [[ "$platform" == 'linux' ]]; then
    sudo apt-get install $1
  fi
}

function update_package_manager() {
  echo "installing $1 for $platform"
  if [[ "$platform" == 'mac' ]]; then
    brew update
  elif [[ "$platform" == 'linux' ]]; then
    sudo apt-get update
  fi
}

function install_brew() {
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

function check_for_deps() {
  if [[ "$platform" == 'mmac' ]]; then
    hash brew 2>/dev/null || { echo >&2 "I require brew but it's not installed. Installing homebrew "; install_brew; }
  elif [[ "$platform" == 'mac' ]]; then
    hash apt-get 2>/dev/null || { echo >&2 "I require apt-get but it's not installed. Aborting"; exit 1; }
    hash realpath 2>/dev/null || { sudo apt-get install realpath }
  fi
}

function install_oh_my_zsh() {
  sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
}

homedir="$(realpath ~)"

function link_zshrc() {
  ln -s "$homedir/dot-files/zsh/zshrc" "$homedir/.zshrc"
}


function link_tmux_conf() {
  ln -s "$homedir/dot-files/tmux/tmux.conf" "$homedir/.tmux.conf"
}

function link_vimrc() {
  ln -s "$homedir/dot-files/vim/vimrc" "$homedir/.vimrc"
}

# The meat of the cake

# Getting prepared for the show
get_platform
check_for_deps
update_package_manager

# Installing and linking
install_package zsh
install_oh_my_zsh
install_package tmux

link_zshrc
link_tmux_conf
link_vimrc
