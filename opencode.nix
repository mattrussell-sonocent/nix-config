# OpenCode (terminal coding agent) against the local ollama server, with
# safeguards. OpenCode allows edits, shell commands and web fetches by default;
# here it must ask first, and it runs without GitHub or SSH credentials, only in
# repositories with no remotes (use `opencode-scratch` to make one). The
# permission rules are friction, not a sandbox: a container is the next step if
# it's ever given long unsupervised tasks.
{ pkgs, ... }:

let
  config = {
    "$schema" = "https://opencode.ai/config.json";
    model = "ollama/qwen3-coder:30b";
    provider.ollama = {
      npm = "@ai-sdk/openai-compatible";
      name = "Ollama (local)";
      options.baseURL = "http://127.0.0.1:11434/v1";
      models."qwen3-coder:30b".name = "Qwen3 Coder 30B";
    };
    # Never upload sessions; updates come from Nix.
    share = "disabled";
    autoupdate = false;
    # The last matching rule wins, so the catch-all must come first. toJSON
    # sorts keys, and "*" sorts before letters; keep the specific patterns
    # from overlapping so their relative order doesn't matter.
    permission = {
      edit = "ask";
      webfetch = "deny";
      bash = {
        "*" = "ask";
        "ls *" = "allow";
        "cat *" = "allow";
        "grep *" = "allow";
        "rg *" = "allow";
        "git status*" = "allow";
        "git diff*" = "allow";
        "git log*" = "allow";
        "git show*" = "allow";
        "cargo build*" = "allow";
        "cargo test*" = "allow";
        "cargo fmt*" = "allow";
        "git push*" = "deny";
        "git remote*" = "deny";
        "git reset*" = "deny";
        "git rebase*" = "deny";
        "git filter-branch*" = "deny";
        "gh *" = "deny";
        "ssh *" = "deny";
        "scp *" = "deny";
        "curl *" = "deny";
        "wget *" = "deny";
        "sudo *" = "deny";
        "rm -rf*" = "deny";
        "darwin-rebuild*" = "deny";
      };
    };
  };

  # The `worker` agent, for unattended runs that Claude orchestrates
  # (`opencode run --agent worker "<task>"` in a scratch clone): edits are
  # allowed, and only an explicit list of commands; everything else is denied,
  # since nobody is there to answer a prompt. It doesn't commit; Claude reviews
  # the diff and brings the change in.
  config.agent.worker = {
    description = "Unattended worker for tasks Claude hands over, in a scratch clone";
    mode = "primary";
    permission = {
      edit = "allow";
      webfetch = "deny";
      bash = {
        "*" = "deny";
        "ls *" = "allow";
        "cat *" = "allow";
        "head *" = "allow";
        "tail *" = "allow";
        "wc *" = "allow";
        "grep *" = "allow";
        "rg *" = "allow";
        "git status*" = "allow";
        "git diff*" = "allow";
        "git log*" = "allow";
        "git show*" = "allow";
        "nix develop -c cargo build*" = "allow";
        "nix develop -c cargo test*" = "allow";
        "nix develop -c cargo fmt*" = "allow";
        "./target/release/stitchwort *" = "allow";
      };
    };
  };

  # `opencode`, but only in a git repository with no remotes, and with GitHub
  # and SSH credentials hidden from it and everything it runs.
  opencode = pkgs.writeShellScriptBin "opencode" ''
    set -euo pipefail
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
      echo "opencode: run it inside a git repository (try opencode-scratch)" >&2
      exit 1
    fi
    if [ -n "$(git remote)" ]; then
      echo "opencode: this repository has remotes ($(git remote | tr '\n' ' '))." >&2
      echo "opencode: use a scratch clone without remotes: opencode-scratch <repo>" >&2
      exit 1
    fi
    exec env -u SSH_AUTH_SOCK -u GH_TOKEN -u GITHUB_TOKEN \
      GH_CONFIG_DIR=/nonexistent GIT_SSH_COMMAND=false GIT_TERMINAL_PROMPT=0 \
      ${pkgs.opencode}/bin/opencode "$@"
  '';

  # opencode-scratch <repo>: clone <repo> (default: the current one) into
  # ~/scratch/opencode/<name>-<time>, drop its remotes, start a branch, and
  # print the path. Bring results back by reviewing and fetching from it.
  scratch = pkgs.writeShellScriptBin "opencode-scratch" ''
    set -euo pipefail
    src="$(cd "''${1:-.}" && git rev-parse --show-toplevel)"
    dest="$HOME/scratch/opencode/$(basename "$src")-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$(dirname "$dest")"
    git clone --quiet --no-hardlinks "$src" "$dest"
    cd "$dest"
    for r in $(git remote); do git remote remove "$r"; done
    # Commit as the source repository does: a clone doesn't copy its local
    # config, and the global identity may be a different (work) one.
    git config user.name "$(git -C "$src" config user.name)"
    git config user.email "$(git -C "$src" config user.email)"
    git switch --quiet -c "opencode/$(date +%Y%m%d-%H%M%S)"
    echo "$dest"
  '';
in
{
  home.packages = [
    opencode
    scratch
  ];
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON config;
}
