#!/bin/bash -e

# ---------------------------------------------- #
# ╻ ╻┏━╸╻  ┏━┓┏━╸┏━┓   ┏━╸╻ ╻┏┓╻┏━╸╺┳╸╻┏━┓┏┓╻┏━┓
# ┣━┫┣╸ ┃  ┣━┛┣╸ ┣┳┛   ┣╸ ┃ ┃┃┗┫┃   ┃ ┃┃ ┃┃┗┫┗━┓
# ╹ ╹┗━╸┗━╸╹  ┗━╸╹┗╸   ╹  ┗━┛╹ ╹┗━╸ ╹ ╹┗━┛╹ ╹┗━┛
# ---------------------------------------------- #

function mv_if_exists() {
  if [ -f $1 ]; then
    print_green "Moving $1 to $2"
    mv $1 $2
  else
    printf "${RED}File $1 does not exist.${NORMAL}, not moving\n"
  fi
}

function set_homedir() {
  homedir="$(realpath ~)"
}

function print_green() {
  printf "${GREEN}$@${NORMAL}\n"
}

function print_red() {
  printf "${RED}$@${NORMAL}\n"
}

function setup_colors() {
  # Use colors, but only if connected to a terminal, and that terminal
  # supports them.
  if which tput >/dev/null 2>&1; then
    ncolors=$(tput colors)
  fi
  if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    BOLD="$(tput bold)"
    NORMAL="$(tput sgr0)"
  else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    NORMAL=""
  fi
}

# ---------------------------------------------- #
# ╻┏┓╻┏━┓╺┳╸┏━┓╻  ╻     ┏━╸╻ ╻┏┓╻┏━╸╺┳╸╻┏━┓┏┓╻┏━┓
# ┃┃┗┫┗━┓ ┃ ┣━┫┃  ┃     ┣╸ ┃ ┃┃┗┫┃   ┃ ┃┃ ┃┃┗┫┗━┓
# ╹╹ ╹┗━┛ ╹ ╹ ╹┗━╸┗━╸   ╹  ┗━┛╹ ╹┗━╸ ╹ ╹┗━┛╹ ╹┗━┛
# ---------------------------------------------- #

# Get OS info (mac or linux)
function get_platform() {
  unamestr=`echo $OSTYPE`
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if [ -f "/etc/arch-release" ]; then
      platform='linux-arch'
    else
      platform='linux'
    fi
  elif [[ "$OSTYPE" == "linux-gnueabihf" ]]; then
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
  print_green "You are attempting to init on $platform"
}

# Install given package for platform
function install_package() {
  print_green "Installing $1 for $platform"
  if ! which $1 > /dev/null; then
    if [[ "$platform" == 'mac' ]]; then
      brew install $1
    elif [[ "$platform" == 'linux' ]]; then
      sudo apt-get install -y $1
    elif [[ "$platform" == 'linux-arch' ]]; then
      yaourt -S --noconfirm $1
    fi
  else
    print_green "$1 is already installed for $platform"
  fi
}

function update_package_manager() {
  print_green "Updating package manager"
  if [[ "$platform" == 'mac' ]]; then
    brew update
  elif [[ "$platform" == 'linux' ]]; then
    sudo apt-get update
  elif [[ "$platform" == 'linux-arch' ]]; then
    yaourt -Syu
  fi
}

function install_brew() {
  print_green "Installing homebrew"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

function check_for_deps() {
  print_green "Checking for dependencies"
  if [[ "$platform" == 'mac' ]]; then
    hash brew 2>/dev/null || { echo >&2 "I require brew but it's not installed. Installing homebrew "; install_brew; }
  elif [[ "$platform" == 'linux' ]]; then
    hash apt-get 2>/dev/null || { echo >&2 "I require apt-get but it's not installed. Aborting"; exit 1; }
  elif [[ "$platform" == 'linux-arch' ]]; then
    hash yaourt 2>/dev/null || { echo >&2 "I require yaourt but it's not installed. Aborting"; exit 1; }
  fi
}

# rudely copied from install.sh for oh-my-zsh, mainly cause i dont want to env zsh
function install_oh_my_zsh() {
  CHECK_ZSH_INSTALLED=$(grep /zsh$ /etc/shells | wc -l)
  if [ ! $CHECK_ZSH_INSTALLED -ge 1 ]; then
    printf "${YELLOW}Zsh is not installed!${NORMAL} Please install zsh first!\n"
    exit
  fi
  unset CHECK_ZSH_INSTALLED

  if [ ! -n "$ZSH" ]; then
    ZSH=~/.oh-my-zsh
  fi

  if [ -d "$ZSH" ]; then
    printf "${YELLOW}You already have Oh My Zsh installed.${NORMAL}\n"
    printf "You'll need to remove $ZSH if you want to re-install.\n"
    exit
  fi

  # Prevent the cloned repository from having insecure permissions. Failing to do
  # so causes compinit() calls to fail with "command not found: compdef" errors
  # for users with insecure umasks (e.g., "002", allowing group writability). Note
  # that this will be ignored under Cygwin by default, as Windows ACLs take
  # precedence over umasks except for filesystems mounted with option "noacl".
  umask g-w,o-w

  printf "${BLUE}Cloning Oh My Zsh...${NORMAL}\n"
  hash git >/dev/null 2>&1 || {
    echo "Error: git is not installed"
    exit 1
  }

  env git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git $ZSH || {
    printf "Error: git clone of oh-my-zsh repo failed\n"
    exit 1
  }

  # The Windows (MSYS) Git is not compatible with normal use on cygwin
  if [ "$OSTYPE" = cygwin ]; then
    if git --version | grep msysgit > /dev/null; then
      echo "Error: Windows/MSYS Git is not supported on Cygwin"
      echo "Error: Make sure the Cygwin git package is installed and is first on the path"
      exit 1
    fi
  fi

  printf "${BLUE}Looking for an existing zsh config...${NORMAL}\n"
  if [ -f ~/.zshrc ] || [ -h ~/.zshrc ]; then
    printf "${YELLOW}Found ~/.zshrc.${NORMAL} ${GREEN}Backing up to ~/.zshrc.pre-oh-my-zsh${NORMAL}\n";
    mv ~/.zshrc ~/.zshrc.pre-oh-my-zsh;
  fi

  printf "${BLUE}Using the Oh My Zsh template file and adding it to ~/.zshrc${NORMAL}\n"
  cp $ZSH/templates/zshrc.zsh-template ~/.zshrc
  sed "/^export ZSH=/ c\\
  export ZSH=$ZSH
  " ~/.zshrc > ~/.zshrc-omztemp
  mv -f ~/.zshrc-omztemp ~/.zshrc

  printf "${BLUE}Copying your current PATH and adding it to the end of ~/.zshrc for you.${NORMAL}\n"
  sed "/export PATH=/ c\\
  export PATH=\"$PATH\"
  " ~/.zshrc > ~/.zshrc-omztemp
  mv -f ~/.zshrc-omztemp ~/.zshrc

  # If this user's login shell is not already "zsh", attempt to switch.
  TEST_CURRENT_SHELL=$(expr "$SHELL" : '.*/\(.*\)')
  if [ "$TEST_CURRENT_SHELL" != "zsh" ]; then
    # If this platform provides a "chsh" command (not Cygwin), do it, man!
    if hash chsh >/dev/null 2>&1; then
      printf "${BLUE}Time to change your default shell to zsh!${NORMAL}\n"
      chsh -s $(grep /zsh$ /etc/shells | tail -1)
    # Else, suggest the user do so manually.
    else
      printf "I can't change your shell automatically because this system does not have chsh.\n"
      printf "${BLUE}Please manually change your default shell to zsh!${NORMAL}\n"
    fi
  fi

  printf "${GREEN}"
  echo 'oh my zsh is now installed'
  printf "${NORMAL}"
}

function link_zshrc() {
  print_green "Linking zshrc"
  mv_if_exists "$homedir/.zshrc" "$homedir/.zshrc.old"
  ln -s "$homedir/dot-files/zsh/zshrc" "$homedir/.zshrc"
}

function link_tmux_conf() {
  print_green "Linking tmux conf"
  mv_if_exists "$homedir/.tmux.conf" "$homedir/.tmux.conf.old"
  ln -s "$homedir/dot-files/tmux/tmux.conf" "$homedir/.tmux.conf"
}

function link_vimrc() {
  print_green "Linking vimrc"
  mv_if_exists "$homedir/.vimrc" "$homedir/.vimrc.old"
  ln -s "$homedir/dot-files/vim/vimrc" "$homedir/.vimrc"
}

function construct_vimrc() {
  # for now lets just use basic_vimrc
  cp "$homedir/dot-files/vim/vimrcs/basic_vimrc" "$homedir/dot-files/vim/vimrc"
}

function install_vim() {
  construct_vimrc
  link_vimrc
}

# ----------------------------------------------------------- #
#╺┳╸╻ ╻┏━╸   ┏┳┓┏━╸┏━┓╺┳╸   ┏━┓┏━╸   ╺┳╸╻ ╻┏━╸   ┏━╸┏━┓╻┏ ┏━╸ #
# ┃ ┣━┫┣╸    ┃┃┃┣╸ ┣━┫ ┃    ┃ ┃┣╸     ┃ ┣━┫┣╸    ┃  ┣━┫┣┻┓┣╸  #
# ╹ ╹ ╹┗━╸   ╹ ╹┗━╸╹ ╹ ╹    ┗━┛╹      ╹ ╹ ╹┗━╸   ┗━╸╹ ╹╹ ╹┗━╸ #
# ----------------------------------------------------------- #

## Getting prepared for the show
get_platform
setup_colors
check_for_deps
update_package_manager
install_package realpath
set_homedir

## Installing and linking
install_package zsh
install_oh_my_zsh
install_package tmux

## Link easy dot files
link_zshrc
link_tmux_conf

## Ok here we go, installing vim
install_vim

## and we are done, boot zsh
env zsh
