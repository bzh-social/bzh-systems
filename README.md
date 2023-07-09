# bzh.social

## Setup

NixOS on Hetzner Cloud

* Setup hetzner cloud server with latest Ubuntu
* Drop in your ssh key by going through the web interface
* ssh into the machine
* follow [steps with `nixos-infect`](https://nixos.wiki/wiki/Install_NixOS_on_Hetzner_Cloud)

## Deploy / Apply changes

* Log into any NixOS host with ssh access to the server

```bash
nixos-rebuild --use-remote-sudo --target-host root@bzh.social switch --flake .#bzh-social
```

### Update system

* manually update inputs in `flake.nix` if necessary
* run `nix flake udpate`
* commit the changed `flake.lock`
* see above for deployment

### Update mastodon

* the mastodon package from current stable channel is used
* to update mastodon, update the nixpkgs input in `flake.nix` as soon as a new version is available
* see above for updating the system