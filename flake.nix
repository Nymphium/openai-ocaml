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
  outputs = { self, flake-utils, opam-nix, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        on = opam-nix.lib.${system};
        src = pkgs.nix-gitignore.gitignoreSource [ ] ./.;
        local =
          with builtins;
          filter
            (f: !isNull f)
            (map (f: 
              let f' = match "(.*)\.opam$" f; in
              if isNull f' then null else elemAt f' 0)
              (attrNames (readDir ./.)));

        devPackagesQuery = {
          ocaml-lsp-server = "*";
          utop = "*";
        };

        query = devPackagesQuery // {
          # fetch ocaml from nixpkgs, not from opam-repository (it can be done without build)
          ocaml-system = "*";
          # XXX: failed to build wiht 1.9.6 :thinking_face:
          ocamlfind = "1.9.5";
        };

        overlay = final: prev:
          with builtins;
          listToAttrs
            (map (p: {
              name = p;
              value = prev.${p}.overrideAttrs (_: {
                  doNixSupport = false;
                  with-test = true;
                });
              }) local);

        scope =
          let scp = on.buildOpamProject' {
              inherit pkgs;
              resolveArgs.with-test = false;
            } src query;
          in scp.overrideScope' overlay;

        devPackages = builtins.attrValues
          (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope);
      in {
        legacyPackages = scope;
        utils.opam-nix = opam-nix;

        devShells.default =
          let
            ocamlformat = pkgs.callPackage ./nix/ocamlformat.nix { ocamlformat = ./.ocamlformat; };
          in
          pkgs.mkShell {
            inputsFrom = builtins.map (p: scope.${p} ) local;
            buildInputs = devPackages ++ [ ocamlformat ];
          };
      });
}
