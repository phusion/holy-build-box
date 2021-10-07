# Tutorial 6: Introducing additional static libraries

[<< Back to Tutorial 5: Using library variants](TUTORIAL-5-USING-LIBRARY-VARIANTS.md) | [Tutorial index](README.md#tutorials) | [Skip to Tutorial 7: Verifying binary portability with libcheck >>](TUTORIAL-7-VERIFYING-PORTABILITY-WITH-LIBCHECK.md)

Although Holy Build Box includes a number of static libraries, your application may need additional static libraries. Although it is tempting to install them with `yum`, it is not the approach we recommend. The static libraries provided by CentOS 7 are sub-optimal for the following reasons:

 1. They are not compiled with `-fvisibility=hidden`. This compilation flag reduces the amount unnecessary of symbol text inside the executable, making it smaller.

 2. They are not suitable if your goal is to link static libraries into a dynamic library, as is the case with e.g. Ruby native extensions and NPM native extensions.

   For one, these static libraries not compiled with `-fPIC`, which is required for dynamic libraries.

   Second, these static libraries are not compiled with `-fvisibility=hidden`. If the final application loads multiple dynamic libraries, and two or more of those dynamic libraries are linked to different versions of the same static libraries, then the different copies of those static libraries will conflict with each other. `-fvisibility=hidden` prevents that.

 3. If you use the `exe_gc_hardened` variant, then note that the static libraries provided by CentOS may not be compiled with security hardening flags, and are certainly not compiled with dead-code elimination enabled.

So we recommend that you compile from source any static libraries that are not included with Holy Build Box. Furthermore, the flags used to compile these static libraries should match the flags for the currently active [library variant](TUTORIAL-5-LIBRARY-VARIANTS.md).

Only reasons #2 and #3 *require* you to compile static libraries from source. If #2 and #3 do not apply to you, then you are free to install static libraries from YUM, as long as you don't care about executable size.

When you are done with this tutorial, please refer to [Installing additional dependencies](INSTALLING-ADDITIONAL-DEPENDENCIES.md) for a more generic, more advanced guide on dealing with dependencies.

## Example: compiling Nginx with PCRE

Let's suppose that you want to compile Nginx with the `rewrite_module` enabled. This module requires PCRE, which Holy Build Box does not include. You also want to compile Nginx with the `exe_gc_hardened` variant.

First, download PCRE:

    curl -LO http://skylineservers.dl.sourceforge.net/project/pcre/pcre/8.37/pcre-8.37.tar.gz

Insert the following code into `compile.sh`, right before `# Extract and enter source`:

~~~bash
# Install static PCRE
tar xzf /io/pcre-8.37.tar.gz
cd pcre-8.37
env CFLAGS="$STATICLIB_CFLAGS" CXXFLAGS="$STATICLIB_CXXFLAGS" \
  ./configure --prefix=/hbb_exe_gc_hardened --disable-shared --enable-static
make
make install
cd ..
~~~

Note that we configure PCRE to install to the active library variant's directory (`/hbb_exe_gc_hardened`). The Holy Build Box environment variables are set up in such a way that your compiler looks for libraries in there first, so installing PCRE to that prefix will ensure that the Nginx build system can find PCRE.

The PCRE build system respects `C(XX)FLAGS` and passes those flags to the compiler. But note that we set `C(XX)FLAGS` to `STATICLIB_C(XX)FLAGS` while running the PCRE configure script. The `C(XX)FLAGS` that Holy Build Box sets are meant for compiling binaries only, not for compiling static libraries. When compiling static libraries, you are supposed to use the flags as defined in `STATICLIB_C(XX)FLAGS`. Since PCRE only recognizes `C(XX)FLAGS` but not `STATICLIB_C(XX)FLAGS`, we pass the value of `STATICLIB_C(XX)FLAGS` through the `C(XX)FLAGS` environment variable..

See [Environment structure](ENVIRONMENT-STRUCTURE.md) and [Library Variants](LIBRARY-VARIANTS.md) for more information about `STATICLIB_C(XX)FLAGS`.

Next, remove the `--without-rewrite_module` parameter from the Nginx configure command:

    ./configure --with-http_ssl_module --with-ld-opt="$LDFLAGS"

## Verifying that it works

Invoke the compilation script:

    docker run -t -i --rm \
      -v `pwd`:/io \
      ghcr.io/foobarwidget/holy-build-box-x64 \
      bash /io/compile.sh

Then verify that Nginx is indeed compiled with the `rewrite_module` enabled:

    $ ./nginx -V
    nginx version: nginx/1.8.0
    built with OpenSSL 1.0.2d 9 Jul 2015
    TLS SNI support enabled
    configure arguments: --with-http_ssl_module --with-ld-opt='-L/hbb_exe_gc_hardened/lib -static-libstdc++ -Wl,--gc-sections -pie -Wl,-z,relro'

## The entire compilation script

~~~bash
#!/bin/bash
set -e

# Activate Holy Build Box environment.
source /hbb_exe_gc_hardened/activate

set -x

# Install static PCRE
tar xzf /io/pcre-8.37.tar.gz
cd pcre-8.37
env CFLAGS="$STATICLIB_CFLAGS" CXXFLAGS="$STATICLIB_CXXFLAGS" \
  ./configure --prefix=/hbb_exe_gc_hardened --disable-shared --enable-static
make
make install
cd ..

# Extract and enter source
tar xzf /io/nginx-1.8.0.tar.gz
cd nginx-1.8.0

# Compile
sed -i 's|-lssl -lcrypto|-lssl -lcrypto -lz -ldl|' auto/lib/openssl/conf
./configure --with-http_ssl_module --with-ld-opt="$LDFLAGS"
make
make install

# Verify result
hardening-check -b /usr/local/nginx/sbin/nginx

# Copy result to host
cp /usr/local/nginx/sbin/nginx /io/
~~~

## Conclusion

You have now learned how to compile additional static libraries. But this tutorial only covers the basics. You should also read [Installing additional dependencies](INSTALLING-ADDITIONAL-DEPENDENCIES.md) for a more generic, more advanced guide on dealing with dependencies. In particular, this tutorial compiles PCRE as part of the Nginx build script, but we only did that because it's easy to demonstrate. For serious usage, we recommend installing dependencies by extending the Holy Build Box image.

Or you can head to the next tutorial: [Tutorial 7: Verifying binary portability with libcheck >>](TUTORIAL-7-VERIFYING-PORTABILITY-WITH-LIBCHECK.md)
