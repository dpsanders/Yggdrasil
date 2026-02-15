# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Pijul"
true_upstream_version = v"1.0.0-beta.11"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    FileSource("https://crates.io/api/v1/crates/pijul/$(true_upstream_version)/download", "8a4fc27aa81ee061310d57fce2df9cc45f3149ddb00bdfab2b816beb0359b13d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
tar xzvf download
cd pijul-*

# Ensure that the `openssl` crate picks up the intended library
# https://docs.rs/openssl/0.10.75/openssl/#manual
# export OPENSSL_DIR="$prefix"

# Build Pijul
cargo build --release

# Install the Pijul ExecutableProduct into the prefix
cargo install --locked --root "$prefix" --path .
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    # Linux:
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("riscv64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),

    # macOS:
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; ),

    # FreeBSD:
    Platform("x86_64", "freebsd"; ),
    Platform("aarch64", "freebsd"; ),

    # Windows:
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; ),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("pijul", :pijul),
    # LibraryProduct("libpijul", :libpijul), # TODO: Build the LibraryProduct
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95")),
    Dependency(PackageSpec(name="libsodium_jll", uuid="a9144af2-ca23-56d9-984f-0d03f7b5ccf8")),
]

if Sys.islinux()
  # Dbus is only needed on Linux
  push!(dependencies, Dependency(PackageSpec(name="Dbus_jll", uuid="ee1fde0b-3d02-5ea6-8484-8dfef6360eab")))
end

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c])
