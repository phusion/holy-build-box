# Tutorial 7: Verifying binary portability with libcheck

[<< Back to Tutorial 6: Introducing additional static libraries](TUTORIAL-6-ADDITIONAL-STATIC-LIBS.md) | [Tutorial index](README.md#tutorials)

Throughout this tutorial set, we have taught you how to statically link your application to their dependencies. However it is easy to make a mistake and accidentally dynamically link to a dependency. Holy Build Box provides a tool -- `libcheck` -- which helps you with checking whether your binary is linked to any [non-essential libraries](ESSENTIAL-SYSTEM-LIBRARIES.md).

## Using libcheck

The `libcheck` command can be found inside the Holy Build Box environment. Its usage format is:

    libcheck <FILES>

For example, let's compile the hello world from [tutorial 1](TUTORIAL-1-BASICS.md), while dynamically linking it to zlib:

    docker run -t -i --rm \
      -v `pwd`:/io \
      phusion/holy-build-box-64:latest \
      gcc /io/hello.c -o /io/hello -lz

Use `ldd` to verify that it is indeed dynamically linked to zlib:

    $ ldd hello
    TODO

If you invoke libcheck, it should complain about this fact:

    $ docker run -t -i --rm \
      -v `pwd`:/io \
      phusion/holy-build-box-64:latest \
      /hbb_nopic/activate-exec \
      libcheck /io/hello
    TODO

## Adding libcheck to your compilation script

We recommend calling `libcheck` from your compilation script, so that you are warned about potential issues. For example, here is how the Nginx compilation script would look like:

~~~bash
#!/bin/bash
set -e

# Activate Holy Build Box environment.
source /hbb_nopic/activate

set -x

# Install static PCRE
tar xzf /io/pcre-XXX.tar.gz
cd pcre-XXX.tar.gz
./configure --prefix=/hbb_deadstrip_hardened_pie
make
make install
cd ..

# Extract and enter source
tar xzf /io/nginx-1.8.0.tar.gz
cd nginx-1.8.0

# Compile
sed -i 's|-lssl -lcrypto|-lssl -lcrypto -lz -ldl|' auto/lib/openssl/conf
./configure --with-http_ssl_module
make
make install

# Verify result
libcheck /usr/local/nginx/sbin/nginx

# Copy result to host
cp /usr/local/nginx/sbin/nginx /io/
~~~

## Conclusion

Congratulations, you have reached the end of the tutorials! You may not be interested in reading the [guides](README.md#guides).

Happy building.
