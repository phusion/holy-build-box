# Tutorial 4: Tweaking the application's build system

[<< Back to Tutorial 3: Static linking to dependencies](TUTORIAL-3-STATIC-LINKING-DEPS.md) | [Tutorial index](README.md#tutorials) | [Skip to Tutorial 5: Library variants >>](TUTORIAL-5-LIBRARY-VARIANTS.md)

Most applications' build systems are not well-tested against static linking, so you will often run into situations where you need to tweak them a little bit.

Each application's build system is different, so each application requires different tweaks. The general idea is that your compilation should should modify the application's build system in such a way that it works. This tutorial serves as an example: we will show you how to tweak Nginx's build system.

## Nginx OpenSSL problem

The Nginx's build system's problem is that it is able to detect OpenSSL's libcrypto library (for cryptographic algorithms), but fails to detect its libssl library (for SSL/TLS support). Because of this, it is not possible to compile Nginx with HTTPS support:

    + ./configure --without-http_rewrite_module --with-http_ssl_module
    ...
    checking for OpenSSL library ... not found

    ./configure: error: SSL modules require the OpenSSL library.
    You can either do not enable the modules, or install the OpenSSL library
    into the system, or build the OpenSSL library statically from the source
    with nginx by using --with-openssl=<path> option.

## Analyzing the problem

Most build systems log the reason why a configure check failed. Autotools log all checks to `config.log`. The Nginx build system logs to `objs/autoconf.err`.

If we look inside the file, we eventually encounter this:

    checking for OpenSSL library

    /hbb_nopic/lib/libcrypto.a(c_zlib.o): In function `bio_zlib_free':
    (.text+0x6f): undefined reference to `inflateEnd'
    ...
    /hbb_nopic/lib/libcrypto.a(dso_dlfcn.o): In function `dlfcn_globallookup':
    (.text+0x30): undefined reference to `dlopen'
    ...
    ----------

    #include <sys/types.h>
    #include <unistd.h>
    #include <openssl/ssl.h>

    int main() {
        SSL_library_init();
       return 0;
    }

    ----------
    cc -O2 -fvisibility=hidden -I/hbb_nopic/include -L/hbb_nopic/lib -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64 -o objs/autotest objs/autotest.c -lssl -lcrypto

In the above snippet, we see that the Nginx configure script tried to compile a small program in order to autodetect whether OpenSSL is available. However, the compilation of that small program failed because of undefined symbol references.

The fact that the `inflateEnd` symbol is undefined clearly indicates that the program should have been linked to zlib (`-lz`), but wasn't. Similarly, `dlopen` indicates that the program needed to be linked to the dl library (`-ldl`).

> Don't know which library a symbol belongs to? Try Google. If you search for `inflateEnd` you should see hints it is related to zlib.

The file inside the Nginx build system that is responsible for autodetect OpenSSL is `auto/lib/openssl/conf`. Inside that file, we see this:

    OPENSSL=NO

    ngx_feature="OpenSSL library"
    ngx_feature_name="NGX_OPENSSL"
    ngx_feature_run=no
    ngx_feature_incs="#include <openssl/ssl.h>"
    ngx_feature_path=
    ngx_feature_libs="-lssl -lcrypto"
    ngx_feature_test="SSL_library_init()"
    . auto/feature

These are the lines responsible for running the OpenSSL check. As you can see, the Nginx configure script tries to link to OpenSSL with `-lssl -lcrypto`, although `-lz -ldl` are also required.

Linking to `-lssl -lcrypto` is enough if OpenSSL is compiled dynamically, because the OpenSSL dynamic is itself linked to zlib and dl. But this doesn't work with static libraries: they do not contain information about which further dependencies are required, so it is up to us to specify all dependencies.

## Fixing the build system

We fix this problem by modifying `auto/lib/openssl/conf` so that it compiles the test program with `-lz -ldl`. The best place to do this is in the compilation script, right after extracting the Nginx source code. Before the `./configure` invocation, insert:

    sed -i 's|-lssl -lcrypto|-lssl -lcrypto -lz -ldl|' auto/lib/openssl/conf

Update the configure invocation in the script to include `--with-http_ssl_module`:

    ./configure --without-http_rewrite_module --with-http_ssl_module

Now test the script. We assume that `nginx-1.8.0.tar.gz` from tutorial 3 is still in the current working directory.

    docker run -t -i --rm \
      -v `pwd`:/io \
      phusion/holy-build-box-64:latest \
      bash /io/compile.sh

You should see that the configure script succeeds in detecting OpenSSL this time:

    + ./configure --without-http_rewrite_module --with-http_ssl_module
    ...
    checking for OpenSSL library ... found

## Verifying the binary

Verify that the compiled Nginx binary works and that it is compiled with SSL support:

    $ ./nginx -V
    nginx version: nginx/1.8.0
    built with OpenSSL 1.0.2d 9 Jul 2015
    TLS SNI support enabled

Finally, verify that it is not dynamically linked to any non-essential libraries:

    $ ldd nginx
        linux-vdso.so.1 =>  (0x00007ffddb4fd000)
        libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fa531b61000)
        libcrypt.so.1 => /lib/x86_64-linux-gnu/libcrypt.so.1 (0x00007fa531928000)
        libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fa531724000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fa53135f000)
        /lib64/ld-linux-x86-64.so.2 (0x00007fa531d7f000)

## The entire compilation script

~~~bash
#!/bin/bash
set -e

# Activate Holy Build Box environment.
source /hbb_nopic/activate

set -x

# Extract and enter source
tar xzf /io/nginx-1.8.0.tar.gz
cd nginx-1.8.0

# Compile
sed -i 's|-lssl -lcrypto|-lssl -lcrypto -lz -ldl|' auto/lib/openssl/conf
./configure --without-http_rewrite_module --with-http_ssl_module
make
make install

# Copy result to host
cp /usr/local/nginx/sbin/nginx /io/
~~~

## Conclusion

You have now seen an example of how a program's build system can be tweaked to allow proper static linking. Next up, we will introduce you to the different library variants that Holy Build Box provides.
