# Environment structure

As described in [Features](README.md#features), the Holy Build Box environment consists of a bare-bones CentOS 7 system, on top of which a compiler toolchain and various libraries are installed.

Most of the compiler toolchain, e.g. `gcc` and `g++`, are installed with YUM. However, some software in CentOS 7 is too outdated for compiling modern applications, so we installed more recent versions of them from source.

 * Executable tools such as `CMake` are installed to `/hbb`.
 * Libraries such as OpenSSL are installed to the [library variant directories](LIBRARY-VARIANTS.md), e.g. `/hbb_exe`.

The activation script inside each library variant directory sets various environment variables to ensure that whatever is inside that library variant directory is found first. For example, it prepends `/hbb/bin` and `/hbb_<VARIANT NAME>/bin` to PATH.

The activation script sets the following environment variables:

 * `PATH`
 * `C_INCLUDE_PATH`
 * `CPLUS_INCLUDE_PATH`
 * `LIBRARY_PATH`
 * `PKG_CONFIG_PATH`
 * `O3_ALLOWED`
 * `CFLAGS`
 * `CXXFLAGS`
 * `LDFLAGS`


Some environment variables deserve special explanation:

 * `O3_ALLOWED` signals whether the variant is compatible with `-O3`. It is set to `true` or `false`. It is true for all variants except for the `exe_gc_hardened` variant.
 * `CFLAGS`, `CXXFLAGS` and `LDFLAGS` are meant for compiling binaries.
 * `STATICLIB_CFLAGS` and `STATICLIB_CXXFLAGS` are meant for compiling static libraries. When compiling static libraries, you should set `CFLAGS` and `CXXFLAGS` to equal these variables.
 * `SHLIB_CFLAGS`, `SHLIB_CXXFLAGS` and `SHLIB_LDFLAGS` are meant for compiling shared libraries. When compiling shared libraries, you should set `CFLAGS`, `CXXFLAGS` and `LDFLAGS` to equal these variables.

You can inspect the environment variables by starting a bash shell and sourcing one of the activation scripts:

    $ docker run -t -i --rm phusion/holy-build-box-64:latest bash

    container$ source /hbb_exe/activate
    Holy build box activated
    Prefix: /hbb_exe
    CFLAGS: -O2 -fvisibility=hidden -I/hbb_exe/include
    LDFLAGS: -L/hbb_exe -static-libstdc++
    STATICLIB_CFLAGS: -O2 -fvisibility=hidden -I/hbb_exe/include
    SHLIB_CFLAGS: -O2 -fvisibility=hidden -I/hbb_exe/include
    SHLIB_LDFLAGS: -L/hbb_exe

    container$ echo $CFLAGS
    -O2 -fvisibility=hidden -I/hbb_exe/include
