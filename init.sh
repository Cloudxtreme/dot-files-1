#!/bin/bash -e

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
  printf "${GREEN}Installing $1 for $platform ${NORMAL}\n"
  if [[ "$platform" == 'mac' ]]; then
    brew install $1
  elif [[ "$platform" == 'linux' ]]; then
    sudo apt-get install $1
  fi
}

function update_package_manager() {
  printf "${GREEN}Updating package manager${NORMAL}\n"
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
  fi
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
  echo '         __                                     __   '
  echo '  ____  / /_     ____ ___  __  __   ____  _____/ /_  '
  echo ' / __ \/ __ \   / __ `__ \/ / / /  /_  / / ___/ __ \ '
  echo '/ /_/ / / / /  / / / / / / /_/ /    / /_(__  ) / / / '
  echo '\____/_/ /_/  /_/ /_/ /_/\__, /    /___/____/_/ /_/  '
  echo '                        /____/                       ....is now installed!'
  echo ''
  printf "${NORMAL}"
}

function mv_if_exists() {
  if [ -f $1 ]; then
    mv $1 $2
  else
    printf "${RED}File $1 does not exist.${NORMAL}\n"
  fi
}

homedir="$(realpath ~)"

function link_zshrc() {
  mv_if_exists "$homedir/.zshrc" "$homedir/.zshrc.old"
  ln -s "$homedir/dot-files/zsh/zshrc" "$homedir/.zshrc"
}


function link_tmux_conf() {
  mv_if_exists "$homedir/.tmux.conf" "$homedir/.tmux.conf.old"
  ln -s "$homedir/dot-files/tmux/tmux.conf" "$homedir/.tmux.conf"
}

function link_vimrc() {
  mv_if_exists "$homedir/.vimrc" "$homedir/.vimrc.old"
  ln -s "$homedir/dot-files/vim/vimrc" "$homedir/.vimrc"
}


# The meat of the cake

## Getting prepared for the show
get_platform
setup_colors
check_for_deps
update_package_manager
install_package realpath

## Installing and linking
install_package zsh
install_oh_my_zsh
install_package tmux

link_zshrc
link_tmux_conf
link_vimrc
