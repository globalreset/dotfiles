#!/bin/bash

set -e

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif grep -q Microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    else
        echo "linux"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Nix
install_nix() {
    if ! command_exists nix; then
        echo "Installing Nix..."
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
        
        # Source nix
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
    else
        echo "Nix is already installed"
    fi
}

# Setup Nix configuration
setup_nix_config() {
    echo "Setting up Nix configuration..."
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
}

# Install and configure nix-darwin for macOS
setup_nix_darwin() {
    if ! command_exists darwin-rebuild; then
        echo "Installing nix-darwin..."
        nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
        ./result/bin/darwin-installer
        rm -rf ./result
    else
        echo "nix-darwin is already installed"
    fi
}

# Install home-manager
install_home_manager() {
    if ! command_exists home-manager; then
        echo "Installing home-manager..."
        nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
        nix-channel --update
        
        # Source nix profile to ensure channels are available
        . ~/.nix-profile/etc/profile.d/nix.sh
        
        nix-shell '<home-manager>' -A install
    else
        echo "home-manager is already installed"
    fi
}

# Main installation process
main() {
    OS=$(detect_os)
    echo "Detected OS: $OS"

    # Install Nix package manager
    install_nix
    
    # Setup Nix configuration
    setup_nix_config

    # Install home-manager for all platforms
    install_home_manager

    # Setup nix-darwin for macOS
    if [ "$OS" = "macos" ]; then
        setup_nix_darwin
        echo "MacOS setup complete. You can now run: darwin-rebuild switch --flake .#MacMiniM4"
    elif [ "$OS" = "wsl" ]; then
        echo "WSL setup complete. You can now run: home-manager switch --flake .#wsl"
    else
        echo "Linux setup complete. You can now run: home-manager switch --flake .#ubuntu"
    fi

    echo "Please restart your shell or source your shell's rc file to start using Nix"
}

main