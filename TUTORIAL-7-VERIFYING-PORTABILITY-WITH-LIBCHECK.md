# Tutorial 7: Verifying binary portability with libcheck

[<< Back to Tutorial 6: Introducing additional static libraries](TUTORIAL-6-ADDITIONAL-STATIC-LIBS.md) | [Tutorial index](README.md#tutorials)

Throughout this tutorial set, we have taught you how to statically link your application to their dependencies. However it is easy to make a mistake and accidentally dynamically link to a dependency. Holy Build Box provides a tool -- `libcheck` -- which helps you with checking whether your binary is linked to any [non-essential libraries](ESSENTIAL-SYSTEM-LIBRARIES.md).

## Using libcheck

The `libcheck` command can be found inside the Holy Build Box environment. Its usage format is:

    libcheck <FILES>

For example, let's compile the hello world from [tutorial 1](TUTORIAL-1-BASICS.md), while dynamically linking it to zlib:

    docker run -t -i --rm \
      -v `pwd`:/io \
      ghcr.io/phusion/holy-build-box/hbb-64 \
      /hbb_exe/activate-exec \
      gcc /io/hello.c -o /io/hello /usr/lib64/libz.so.1

Notice that we don't use activation command `/hbb_exe/activate-exec`.

Use `ldd` to verify that it is indeed dynamically linked to zlib:

    $ ldd hello
        linux-vdso.so.1 =>  (0x00007ffe28054000)
        libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007f216b1ff000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f216ae3a000)
        /lib64/ld-linux-x86-64.so.2 (0x00007f216b418000)

If you invoke libcheck, it should complain about this fact:

    $ docker run -t -i --rm \
      -v `pwd`:/io \
      ghcr.io/phusion/holy-build-box/hbb-64 \
      /hbb_exe/activate-exec \
      libcheck /io/hello
    ...
    /io/hello is linked to non-system libraries: ['/lib64/libz.so.1']

## Adding libcheck to your compilation script

We recommend calling `libcheck` from your compilation script, so that you are warned about potential issues. For example, here is how the Nginx compilation script would look like:

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
libcheck /usr/local/nginx/sbin/nginx

# Copy result to host
cp /usr/local/nginx/sbin/nginx /io/
~~~

## Conclusion

Congratulations, you have reached the end of the tutorials! You may now be interested in reading the [guides](README.md#guides) and the [caveats](README.md#caveats).

Happy building.
