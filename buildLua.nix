{ pkgs, config, wrapLua, ... }:
luaVersion:
let
  bin = wrapLua luaVersion;
  lua = pkgs.${luaVersion}.pkgs // { inherit bin; };
  buildConfig = let
    configDefaults = {
      src = ./.;
      buildInputs = [ ];
      nativeBuildInputs = [ ];
      propagatedBuildInputs = [ ];
      buildPhase = ":";
      checkPhase = "";
      doCheck = false;
    };
  in configDefaults // ((config.build lua) configDefaults);

in lua.buildLuaPackage {
  inherit (config) pname version;
  inherit (buildConfig) src buildPhase installPhase checkPhase doCheck;
  inherit (buildConfig) buildInputs nativeBuildInputs propagatedBuildInputs;
}
