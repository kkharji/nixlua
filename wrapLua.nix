{ pkgs, config, ... }:
luaName:
let
  inherit (pkgs.lib) concatStringsSep;
  concatPaths = concatStringsSep ";";

  lua' = pkgs."${luaName}";
  inherit (lua') luaversion;
  isLua5_4 = luaversion == "5.4";

  luaEnv = config.shell.luaEnv lua;

  # note: remove if nix luarocks updated to 3.7
  packageOverrides = { overrides ? { }, ... }:
    _: p:
    let luarocks = p: if isLua5_4 then p.luarocks-3_7 else p.luarocks;
    in { luarocks = luarocks p; } // overrides;

  extraPackages = { extra ? [ ], ... }:
    (pa: with pa; extra ++ [ inspect luarocks ]);

  lua =
    (lua'.override { packageOverrides = packageOverrides lua'; }).withPackages
    (extraPackages lua');

  resolve = map (str: "${lua.outPath}/${str}");

  nixCPath = resolve lua.lua.LuaCPathSearchPaths;
  nixLuaPath = resolve lua.lua.LuaPathSearchPaths;

  userPath = { path, ... }:
    path ++ [
      "src/?.lua"
      "src/?/init.lua"
      "result/share/lua/${luaversion}/?.lua"
      "result/share/lua/${luaversion}/?/init.lua"
    ];

  userCpath = { cpath, ... }:
    cpath ++ [
      "result/lib/lua/${luaversion}/?.so"
      "result/lib/lua/${luaversion}/?.dylib"
      "result/lib/?.dylib"
      "result/lib/?.os"
    ];

in ''
  export LUA_CPATH="${concatPaths (nixCPath ++ (userCpath luaEnv))}"
  export LUA_PATH="${concatPaths (nixLuaPath ++ (userPath luaEnv))}"
  exec ${lua}/bin/lua "$@"
''
