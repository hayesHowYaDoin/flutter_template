{ pkgs, lib, config, inputs, ... }:

{
  android = {
    enable = true;
    flutter.enable = true;
  };

  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = with pkgs; [ 
    chromium
    git
  ];

  # https://devenv.sh/scripts/
  scripts.hello.exec = "echo hello from $GREET";

  enterShell = ''
    export CHROME_EXECUTABLE=$(which chromium)
    export ANDROID_HOME=$(which android | sed -E 's/(.*libexec\/android-sdk).*/\1/')
    export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
  '';


  # https://devenv.sh/tests/
  enterTest = ''
  '';

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/languages/
  languages = {
    nix.enable = true;
    dart.enable = true;
  };

  # https://devenv.sh/pre-commit-hooks/
  # pre-commit.hooks.shellcheck.enable = true;

  # https://devenv.sh/processes/
  # processes.ping.exec = "ping example.com";

  # See full reference at https://devenv.sh/reference/options/
}
