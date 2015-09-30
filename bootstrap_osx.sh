#!/bin/sh

# Based off of thoughtbot's labtop script; see:
# https://github.com/thoughtbot/laptop/blob/master/mac

info() {
    local fmt="$1"; shift
    # shellcheck disable=SC2059
    printf "$fmt\n" "$@"
}

trap 'ret=$?; test $ret -ne 0 && printf "failed\n" >&2; exit $ret' EXIT

set -e

brew_install_or_upgrade() {
    if brew_is_installed "$1"; then
        if brew_is_upgradable "$1"; then
            info "Upgrading %s ..." "$1"
            brew upgrade "$@"
        else
            info "Already using the latest version of %s. Skipping ..." "$1"
        fi
    else
        info "Installing %s ..." "$1"
        brew install "$@"
    fi
}

brew_is_installed() {
    local name="$(brew_expand_alias "$1")"

    brew list -1 | grep -Fqx "$name"
}

brew_is_upgradable() {
    local name="$(brew_expand_alias "$1")"

    ! brew outdated --quiet "$name" >/dev/null
}

brew_expand_alias() {
    brew info "$1" 2>/dev/null | head -1 | awk '{gsub(/:/, ""); print $1}'
}

brew_launchctl_restart() {
    local name="$(brew_expand_alias "$1")"
    local domain="homebrew.mxcl.$name"
    local plist="$domain.plist"

    info "Restarting %s ..." "$1"
    mkdir -p "$HOME/Library/LaunchAgents"
    ln -sfv "/usr/local/opt/$name/$plist" "$HOME/Library/LaunchAgents"

    if launchctl list | grep -Fq "$domain"; then
        launchctl unload "$HOME/Library/LaunchAgents/$plist" >/dev/null
    fi
    launchctl load "$HOME/Library/LaunchAgents/$plist" >/dev/null
}

if ! command -v brew >/dev/null; then
    info "Installing Homebrew ..."
    curl -fsS \
         'https://raw.githubusercontent.com/Homebrew/install/master/install' | ruby

    export PATH="/usr/local/bin:$PATH"
else
    info "Homebrew already installed. Skipping ..."
fi

info "Updating Homebrew formulas ..."
brew update

brew_install_or_upgrade 'autoconf'
brew_install_or_upgrade 'automake'
brew_install_or_upgrade 'coreutils'
brew_install_or_upgrade 'git'
brew_install_or_upgrade 'htop'
brew_install_or_upgrade 'the_silver_searcher'
brew_install_or_upgrade 'python'
brew_install_or_upgrade 'openssl'
brew_install_or_upgrade 'tmux'

brew unlink openssl && brew link openssl --force

brew_install_or_upgrade 'libyaml'
brew_install_or_upgrade 'node'
