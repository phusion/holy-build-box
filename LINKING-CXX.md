# Caveat: Linking C++ applications and libraries

Linking C++ applications and libraries is tricky because you have to wonder whether you want to statically link to libstdc++. Unlike glibc which is pretty stable and where newer versions are backwards compatible, newer versions of libstdc++ may not be backwards compatible. Libstdc++ has been pretty stable over the couple of years, but historically it has broken compatibility a lot.

We therefore recommend that you statically link to libstdc++. This is why [the `*LDFLAGS` environment variables](LIBRARY-VARIANTS.md) contain `-static-libstdc++`.

## The special problem of `dlopen()` compatibility

You should be aware of the fact that making C++ applications work well with `dlopen()` is tricky. Specifically, `dlopen()`ing C++ shared libraries is tricky. Luckily, Holy Build Box already solves most of the problems for you.

The core problem is that the C++ application and the `dlopen()`ed C++ library may expect different -- possibly incompatible -- libstdc++ versions. If the application contains libstdc++ symbols, then the loaded shared library may use those (incompatible) symbols instead of the symbols from the libstdc++ that it expects. These symbol clashes may cause crashes.

Holy Build Box ships static libstdc++ libraries that are compiled with `-fvisibility=hidden`, which ensures that these symbol clashes do not happen. `dlopen()`ed C++ shared libraries will never be able to use the libstdc++ symbols defined in your application.

## Dynamically linking to libstdc++

There is a situation in which you should not statically link to libstdc++. If your application bundles a bunch of C++ shared libraries, then you can save space by having everything dynamically linked to libstdc++.

However, you must be very certain that none of the code ever `dlopen()`s a library that is not part of your application. This may happen more subtly than you think. A classic problematic use case is the Steam game store. Steam was dynamically linked to libstdc++, and they shipped an older version of libstdc++. Steam's OpenGL library loads the system's video driver with `dlopen()`, and on some systems the video driver is dynamically linked to libstdc++. Because the older libstdc++ shipped with steam was already loaded inside the same process, the video driver fails to find the symbols it needs, and Steam crashes.

If you want to dynamically link to libstdc++ then remove `-static-libstdc++` from your linker flags. You should also set an environment variable so that `libcheck` does not complain about the fact that you are dynamically linked to libstdc++:

    export LIBCHECK_ALLOW='libstdc\+\+'
