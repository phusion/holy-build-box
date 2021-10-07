# Tutorial 3: Static linking to dependencies

[<< Back to Tutorial 2: Compilation via a script](TUTORIAL-2-COMPILATION-SCRIPT.md) | [Tutorial index](README.md#tutorials) | [Skip to Tutorial 4: Tweaking the application's build system >>](TUTORIAL-4-TWEAKING-APPS.md)

Any non-trivial application has dependencies. As explained in the [introduction](README.md#problem-introduction), our recommended approach is to statically link applications to all their dependencies, except for [essential system dependencies](ESSENTIAL-SYSTEM-LIBRARIES.md) such as glibc, libpthread, libm etc.

In this tutorial, we will compile [Nginx](http://nginx.org) using Holy Build Box. At the very least, Nginx depends on zlib (for compression) and OpenSSL (for cryptographic operations). Holy Build Box happens to include static versions of both libraries, so in this tutorial we will show you how to statically link Nginx to them.

Does your application depend on something that is not included by default in Holy Build Box? In [tutorial 6](TUTORIAL-6-ADDITIONAL-STATIC-LIBS.md) and in the [Installing additional dependencies](INSTALLING-ADDITIONAL-DEPENDENCIES.md) guide we will cover installing your own dependencies.

## Writing the compilation script

Your compilation script `compile.sh` should look as follows:

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
./configure --without-http_rewrite_module
make
make install

# Copy result to host
cp /usr/local/nginx/sbin/nginx /io/
~~~

Note that we configure the Nginx source with `--without-http_rewrite_module`, because otherwise Nginx requires PCRE. For the sake of keeping this tutorial simple, we won't deal with PCRE.

## Invoking the compilation script

Download Nginx and invoke the script:

    curl -LO http://nginx.org/download/nginx-1.8.0.tar.gz
    docker run -t -i --rm \
      -v `pwd`:/io \
      ghcr.io/foobarwidget/holy-build-box-x64 \
      bash /io/compile.sh

## Verify that it works

Finally, verify that Nginx works and is not dynamically linked to any non-essential system libraries:

    $ ./nginx -v
    nginx version: nginx/1.8.0
    $ ldd nginx
        linux-vdso.so.1 =>  (0x00007ffc1ffec000)
        libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f71eb530000)
        libcrypt.so.1 => /lib/x86_64-linux-gnu/libcrypt.so.1 (0x00007f71eb2f7000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f71eaf32000)
        /lib64/ld-linux-x86-64.so.2 (0x00007f71eb74e000)

## Why is Nginx not dynamically linked to OpenSSL?

If you have inspected the Holy Build Box environment, then you may have noticed that it includes a dynamic version of OpenSSL in /usr/lib. So why was Nginx linked to the static OpenSSL in /hbb_exe/lib, instead of the dynamic OpenSSL in /usr/lib?

It is because the Holy Build Box activation script (`/hbb_exe/activate`) sets environment variables so that the compiler toolchain looks in /hbb_exe/lib first. Some of the environment variables set are:

    export LIBRARY_PATH='/hbb_exe/lib'
    export LDFLAGS='-L/hbb_exe/lib -static-libstdc++'

## Conclusion

You have now learned the basics of statically linking dependencies. Next up, we will consider how to deal with applications whose build system don't let you perform static linking so easily.

[Tutorial 4: Tweaking the application's build system >>](TUTORIAL-4-TWEAKING-APPS.md)
