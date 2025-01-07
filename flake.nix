{
  description = "Matt's work Macbook config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      home-manager,
      nix-darwin,
      nixpkgs,
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          environment.systemPackages = with pkgs; [
            bat
            comma
            cowsay
            eza
            ffmpeg-full
            fzf
            git
            htop
            httpie
            nixfmt-rfc-style
            ponysay
            ripgrep
            wget
          ];

          homebrew = {
            enable = true;
            # onActivation.cleanup = "uninstall";
            taps = [ ];
            brews = [ ];
            casks = [
              "1password"
              "disk-inventory-x"
              "firefox"
              "iterm2"
              "slack"
              "visual-studio-code"
            ];
          };

          # Suppresses a bunch of warnings: https://github.com/LnL7/nix-darwin/issues/145#issuecomment-2499223123
          nix.channel.enable = false;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          system.defaults.dock.autohide = false;
          system.defaults.menuExtraClock.ShowSeconds = true;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          security.pam.enableSudoTouchIdAuth = true;

          nix.extraOptions = ''
            extra-platforms = x86_64-darwin aarch64-darwin
          '';

          system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;
          system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = true;
          #system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;

          users.users.matt = {
            name = "matt";
            home = "/Users/matt";
          };
        };
    in
    {
      darwinConfigurations."Matts-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.matt = import ./home.nix;
          }
        ];
      };
    };
}
