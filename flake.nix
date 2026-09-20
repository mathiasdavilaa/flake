{
  description = "nixos setup by mad";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    xwayland-satellite-flake = {
      url = "github:Supreeeme/xwayland-satellite/v0.8.1";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mangowm = {
          url = "github:mangowm/mango";
          inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs"; # this line is optional, prevents downloading two versions of nixpkgs but disables cache
    };

    silent-sddm = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      xwayland-satellite-flake,
      ...
    }@inputs:

    let
      system = "x86_64-linux";
      xwayland-pkg = xwayland-satellite-flake.packages.${system}.default;

    in
    {
      nixosConfigurations = {

        laptop = nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs;
            xwayland-satellite-v081 = xwayland-pkg;
          };

          modules = [
            /etc/nixos/hardware-configuration.nix
            ./hosts/laptop/default.nix

            home-manager.nixosModules.home-manager

            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.extraSpecialArgs = {
                inherit inputs;
              };

              home-manager.users.mathias = import ./home/mathias.nix;
            }
          ];
        };

        desktop = nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs;
            xwayland-satellite-v081 = xwayland-pkg;
          };

          modules = [
            /etc/nixos/hardware-configuration.nix
            ./hosts/desktop/default.nix

            home-manager.nixosModules.home-manager

            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.extraSpecialArgs = {
                inherit inputs;
              };


              home-manager.users.mad = import ./home/mad.nix;
            }
          ];
        };
      };
    };
}
