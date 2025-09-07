{ pkgs, config, lib, ... }:
let
  pg = config.services.postgresql.package;
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  networking = {
    hostName = "bzh-social";
    domain = "";
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    pg.pkgs.pg_repack
  ];

  # add unfree software on per-package level
  # https://nixos.wiki/wiki/Unfree_Software
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "elasticsearch"
    ];

  services.openssh.enable = true;
  services.fail2ban.enable = true;

  # required for mastodon full text search
  services.elasticsearch.enable = true;

  security.acme = {
    acceptTerms = true;
    defaults.email = "bzh.social@gmail.com";
  };

  services.mastodon = {
    enable = true;
    localDomain = "bzh.social";
    configureNginx = true;
    streamingProcesses = 3;
    smtp = {
      host = "smtp.gmail.com";
      user = "bzh.social@gmail.com";
      passwordFile = "/var/lib/mastodon/secrets/smtp-password";
      authenticate = true;
      port = 587;
      fromAddress = "bzh.social <bzh.social@gmail.com>";
    };
    elasticsearch = {
      host = "localhost";
      port = 9200;
    };
    extraConfig = {
      DEFAULT_LOCALE = "fr";
    };
    extraEnvFiles = [
      "/var/lib/mastodon/hcaptcha.env"
    ];
    mediaAutoRemove = {
      enable = true;
      olderThanDays = 7;
    };
  };

  systemd.services.mastodon-prune = {
    description = "Prune old profiles";
    wantedBy = [ "multi-user.target" ];
    after = [ "mastodon-web.service" ];
    environment = config.systemd.services.mastodon-media-auto-remove.environment;
    serviceConfig = builtins.removeAttrs config.systemd.services.mastodon-media-auto-remove.serviceConfig [ "ExecStart" ];
    script = ''
      ${pkgs.mastodon}/bin/tootctl media remove --prune-profiles
      ${pkgs.mastodon}/bin/tootctl statuses remove
    '';
    startAt = "Sun 06:00:00";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    # Allow video uploads up to 100MB
    clientMaxBodySize = "100m";
  };

  services.postgresql = {
    extensions = ps: with ps; [
      pg_repack
    ];
  };

  services.postgresqlBackup = {
    enable = true;
    databases = [ 
      "mastodon"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILOlGe1RFgBIcHdNBRA6SyCjd4TONwi29anhD2c/2K1d @bzh@bzh.social"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJTdCJeK8yhtAxa+wSWwURz4hE4FGQGOPgSwOU0OtEee @hendrik@pourparlers.social"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMQnmVODr2pCW+d13cOikhZsElmcBY8azffqGQGVwlK1 @theolodis@vegane.schule"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICdSYdFmTqbKl+M1TSGCAIlGBLXwIV3LHs0XTt8noXPb Github Actions"
  ];

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  system.stateVersion = "23.05";
}
