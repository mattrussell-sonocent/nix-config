{ config, pkgs, ... }:

{
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.hello
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {
    USE_GKE_GCLOUD_AUTH_PLUGIN = "True";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    lfs = {
      enable = true;
    };
    userEmail = "matt.russell@glean.co";
    userName = "Matt Russell";
    aliases = {
      ci = "commit";
      co = "checkout";
    };
    extraConfig = {
      push.autoSetupRemote = "true";
      pull.rebase = "false"; # merge on pull
      # Config suggested by 1Password when configuring Git Commit Signing:
      user.signingkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDrcDfItPC8Qd85Dydafu6mX28TKIpSlLp3EsnYUqS/XXCNqkFbEhkrMNJW6T7sj3loaGDuIGU3i4CLwX5A7p4XGe4g3t1lPJhnayNg3NS76rNmdsCma4SjFEmxUSJ+Xve9LNgmNiSIyHPDTN9JotmE07b2QaXWxfg1TlS68I4daM33Ha6P43kVFzKMda6XnNnWPNdd6ADsX6v0jZELW/SVui74LoVDYgGmYQX2pfZq0vnsvqJBC2ze7KgtvA3rG1ff2+DlnoX0zE5E986q0GKgzoyV9DZ/aVMgxzSl5W1Zmn3mSe0+0GPhf1U0bZmkfHxuonWqbSkqkfru+si9x4gy33sR28tBQvg4OHEEcYFlezVh/A6vRmkZNDYuao0uuVEX3J5iffh/nN1puSxL8wWiRmbiHjsu8G+vD4Pgi0Xl/X61ikXN0AksJsCGopOpZUYuztK5Mip9DiS8DFtYGuZ/dQDRVX7G8p5I1R1wXpKtS8UCPsWUk+5CPTJ3fJFzSds=";
      gpg.format = "ssh";
      gpg."ssh".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      commit.gpgsign = "true";
    };
  };

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "docker-compose"
        "docker"
        "git"
      ];
      theme = "jonathan";
    };
    shellAliases = {
      b = "git checkout $(git branch | fzf)";
      dc = "docker compose";
      g = "git";
      gd = "git diff";
      gdc = "git diff --cached";
      gs = "git status";
      k = "kubectl";
      ll = "exa --long --classify --git --header";
      sw = "darwin-rebuild switch --flake ~/.config/nix-darwin";
      t = "task";
    };
    initExtra = ''
      . "${pkgs.asdf-vm}/share/asdf-vm/asdf.sh"
      . "${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.bash"
      if [[ -f ~/.asdf/plugins/java/set-java-home.zsh ]]; then
        source ~/.asdf/plugins/java/set-java-home.zsh
      fi
      export PYENV_ROOT="$HOME/.pyenv"
      [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
      eval "$(pyenv init -)"
      eval "$(pyenv virtualenv-init -)"
      eval "$(direnv hook zsh)"
    '';
  };

#   programs.ssh = {
#     enable = true;
#   };
}
