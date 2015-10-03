# Which system libraries are considered essential?

As explained in the [introduction](README.md#problem-introduction), the approach recommended by Holy Build Box is to statically link applications to all their dependencies, except for essential system dependencies. This is because those essential system dependencies exist on pretty much all Linux systems and are pretty stable.

We consider the following libraries to be essential system libraries:

    # Linux dynamic linker and kernel interface
    ld-linux.*
    linux-gate.so
    linux-vdso.so

    # glibc
    libc.so
    libm.so
    libpthread.so
    librt.so
    libdl.so
    libcrypt.so  (NOT libcrypto.so!)
    libutil.so
    libnsl.so
    libresolv.so

    # GCC runtime
    libgcc_s.so

Note that libstdc++ is not included in this list because of the [C++ linking caveats](LINKING-CXX.md).
