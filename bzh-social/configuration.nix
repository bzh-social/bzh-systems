{ pkgs, ... }:

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
    docker-compose
    git
    vim
    htop
  ];

  virtualisation.docker.enable = true;

  services.openssh.enable = true;
  services.fail2ban.enable = true;

  security.acme = {
    acceptTerms = true;
    defaults.email = "bzh.social@gmail.com";
  };

  services.mastodon = {
    enable = true;
    localDomain = "bzh.social";
    configureNginx = true;
    smtp = {
      host = "smtp.gmail.com";
      user = "bzh.social@gmail.com";
      passwordFile = "/var/lib/mastodon/secrets/smtp-password";
      authenticate = true;
      port = 587;
      fromAddress = "bzh.social <bzh.social@gmail.com>";
    };
    extraConfig = {
      DEFAULT_LOCALE = "fr";
    };
    mediaAutoRemove = {
      enable = true;
      olderThanDays = 7;
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    # Allow video uploads up to 100MB
    clientMaxBodySize = "100m";

    virtualHosts."relay.pourparlers.social" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        root = "/var/lib/activity-relay";
      };

      locations."/inbox" = {
        proxyPass = "http://127.0.0.1:8080";
      };
      
      locations."/actor" = {
        proxyPass = "http://127.0.0.1:8080";
      };

      locations."~ ^/(.*)/" = {
        proxyPass = "http://127.0.0.1:8080";
      };
    };
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

  system.stateVersion = "23.05";
}
