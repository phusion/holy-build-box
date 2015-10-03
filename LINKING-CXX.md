# Caveat: Linking C++ applications and libraries

Linking C++ applications and libraries may be tricky because you have to wonder whether you want to statically link to libstdc++.

Unlike glibc which is pretty stable and where newer versions are backwards compatible, newer versions of libstdc++ may not be backwards compatible. Libstdc++ has been pretty stable over the couple of years, but historically it has broken compatibility a lot.

We therefore recommend in most situations that you statically link to libstdc++. This is why [the `*LDFLAGS` environment variables](LIBRARY-VARIANTS.md) contain `-static-libstdc++`. However, sometimes dynamically linking to libstdc++ is better.

## `dlopening()` shared libraries written in C++

C++ applications `dlopen()`ing C++ shared libraries may be problematic. The `dlopen()`ed C++ library may expect different -- possibly incompatible -- libstdc++ versions. If the application contains libstdc++ symbols, then the loaded shared library may use those (incompatible) symbols instead of the symbols from the libstdc++ that it expects. These symbol clashes may cause crashes.

This problem is solved by statically linking the application to libstdc++. Holy Build Box ships static libstdc++ libraries that are compiled with `-fvisibility=hidden`, so symbol clashes do not occur.

## Exceptions

According to [the GCC wiki](https://gcc.gnu.org/wiki/Visibility), exceptions that may be thrown across library boundaries must be declared with default (not hidden) symbol visibility. However, the developer who wrote the original patch [claims](http://stackoverflow.com/questions/14268736/symbol-visibility-exceptions-runtime-error) that these issues have been solved in later GCC issues, so that everything should work even if you do not explicitly declare your exceptions with default visibility. Our static libstdc++ should therefore not cause any problems with exception handling.

## Dynamically linking to libstdc++

There is a situation in which you should not statically link to libstdc++. If your application bundles a bunch of C++ shared libraries, then you can save space by having everything dynamically linked to libstdc++.

However, you must be very certain that none of the code ever `dlopen()`s a library that is not part of your application. This may happen more subtly than you think. A classic problematic use case is the Steam game store. Steam was dynamically linked to libstdc++, and they shipped an older version of libstdc++. Steam's OpenGL library loads the system's video driver with `dlopen()`, and on some systems the video driver is dynamically linked to libstdc++. Because the older libstdc++ shipped with steam was already loaded inside the same process, the video driver fails to find the symbols it needs, and Steam crashes.

If you want to dynamically link to libstdc++ then remove `-static-libstdc++` from your linker flags. You should also set an environment variable so that `libcheck` does not complain about the fact that you are dynamically linked to libstdc++:

    export LIBCHECK_ALLOW='libstdc\+\+'

## References

 * [StackOverflow: Linking libstdc++ statically: any gotchas?](http://stackoverflow.com/questions/13636513/linking-libstdc-statically-any-gotchas)
 * [Rules of static linking: libstdc++, libc, libgcc](http://micro.nicholaswilson.me.uk/post/31855915892/rules-of-static-linking-libstdc-libc-libgcc)
