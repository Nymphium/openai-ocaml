{ pkgs, lib, ocamlformat }:
let
  ocamlformat_version =
    let
      ocamlformat_config = lib.strings.splitString "\n" (builtins.readFile ocamlformat);
      re = builtins.match "version\s*=\s*(.*)\s*$";
      version_line = lib.lists.findFirst
        (l: builtins.isList (re l))
        (throw "no version specified in .ocamlformat")
        ocamlformat_config;
      version = builtins.elemAt (re version_line) 0;
    in
    builtins.trace
      "detect ocamlformat version: ${version}"
      (builtins.replaceStrings ["."] ["_"] version);
in
builtins.getAttr ("ocamlformat_" + ocamlformat_version) pkgs
