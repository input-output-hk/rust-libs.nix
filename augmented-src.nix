{ mkDerivation }:
{ name, src, files }:
mkDerivation {
    name = "${name}-augmented-src";

    inherit src;

    phases = [ "unpackPhase" "installPhase" ];

    installPhase = (''
        mkdir $out
        cd "$src"
        cp -r . $out/
        cd "$out"
    ''
    + (__concatStringsSep "\n"
        (__attrValues (__mapAttrs (k: v: ''
            if [[ ! -z "$(dirname "${k}")" ]]; then
                mkdir -p "$(dirname "${k}")"
            fi
            cp "${v}" "${k}"
            '')
        files))));
};