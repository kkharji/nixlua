{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
  inputs.devshell.url =
    "github:numtide/devshell?rev=7033f64dd9ef8d9d8644c5030c73913351d2b660";
  inputs.utils.url =
    "github:numtide/flake-utils?rev=3cecb5b042f7f209c56ffd8371b2711a290ec797";

  outputs = { self, nixpkgs, utils, devshell }:
    let
      inherit (utils.lib) eachDefaultSystem flattenTree;
      readVersionFromFile = path:
        with builtins;
        replaceStrings [ "\n" ] [ "" ] (readFile path);

      defaults = {
        luaVersions = [ "lua" "lua5_1" "lua5_2" "lua5_3" "luajit" "lua5_4" ];
        defaultVersion = "lua";
        overlays = [ ];
      };

      mkOverlay = options: final: prev:
        with prev.lib;
        let
          inherit (options) pname luaVersions;
          drv = options.self;
          packages = drv.packages.${final.system};
          mergeOverrides = foldl' mergeAttrs { };
          override = v: _: _: { ${pname} = packages."${pname}_${v}"; };
        in mergeOverrides (map (v:
          let luaOverrides = { packageOverrides = override v; };
          in { ${v} = prev.${v}.override luaOverrides; }) luaVersions);

      mkOutputs = options':
        let
          options = defaults // options';
          inherit (options) pname defaultVersion luaVersions;
        in eachDefaultSystem (system:
          let
            overlays = [ devshell.overlay ] ++ config.overlays;
            pkgs = import nixpkgs { inherit system overlays; };
            config = defaults // options.config pkgs // options;

            inherit (pkgs.lib) genAttrs mapAttrs' nameValuePair flatten;

            wrapLua = import ./wrapLua.nix { inherit pkgs config; };
            mkLuaPkg = luaVersion:
              let
                lua = pkgs.${luaVersion}.pkgs // { bin = wrapLua luaVersion; };
                buildDefaults = {
                  src = ./.;
                  buildInputs = [ ];
                  nativeBuildInputs = [ ];
                  propagatedBuildInputs = [ ];
                  buildPhase = ":";
                  checkPhase = "";
                  doCheck = false;
                };

                buildConfig = buildDefaults
                  // ((config.build lua) buildDefaults);

              in lua.buildLuaPackage {
                inherit (config) pname version;
                inherit (buildConfig) checkPhase doCheck;
                inherit (buildConfig) src buildPhase installPhase;
                inherit (buildConfig) propagatedBuildInputs;
                inherit (buildConfig) buildInputs nativeBuildInputs;
              };

            devShell = let
              getCommands = { commands ? [ ], ... }:
                (map (v: {
                  name = v;
                  command = wrapLua v;
                }) luaVersions) ++ commands;
              getPackages = { packages ? [ ], ... }: packages;
              getEnv = { env ? [ ], ... }: env;
              commands = getCommands config.shell;
              packages = getPackages config.shell;
              env = getEnv config.shell;
            in pkgs.devshell.mkShell { inherit commands packages env; };

            packages = let
              pkgName = n: nameValuePair "${pname}_${n}";
              generate = genAttrs luaVersions;
              fixNames = mapAttrs' pkgName;
            in flattenTree (fixNames (generate mkLuaPkg));

            defaultPackage = packages."${pname}_${defaultVersion}";

          in rec { inherit packages defaultPackage devShell; }) // {
            overlay = mkOverlay options;
          };

    in { inherit readVersionFromFile mkOutputs; };
}
