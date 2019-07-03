{stdenv, fetchurl, moar, perl}:
stdenv.mkDerivation rec {
    name = "nqp-${version}";
    version = "2019.03";
    src = fetchurl {
        url    = "https://github.com/perl6/nqp/archive/${version}.tar.gz";
        sha256 = "0qv8pz9is228gy8qyq1r3zcvp1dz3vnyxmfigxwk8zsny3l6s8jz";
    };
    buildInputs = [moar perl];
    configureScript = "perl ./Configure.pl";
    configureFlags = [
        "--backends=moar"
        "--with-moar=${moar}/bin/moar"
    ];
}
