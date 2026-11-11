{
  description = "Build environment for Scion installer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
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

          fhs = pkgs.buildFHSEnv {
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
              llvmPackages.llvm

              # Build systems & utilities
              meson
              ninja
              pkg-config
              autoconf
              automake
              libtool
              binutils
              bc

              # Compression & filesystems
              _7zz
              zstd
              hfsprogs

              # Headers & libraries
              util-linux.lib
              util-linux.dev
              stdenv.cc.cc.lib
              zlib
              ncurses
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
          };
        in
        {
          default = fhs;
        }
      );

      devShells = forAllSystems (system:
        let
          fhs = self.packages.${system}.default;
        in
        {
          default = fhs.env;
        }
      );
    };
}
