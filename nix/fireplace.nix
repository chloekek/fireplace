{stdenv, makeWrapper, perl, rakudo, zeromq}:
let libraryPath = stdenv.lib.makeLibraryPath [zeromq]; in
stdenv.mkDerivation {
    name = "fireplace";
    src = stdenv.lib.cleanSource ./..;
    buildInputs = [makeWrapper rakudo];
    phases = ["unpackPhase" "installPhase"];
    installPhase = ''
        mkdir --parents $out/bin $out/share/doc

        cp --recursive bin lib t $out/share

        for src in $(find $out/share/lib -type f -name '*.pm6' -printf '%P\n')
        do
            HOME=$PWD PERL6LIB=$out/share/lib \
                perl6 --doc "$out/share/lib/$src" \
                    > $out/share/doc/$(sed 's:/:-:g' <<< ''${src%.pm6}.txt)
        done

        makeWrapper \
            ${rakudo}/bin/perl6 \
            $out/bin/fireplace \
            --prefix LD_LIBRARY_PATH : ${libraryPath} \
            --prefix PERL6LIB , $out/share/lib \
            --add-flags $out/share/bin/fireplace

        makeWrapper \
            ${perl}/bin/prove \
            $out/bin/fireplace.test \
            --prefix LD_LIBRARY_PATH : ${libraryPath} \
            --prefix PERL6LIB , $out/share/lib \
            --add-flags --exec \
            --add-flags ${rakudo}/bin/perl6 \
            --add-flags --recurse \
            --add-flags $out/share/t
    '';
}
