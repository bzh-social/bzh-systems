{
  description = "bzh.social nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }@attrs: {
    nixosConfigurations.bzh-social = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        ./bzh-social/configuration.nix
      ];
    };
  };
}
