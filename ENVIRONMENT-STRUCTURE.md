# Environment structure

As described in [Features](README.md#features), the Holy Build Box environment consists of a bare-bones CentOS 5 system, on top of which a compiler toolchain and various libraries are installed.

Most of the compiler toolchain, e.g. `gcc` and `g++`, are installed with YUM. However, some software in CentOS 5 is way too outdated for compiling modern applications, so we installed more recent versions of them from source.

 * Executable tools such as `pkg-config` and `CMake` are installed to `/hbb`.
 * Libraries such as OpenSSL are installed to to the library variant directories. That is, `/hbb_nopic`, `/hbb_pic` and `/hbb_deadstrip_hardened_pie`.

The activation script inside each library variant directory sets various environment variables to ensure that whatever is inside that library variant directory is found first. For example, it prepends `/hbb/bin` and `/hbb_<VARIANT NAME>/bin` to PATH.

The activation script sets the following environment variables:

 * `PATH`
 * `C_INCLUDE_PATH`
 * `CPLUS_INCLUDE_PATH`
 * `LIBRARY_PATH`
 * `PKG_CONFIG_PATH`
 * `CFLAGS`
 * `CXXFLAGS`
 * `LDFLAGS`
 * `MINIMAL_CFLAGS`
 * `O3_ALLOWED`

Some environment variables deserve special explanation:

 * `MINIMAL_CFLAGS` is like `CXFLAGS` and `CXXFLAGS`, but does not include `-O2 -fvisibility=hidden`. It does include `-I` and `-L` flags to ensure that the compiler knows where to look for header and library files. It also does include variant-specific flags such as `-fPIC` (for the `pic` variant).
 * `O3_ALLOWED` signals whether the variant is compatible with `-O3`. It is set to `true` or `false`. It is true for all variants except for the `deadstrip_hardened_pie` variant.

You can inspect the environment variables by starting a bash shell and sourcing one of the activation scripts:

    $ docker run -t -i --rm phusion/holy-build-box-64:latest bash
    
    container$ source /hbb_pic/activate
    Holy build box activated
    Prefix: /hbb_pic
    Compiler flags: -O2 -fvisibility=hidden -I/hbb_nopic/include -L/hbb_nopic/lib -fPIC
    Linker flags: -L/hbb_nopic/lib -fPIC

    container$ echo $CFLAGS
    -O2 -fvisibility=hidden -I/hbb_nopic/include -L/hbb_nopic/lib -fPIC
