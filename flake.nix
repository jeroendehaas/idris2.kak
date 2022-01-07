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
          name = "kakoune-with-idris2-0.1";
          paths = [ (pkgs.kakoune.override { plugins = [ kakoune-idris2 ]; }) ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            mkdir -p $out/config
            ln -s $out/share/kak/autoload $out/config/autoload
            cat << "EOF" > $out/config/kakrc
            hook global WinSetOption filetype=idris %{

                hook window InsertChar \n -group my-idris-indent idris-newline
                hook window InsertDelete ' ' -group my-idris-indent idris-delete

                map window normal ">" ': idris-indent<ret>'
                map window normal "<" ': idris-unindent<ret>'

                hook -once -always window WinSetOption filetype=.* %{
                  remove-hooks window my-idris-.*
                  map window normal '>' '>'
                  map window normal '<' '<'
                }
            }
            EOF
            rm $out/bin/kak
            makeWrapper ${pkgs.kakoune}/bin/kak "$out/bin/kak" --set KAKOUNE_CONFIG_DIR "$out/config"
          '';
          meta = {
            mainProgram = "kak";
          };
        };
      in {
        packages = { inherit kakoune-idris2; };
        defaultApp = kakoune-with-idris2;
        devShell = pkgs.mkShell {
          buildInputs = [
            kakoune-with-idris2
          ];
        };
 
      }
    );
}
