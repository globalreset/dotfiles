{
   config,
   pkgs,
   lib,
   ...
}: let
   inherit (config.lib.file) mkOutOfStoreSymlink;
in {
   programs.home-manager.enable = true;

   home.username = "shughes";
   home.homeDirectory = "/Users/shughes";
   xdg.enable = true;

   #xdg.configFile.nvim.source = mkOutOfStoreSymlink "/Users/shughes/.dotfiles/.config/nvim";

   home.stateVersion = "23.11";

   programs = {
      git = {
         enable = true;
         userName = "Scott Hughes";
         userEmail = "shughes@pobox.com";
         
         extraConfig = {
            core = {
               editor = "nvim";
            };
            init = {
               defaultBranch = "main";
            };
            protocol = {
               # Use SSH instead of HTTPS
               git = {
                  allow = "always";
               };
            };
         };
      };

      gh = {
         enable = true;
         extensions = [
            pkgs.gh-copilot
         ];
         settings = {
            # Use SSH for git operations
            git_protocol = "ssh";
            # Set default editor for GitHub CLI
            editor = "nvim";
            # Enable aliases
            aliases = {
               co = "pr checkout";
               pv = "pr view";
            };
         };
      };
      
      #tmux = import ../home/tmux.nix {inherit pkgs;};
      #zsh = import ../home/zsh.nix {inherit config pkgs lib; };
      #zoxide = (import ../home/zoxide.nix { inherit config pkgs; });
      #fzf = import ../home/fzf.nix {inherit pkgs;};
      #oh-my-posh = import ../home/oh-my-posh.nix {inherit pkgs;};
   };
}