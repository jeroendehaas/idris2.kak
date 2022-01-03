{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils, ...}:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        kakoune-idris2 = pkgs.kakouneUtils.buildKakounePlugin {
          pname = "kakoune-idris2";
          version = "0.1";
          src = ./.;
        };
        kakoune-with-idris2 = pkgs.symlinkJoin {
          paths = [
            (pkgs.kakoune.override { plugins = [kakoune-idris2]; })
          ];
          name = "kakoune-with-idris2-0.1";
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            cat << "EOF" > $out/share/kak/autoload/idris2-conf.kak
            hook global WinSetOption filetype=idris2 %{

                hook window InsertChar \n -group my-idris2-indent idris2-newline
                hook window InsertDelete ' ' -group my-idris2-indent idris2-delete

                hook -once -always window WinSetOption filetype=.* %{ remove-hooks window my-idris2-.* }
            }
            EOF
          '';
        };

      in rec {
        packages = { inherit kakoune-idris2; };
        devShell = pkgs.mkShell {
          buildInputs = [
            kakoune-with-idris2
          ];
        };
 
      }
    );
}
