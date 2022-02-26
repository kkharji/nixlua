# nixlua
Package and develop lua with nix with ease. (WIP)

## Features
What does developing with [nixlua] feels like?

- [x] Auto support for all common systems: thanks to [flakes-utils]. Once your flake is is setup, it will produce artifacts to most common systems.
- [x] Auto support and configure lua versions: control which lua versions you support and [nixlua] will auto-generate outputs and overlay for it.
- [x] Test multiple lua version fast: write init.lua and see if it runs on luajit as well as lua 5.4, through the integrate devShell `nix develop`. to run under in luajit just run `luajit` or `lua5_4` for lua 5.4 or use the `defaultVersion` which is bind to `lua`
- [x] Overlay that set enable the user to access packages from `lua.withPackages(p: [_])`
- [ ] convenient commands to tests and debug your lib or app from the command line: e.g. `binspect '.panic()'` would execute top level function called `panic` and pass it's result to [inspect.lua]


## Usage
```nix
(pkgs: rec {
  pname = "awesomelib";

  luaVersions = [ "lua5_4" "luajit" ];
  defaultVersion = "lua5_4";
  src = ./.;

  build = lua: prev: {
    installPhase = with lua.lua; ''
      TARGET="$out/share/lua/${luaversion}"
      mkdir -p $TARGET; cp -r src/${pname} $TARGET
    '';
    checkPhase = "${lua} -i test/script.lua";
  };

  shell = {
    luaEnv = lua: {
        extra = [ lua.stdlib ];
      };
  };
})
```

## Setup

```nix
{
  inputs.nixlua.url = "github:tami5/nixlua";
  outputs = { nixlua, ... }:@inputs
    nixlua.mkOutputs (pkgs: /* config */);
}
```

Should just work :), report if not :P

## Overview

- `pname`: Package name. this option will be concatenate with version to produce nix derivation name.
- `luaVersions`: Lua versions your code base support. default all versions. This controls what devshell lua version you have and what your derivation export.
- `defaultVersion`: default version to expose and make available in yout environment so you can acces it with just `lua`
- `version`: Package version, nixlua comes with helper function called `readVersionFromFile` to read version from a file.
- `src`: where the source code is located. default to current directory.
- `overlays`: overlays to inject to nixpkgs, for example you can inject different luaffi derivation then the one available in nix store.
- `build`: build configuration to pass to `BuildLuaPackage` or `mkDerivation`. not all key are supported, below are the ones supported.
- `build.buildInputs`: build packages  require to build your output.
- `build.nativeBuildInputs`: build libraries require to build your output.
- `build.buildPhase`: script to execute at the build phase. This is useful if you have cmodule.
- `build.installPhase`: script to execute after building your package, here you define basically how ppl would access your artifacts after it gets built.
- `build.checkPhase`: script to execute after the package is built. Got place
  to run tests. To access your lua setup from check, you need to access
  `${lua.bin}` which wrapper exposing youtr lua paths.
- `build.doCheck`: whether to enable the checks.
- `shell`: configurations to be passed mostly to [devshell]
- `shell.commands`: commands to be passed to  [devshell]
- `shell.env`: env variables to be passed to  [devshell]
- `shell.packages`: packages variables to be passed to  [devshell]
- `shell.luaEnv`: lua configuration your shell. This one expect a function that takes lua package specific to a version. see ./wrapLua.nix
- `shell.luaEnv.extra`: (extra packages to be available),
- `shell.luaEnv.overrides` (package overrides),
- `shell.luaEnv.path` a list of paths to be add to lua search path. by default it includes `result/share/lua/$version` and `src`
- `shell.luaEnv.cpath` a list of cpaths to be add to lua c search path. by default it includes `result/lib/lua/$version` and `result/lib`

## Wishlist
- [ ] Expose nix template to be installed with `nix flake init -t github:tami5/nixlua`
- [ ] Override main lua wrapper, e.g. current is `exec ${lua}/bin/lua "$@"`
- [ ] Fix main `lua` alias in devshell not getting set to the `defaultVersion`
  rather just expose luaVersion.
- [ ] pass user inputs to build to mkDerivation directly.
- [ ] drop the requirement for defining `src`, currently it just point to this project repo.

## Insperations

- [nix-cargo-integration](https://github.com/yusdacra/nix-cargo-integration)


[inspect.lua]: https://github.com/kikito/inspect.lua
[devshell]: https://github.com/numtide/devshell
