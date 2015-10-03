# Tutorial 4: Tweaking the application's build system

[<< Back to Tutorial 3: Static linking to dependencies](TUTORIAL-3-STATIC-LINKING-DEPS.md) | [Tutorial index](README.md#tutorials) | [Skip to Tutorial 5: Using library variants >>](TUTORIAL-5-USING-LIBRARY-VARIANTS.md)

Most applications' build systems are not well-tested against static linking, so you will often run into situations where you need to tweak them a little bit.

Each application's build system is different, so each application requires different tweaks. The general idea is that your compilation should should modify the application's build system in such a way that it works. This tutorial serves as an example: we will show you how to tweak Nginx's build system.

## Problem 1: Nginx's OpenSSL detection

One of the problems in the Nginx build system is that it is able to detect OpenSSL's libcrypto library (for cryptographic algorithms), but fails to detect its libssl library (for SSL/TLS support). Because of this, it is not possible to compile Nginx with HTTPS support. Consider what happens if we were to try to run Nginx's configure script (inside Holy Build Box) with `--with-http_ssl_module`:

    + ./configure --without-http_rewrite_module --with-http_ssl_module
    ...
    checking for OpenSSL library ... not found

    ./configure: error: SSL modules require the OpenSSL library.
    You can either do not enable the modules, or install the OpenSSL library
    into the system, or build the OpenSSL library statically from the source
    with nginx by using --with-openssl=<path> option.

### Analyzing the problem

The best way to analyze the problem is by entering the Holy Build Box container, running the compilation script, then check whether the build system left any logs files that we can use to further analyze the problem.

Let's first update `compile.sh` so that the configure script is called with `--with-http_ssl_module`:

    ./configure --without-http_rewrite_module --with-http_ssl_module

Next, enter the container, invoke the compilation script and verify that the Nginx configure script bails out with an error. We assume that `nginx-1.8.0.tar.gz` from [tutorial 3](TUTORIAL-3-STATIC-LINKING-DEPS.md) is still in the current working directory.

    $ docker run -t -i --rm \
      -v `pwd`:/io \
      phusion/holy-build-box-64:latest \
      bash

    container# bash /io/compile.sh
    ...
    ./configure: error: ...

    container#

Most build systems log the reason why a configure check failed. Autotools log all checks to `config.log`. Nginx's build system is not written in autotools, but if you look around inside the Nginx source directory (`/nginx-1.8.0`) you will eventually find a file `objs/autoconf.err`. That is where the Nginx build system logs to. Let's look inside the file.

    container# cd nginx-1.8.0
    container# cat objs/autoconf.err

Towards the end of the file, we encounter a bunch of errors:

    checking for OpenSSL library

    /hbb_exe/lib/libcrypto.a(c_zlib.o): In function `bio_zlib_free':
    (.text+0x6f): undefined reference to `inflateEnd'
    ...
    /hbb_exe/lib/libcrypto.a(dso_dlfcn.o): In function `dlfcn_globallookup':
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
    cc -O2 -fvisibility=hidden -I/hbb_exe/include -L/hbb_exe/lib -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64 -o objs/autotest objs/autotest.c -lssl -lcrypto

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

Now that you are done analyzing the problem, you can exit the container shell.

    container# exit

### Fixing the build system

We fix this problem by modifying `auto/lib/openssl/conf` so that it compiles the test program with `-lz -ldl`. The best place to do this is in the compilation script, right after extracting the Nginx source code. Before the `./configure` invocation, insert:

    sed -i 's|-lssl -lcrypto|-lssl -lcrypto -lz -ldl|' auto/lib/openssl/conf

Now test the script:

    docker run -t -i --rm \
      -v `pwd`:/io \
      phusion/holy-build-box-64:latest \
      bash /io/compile.sh

You should see that the configure script succeeds in detecting OpenSSL this time:

    + ./configure --without-http_rewrite_module --with-http_ssl_module
    ...
    checking for OpenSSL library ... found

### Verifying the binary

Verify that the compiled Nginx binary works and that it is compiled with SSL support:

    $ ./nginx -V
    nginx version: nginx/1.8.0
    built with OpenSSL 1.0.2d 9 Jul 2015
    TLS SNI support enabled

Finally, verify that it is not dynamically linked to any [non-essential libraries](ESSENTIAL-SYSTEM-LIBRARIES.md):

    $ ldd nginx
        linux-vdso.so.1 =>  (0x00007ffddb4fd000)
        libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fa531b61000)
        libcrypt.so.1 => /lib/x86_64-linux-gnu/libcrypt.so.1 (0x00007fa531928000)
        libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fa531724000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fa53135f000)
        /lib64/ld-linux-x86-64.so.2 (0x00007fa531d7f000)

## Problem 2: `$LDFLAGS` is not respected

Another problem is that the Nginx build system does not respect `$LDFLAGS`.

If you look closely at the output of the compilation script, you will see that the Nginx build system invokes the compiler like this:

    cc -c -O2 -fvisibility=hidden -I/hbb_exe/include -L/hbb_exe/lib    -I src/core -I src/event -I src/event/modules -I src/os/unix -I objs \
        -o objs/src/core/ngx_log.o \
        src/core/ngx_log

Notice the `-O2 -fvisibility=hidden -I/hbb_exe/include -L/hbb_exe/lib` part. This is the value of the `$CFLAGS` environment variable (as you have seen in [tutorial 1](TUTORIAL-1-BASICS.md)), so the Nginx build system passed that environment variable to the compiler, just as we wanted.

However, if you look a bit further at how Nginx links the executable, that doesn't look so good:

    cc -o objs/nginx \
        objs/src/core/nginx.o \
        ...
        objs/ngx_modules.o \
        -lpthread -lcrypt -lssl -lcrypto -lz -ldl -ldl -lz

Nginx did not pass the value of `$LDFLAGS` -- which is `-L/hbb_exe/lib` -- to the linker at all!

Until now, this hasn't been much of a problem. `$LDFLAGS` only contains a `-L` parameter. The Holy Build Box environment also sets the `LIBRARY_PATH` environment variable, so the linker can still find the Holy Build Box static libraries. However, as you will learn in [tutorial 5](TUTORIAL-5-LIBRARY-VARIANTS.md), we provide alternative library variants where `$LDFLAGS` can contain much more than just `-L`. So we need to find a way to make Nginx's build system pass our `$LDFLAGS`.

### Fixing the build system

One way to fix this is by editing the Makefile. However this should be considered the "nuclear option" -- something to be done when you have no other choice. If Nginx provides a way for us to pass additional linker flags, then we should use that.

If we run the Nginx configure script with `--help`, we find just what we need:

    $ ./configure --help
    ...
      --with-ld-opt=OPTIONS              set additional linker options
    ...

So we modify `compile.sh` and change the configure invocation to:

    ./configure --without-http_rewrite_module --with-http_ssl_module --with-ld-opt="$LDFLAGS"

Notice the quotes around `$LDFLAGS`. This ensures that Bash considers `$LDFLAGS` to be a single argument, despite the fact that it contains spaces.

Now test the script:

    docker run -t -i --rm \
      -v `pwd`:/io \
      phusion/holy-build-box-64:latest \
      bash /io/compile.sh

You should see that linker flags are now passed properly:

    cc -c -O2 -fvisibility=hidden -I/hbb_exe/include -L/hbb_exe/lib    -I src/core -I src/event -I src/event/modules -I src/os/unix -I objs \
        -o objs/ngx_modules.o \
        objs/ngx_modules.c
        ...
        objs/ngx_modules.o \
        -L/hbb_exe/lib -lpthread -lcrypt -lssl -lcrypto -lz -ldl -ldl -lz

## The entire compilation script

~~~bash
#!/bin/bash
set -e

# Activate Holy Build Box environment.
source /hbb_exe/activate

set -x

# Extract and enter source
tar xzf /io/nginx-1.8.0.tar.gz
cd nginx-1.8.0

# Compile
sed -i 's|-lssl -lcrypto|-lssl -lcrypto -lz -ldl|' auto/lib/openssl/conf
./configure --without-http_rewrite_module --with-http_ssl_module --with-ld-opt="$LDFLAGS"
make
make install

# Copy result to host
cp /usr/local/nginx/sbin/nginx /io/
~~~

## Conclusion

You have now seen an example of how a program's build system can be tweaked to allow proper static linking. Next up, we will introduce you to the different library variants that Holy Build Box provides.

[Tutorial 5: Using library variants >>](TUTORIAL-5-USING-LIBRARY-VARIANTS.md)
