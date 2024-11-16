# MacOS System Configuration
#
# Fresh Install Setup Guide:
# -------------------------
#
# 1. Install Nix Package Manager:
#    $ curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
#    - Follow the prompts and restart your terminal after installation
#
# 2. Enable Nix Flakes:
#    $ mkdir -p ~/.config/nix
#    $ echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
#
# 3. Install nix-darwin:
#    $ nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
#    $ ./result/bin/darwin-installer
#    - Say 'yes' to editing /etc/shells
#    - Say 'yes' to editing /etc/nix/nix.conf
#    - Say 'no' to editing /etc/synthetic.conf (we'll handle this via flake)
#
# 4. Clone this repository:
#    $ git clone https://github.com/globalreset/dotfiles.git
#    $ cd dotfiles/nix/darwin
#
# 5. Build and activate the configuration:
#    $ darwin-rebuild switch --flake .#MacMiniM4
#    - Replace MacMiniM4 with your hostname from the configurations below
#
# Maintenance Commands:
# -------------------
# - Update all flake inputs:    $ nix flake update
# - Update specific input:      $ nix flake lock --update-input nixpkgs
# - Rebuild configuration:      $ darwin-rebuild switch --flake .#MacMiniM4
# - Edit configuration:         $ nano flake.nix
# - Check configuration:        $ darwin-rebuild check --flake .#MacMiniM4
#
# Troubleshooting:
# ---------------
# - If Homebrew issues occur:
#   1. Uninstall existing Homebrew: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
#   2. Remove remnants: sudo rm -rf /opt/homebrew
#   3. Rebuild: darwin-rebuild switch --flake .#MacMiniM4
#
# - If permission issues occur:
#   $ sudo chown -R $(whoami):staff /nix
#   $ sudo chmod -R u+w /nix
#
# - If nix-darwin doesn't create directories:
#   $ sudo mkdir -p /run
#   $ sudo chown -R $(whoami):staff /run
#
{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };

  outputs = {
    self,
    nix-darwin,
    nixpkgs,
    nixpkgs-unstable,
    nix-homebrew,
    homebrew-core, homebrew-cask, homebrew-bundle,
    home-manager,
    ...
  } @ inputs: let
    username = "shughes";
    
    # Function to create a base Darwin configuration
    mkDarwinConfig = { system, hostname, extraCasks ? [] }: let
      add-unstable-packages = final: _prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = "${system}";
        };
      };
    in nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [
        # Base configuration
        ({ pkgs, lib, config, ... }: {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [ add-unstable-packages ];
          
          environment.systemPackages = [
            pkgs._1password-cli
            pkgs.bat
            pkgs.fd
            pkgs.fzf
            pkgs.gh
            pkgs.gh-copilot
            pkgs.git
            pkgs.iperf
            pkgs.mkalias
            pkgs.neofetch
            pkgs.neovim
            pkgs.python312
            pkgs.python312Packages.pip
            pkgs.ripgrep
            (pkgs.ruby_3_3.withPackages (ps: [
              pkgs.rubyPackages_3_3.pry
              pkgs.rubyPackages_3_3.pry-doc
              pkgs.rubyPackages_3_3.solargraph
            ]))
            pkgs.tmux
            pkgs.zoxide

            # Fonts
            (pkgs.nerdfonts.override {
              fonts = [ "FiraMono" "Inconsolata" "FiraCode" "UbuntuMono" ];
            })
          ];

          users.users.${username} = {
            name = username;
            home = "/Users/${username}";
          };

          # Nix configuration
          services.nix-daemon.enable = true;
          nix.settings.experimental-features = "nix-command flakes";
          
          # Add ability to used TouchID for sudo
          security.pam.enableSudoTouchIdAuth = true;

          # System Defaults
          system.defaults = {
            # Global system settings
            NSGlobalDomain = {
              # Show all file extensions
              AppleShowAllExtensions = true;
              # Disable press-and-hold in favor of key repeat
              ApplePressAndHoldEnabled = false;
              # Set key repeat settings (lower is faster)
              InitialKeyRepeat = 15;
              KeyRepeat = 2;
            };

            # Finder settings
            finder = {
              # Show path bar and status bar
              ShowPathbar = true;
              ShowStatusBar = true;
              # Show all mounted media on desktop
              ShowExternalHardDrivesOnDesktop = true;
              ShowHardDrivesOnDesktop = true;
              ShowMountedServersOnDesktop = true;
              ShowRemovableMediaOnDesktop = true;
              # Default to column view (Nlsv = list, icnv = icon, clmv = column, Flwv = gallery)
              FXPreferredViewStyle = "clmv";
            };
          };

          # Ensure Nix-installed packages take precedence
          environment.systemPath = [
            "/etc/profiles/per-user/${username}/bin"
            "/run/current-system/sw/bin"
            "/nix/var/nix/profiles/default/bin"
          ];

          # Configure shell environment
          environment.variables = {
            # Prevent system Ruby from taking precedence
            RUBY_ROOT = "${pkgs.ruby_3_3}";
            GEM_HOME = "$HOME/.gem";
            PATH = lib.mkForce "/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin";
          };

          # Used for backwards compatibility, please read the changelog before changing.
          system.stateVersion = 4;
        })

        # Home Manager configuration
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${username} = import ./home.nix;
        }

        # Homebrew configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = username;
            autoMigrate = true;
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "homebrew/homebrew-bundle" = homebrew-bundle;
            };
            mutableTaps = false;
          };

          homebrew = {
            enable = true;
            casks = [
              "arc"
              "chatgpt"
              "claude"
              "discord"
              "firefox"
              "microsoft-teams"
              "obsidian"
              "orbstack"
              "slack"
              "the-unarchiver"
              "visual-studio-code"
              "warp"
            ] ++ extraCasks;
            onActivation = {
              autoUpdate = true;
              cleanup = "zap";
              upgrade = true;
            };
          };
        }
      ];
    };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .
    darwinConfigurations = {
      # M4 Mac Mini (2024)
      "MacMiniM4" = mkDarwinConfig {
        system = "aarch64-darwin";
        hostname = "MacMiniM4";
        extraCasks = [ "adobe-creative-cloud" ];
      };
      
      # Add more machines here
      "OtherMac" = mkDarwinConfig {
        system = "aarch64-darwin";
        hostname = "OtherMac";
      };
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."MacMiniM4".pkgs;
  };
}