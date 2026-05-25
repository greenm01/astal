{
  mkAstalPkg,
  pkgs,
  ...
}:
mkAstalPkg {
  pname = "astal-triad";
  src = ./.;
  packages = [pkgs.json-glib];

  libname = "triad";
  authors = "Nil Tempus";
  name = "AstalTriad";
  description = "IPC client for Triad";
}
