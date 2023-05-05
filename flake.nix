{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    opam-repository = { url = "github:ocaml/opam-repository"; flake = false; };

    flake-utils.url = "github:numtide/flake-utils";

    opam-nix = {
      url = "github:tweag/opam-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        opam-repository.follows = "opam-repository";
      };
    };
  };
  outputs = { self, flake-utils, opam-nix, nixpkgs, opam-repository, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        on = opam-nix.lib.${system};
        src = ./.;
        localNames =
          with builtins;
          filter
            (f: !isNull f)
            (map
              (f:
                let f' = match "(.*)\.opam$" f; in
                if isNull f' then null else elemAt f' 0)
              (attrNames (readDir src)));

        localPackagesQuery =
          with builtins; listToAttrs (map
            (p: {
              name = p;
              value = "*";
            })
            localNames);

        devPackagesQuery = {
          ocaml-lsp-server = "*";
          utop = "*";
          ocamlformat = pkgs.callPackage ./nix/ocamlformat.nix { ocamlformat = "${src}/.ocamlformat"; };
        };

        query = devPackagesQuery // localPackagesQuery // {
          ocaml-system = "*";
        };

        overlay = self: super:
          with builtins;
          let
            super' = mapAttrs
              (p: _:
                if hasAttr "passthru" super.${p} && hasAttr "pkgdef" super.${p}.passthru
                then super.${p}.overrideAttrs (_: { opam__with_test = "false"; opam__with_doc = "false"; })
                else super.${p})
              super;
            local' = mapAttrs
              (p: _:
                super.${p}.overrideAttrs (_: {
                  doNixSupport = false;
                }))
              localPackagesQuery;
          in
          super' // local';
        scope =
          let
            scp = on.buildOpamProject'
              {
                inherit pkgs;
                resolveArgs = { with-test = true; with-doc = true; };
              }
              src
              query;
          in
          scp.overrideScope' overlay;

        devPackages = builtins.attrValues
          (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope);
      in
      {
        legacyPackages = pkgs;
        packages = with builtins; listToAttrs (map (p: {
          name = p;
          value = scope.${p};
        }) localNames);

        devShells.default =
          pkgs.mkShell {
            inputsFrom = builtins.map (p: scope.${p}) localNames;
            buildInputs = devPackages ++ [ pkgs.nil pkgs.nixpkgs-fmt ];
          };
        formatter = pkgs.nixpkgs-fmt;
      });
}
