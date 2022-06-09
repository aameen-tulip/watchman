{
  inputs.util.url = "github:numtide/flake-utils/master";
  inputs.util.inputs.nixpkgs.follows = "/nixpkgs";

  inputs.fbthrift = {
    url = "github:facebook/fbthrift/5e4ce0994de546bc7e17a0ba588518cabd01f303";
    flake = false;
  };

  /*
  inputs.folly = {
    url = "github:facebook/folly/530a7266f9f15eaad196ce1b291fbbfc8e578810";
    flake = false;
  };
  */

  inputs.wangle = {
    url = "github:facebook/wangle/6edb5d93b6770db56b23c670b782ee452a844b54";
    flake = false;
  };


  outputs = {
    self
    , nixpkgs
    , util
    /* , watchman-src  FIXME: replace with upstream repo when we're done hacking around */
    , fbthrift
    /* , folly */
    , wangle }: let
    inherit (util.lib) eachDefaultSystemMap;
  in {
    packages = eachDefaultSystemMap ( system: let
      pkgsFor = nixpkgs.legacyPackages.${system};
    in {
      watchman = pkgsFor.stdenv.mkDerivation {
        pname = "watchman";
        version = "2022.03.21";
        src = self;
        nativeBuildInputs = with pkgsFor; [
          cmake autoconf automake pkg-config libtool python3
        ];
        buildInputs = with pkgsFor; [
          pcre openssl gmock glog boost.dev libevent
          fmt pkgsFor.folly
          # FIXME: no idea there this tool comes from  -  fizz
        ]; # CoreServices for Apple

        prePatch = ''
          rm -f ./autogen.sh ./autogen.cmd
          cp -r --reflink=auto -- ${fbthrift} ./build/deps/fbthrift
          cp -r --reflink=auto -- ${wangle}   ./build/deps/wangle
          chmod -R u+w ./build/deps
          patchShebangs .
        '';
        # I'm going to try to use `nixpkgs.folly' first, but if it fails
        # we can let them build it from scratch like they normally do.
        #cp -r --reflink=auto -- ${folly}    ./build/deps/folly

        # FIXME: convert to CMake equivalents...
        configureFlags = [
          "--enable-lenient"
          "--with-pcre=yes"
          "--disable-statedir"
        ];

        configurePhase = ''
          runHook preConfigure
          cmake .
          runHook postConfigure
        '';

      };
      default = self.packages.${system}.watchman;
    } );
  };
}
