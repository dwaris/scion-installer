{ pkgs ? import <nixpkgs> {} }:

let
  clangUnwrapped = pkgs.llvmPackages.clang-unwrapped;
  clangWrapped = pkgs.clang;
  multiTargetClang = pkgs.runCommand "multi-target-clang" {} ''
    mkdir -p $out/bin
    cat <<EOF > $out/bin/clang
#!/usr/bin/env bash
for arg in "\$@"; do
  case "\$arg" in
    -target|--target=*)
      exec ${clangUnwrapped}/bin/clang "\$@"
      ;;
  esac
done
exec ${clangWrapped}/bin/clang "\$@"
EOF
    cat <<EOF > $out/bin/clang++
#!/usr/bin/env bash
for arg in "\$@"; do
  case "\$arg" in
    -target|--target=*)
      exec ${clangUnwrapped}/bin/clang++ "\$@"
      ;;
  esac
done
exec ${clangWrapped}/bin/clang++ "\$@"
EOF
    chmod +x $out/bin/clang $out/bin/clang++
  '';
in
(pkgs.buildFHSEnv {
  name = "scion-installer-env";
  targetPkgs = pkgs: (with pkgs; [
    # Shell & core utilities
    bash
    coreutils
    git
    curl
    gnutar
    xz
    gnumake
    perl
    patch
    gawk
    flex
    bison
    m4

    # Compilers & LLVM toolchain
    multiTargetClang
    gcc
    lld
    llvmPackages.llvm # provides llvm-ar

    # Build systems & utilities
    meson
    ninja
    pkg-config
    autoconf
    automake
    libtool
    binutils # provides ar
    bc

    # Compression & filesystems
    _7zz
    zstd
    hfsprogs

    # Headers & libraries
    util-linux.lib # provides libuuid.so.1
    util-linux.dev # provides /usr/include/uuid/uuid.h
    stdenv.cc.cc.lib # provides libstdc++.so.6
    zlib # provides libz.so.1
    ncurses # provides libtinfo.so.6
    libxcrypt

    # Python environment
    python3
    python3Packages.pip
    python3Packages.virtualenv

    # Signing & Android device tools
    ldid
    android-tools
  ]);
  profile = ''
    export LD_LIBRARY_PATH=/lib:/lib64:/usr/lib:/usr/lib64:''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
  '';
  runScript = "bash";
}).env
