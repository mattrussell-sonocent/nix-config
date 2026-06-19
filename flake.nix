{
  description = "Matt's work Macbook config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    claude-commander.url = "github:sizeak/claude-commander/v0.16.0";
  };

  outputs =
    inputs@{
      self,
      home-manager,
      nix-darwin,
      nixpkgs,
      determinate,
      claude-commander,
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          environment.systemPackages = with pkgs; [
            bat
            colima
            comma
            cowsay
            direnv
            docker
            dtrx
            eza
            fd
            ffmpeg-full
            fzf
            gh
            gnupg
            htop
            httpie
            lazydocker
            lazygit
            kubectx
            ngrok
            nixfmt
            ponysay
            ripgrep
            sd
            unixtools.watch
            watchman
            wget
            yt-dlp
          ];

          homebrew = {
            enable = true;
            global = {
              autoUpdate = false;
            };
            onActivation = {
              cleanup = "uninstall";
              upgrade = false;
            };
            taps = [ ];
            brews = [
              "pyenv"
              "pyenv-virtualenv"
              "tfenv"
            ];
            casks = [
              "1password"
              "anki"
              "bruno"
              "discord"
              "disk-inventory-x"
              "firefox"
              "iterm2"
              "libreoffice"
              "microsoft-edge"
              "obs"
              "rectangle"
              "slack"
              "stellarium"
              "visual-studio-code"
              "vlc"
            ];
          };

          # Determinate Nix owns Nix (binary, daemon, /etc/nix/nix.conf, GC).
          # Force-disables nix-darwin's own Nix management.
          determinateNix.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          system.defaults.dock.autohide = false;
          system.defaults.menuExtraClock.ShowSeconds = true;
          system.defaults.controlcenter.Bluetooth = true;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          system.primaryUser = "matt";

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          security.pam.services.sudo_local.touchIdAuth = true;

          nixpkgs.config.allowUnfree = true;

          system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;
          system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = true;
          #system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;

          # system.defaults.CustomUserPreferences = {
          #   NSGlobalDomain = {
          #     # Add a context menu item for showing the Web Inspector in web views
          #     WebKitDeveloperExtras = true;
          #   };            
          #   "com.apple.Safari" = {
          #     IncludeDevelopMenu = true;
          #     WebKitDeveloperExtrasEnabledPreferenceKey = true;
          #     "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
          #   };
          # };

          users.users.matt = {
            name = "matt";
            home = "/Users/matt";
          };
        };
    in
    {
      darwinConfigurations."Matts-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          inputs.determinate.darwinModules.default
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.matt = import ./home.nix;
          }
        ];
      };
    };
}
