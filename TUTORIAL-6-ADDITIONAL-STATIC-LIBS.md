# Tutorial 6: Introducing additional static libraries

[<< Back to Tutorial 5: Library variants](TUTORIAL-5-LIBRARY-VARIANTS.md) | [Tutorial index](README.md#tutorials) | [Skip to Tutorial 7: Verifying binary portability with libcheck >>](TUTORIAL-7-VERIFYING-PORTABILITY-WITH-LIBCHECK.md)

Although Holy Build Box includes a number of static libraries, your application may need additional static libraries. Although it is tempting to install them with `yum`, it is not the approach we recommend. The static libraries provided by CentOS 5 are sub-optimal for the following reasons:

 1. They are not compiled with `-fvisibility=hidden`. This compilation flag reduces the amount unnecessary of symbol text inside the executable, making it smaller.

 2. They are not suitable if your goal is to link static libraries into a dynamic library, as is the case with e.g. Ruby native extensions and NPM native extensions.

   For one, these static libraries not compiled with `-fPIC`, which is required for dynamic libraries.

   Second, these static libraries are not compiled with `-fvisibility=hidden`. If the final application loads multiple dynamic libraries, and two or more of those dynamic libraries are linked to different versions of the same static libraries, then the different copies of those static libraries will conflict with each other. `-fvisibility=hidden` prevents that.

 3. If you use the `deadstrip_hardened_pie` variant, then note that the static libraries provided by CentOS may not be compiled with security hardening flags, and are certainly not compiled with dead-code elimination enabled.

So we recommend that you compile from source any static libraries that are not included with Holy Build Box. Furthermore, the flags used to compile these static libraries should match the flags for the currently active [library variant](TUTORIAL-5-LIBRARY-VARIANTS.md).

Only reasons #2 and #3 *require* you to compile static libraries from source. If #2 and #3 do not apply to you, then you are free to install static libraries from YUM, as long as you don't care about executable size.

## Example: compiling Nginx with PCRE

Let's suppose that you want to compile Nginx with the `rewrite_module` enabled. This module requires PCRE, which Holy Build Box does not include. You also want to compile Nginx with the `deadstrip_hardened_pie` variant.

First, download PCRE:

    TODO

Insert the following code into `compile.sh`, right after the `source` call:

~~~bash
# Install static PCRE
tar xzf /io/pcre-XXX.tar.gz
cd pcre-XXX.tar.gz
./configure --prefix=/hbb_deadstrip_hardened_pie
make
make install
cd ..
~~~

Note that we configure PCRE to install the active library variant's directory (`/hbb_deadstrip_hardened_pie`). The Holy Build Box environment variables are set up in such a way that your compiler looks for libraries in there first, so installing PCRE to that prefix will ensure that the Nginx build system can find PCRE.

The PCRE build system respects the environment variables set by the Holy Build Box activation script, so we know that PCRE is compiled with the right flags.

Remove the `--without-rewrite_module` parameter from the Nginx configure command:

    ./configure --with-http_ssl_module

## Verifying that it works

Invoke the compilation script:

    docker run -t -i --rm \
      -v `pwd`:/io \
      phusion/holy-build-box-64:latest \
      bash /io/compile.sh
    

Then verify that Nginx is indeed compiled with the `rewrite_module` enabled:

    TODO

## The entire compilation script

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

# Copy result to host
cp /usr/local/nginx/sbin/nginx /io/
~~~

## Conclusion

You have now learned how to compile additional static libraries. Next, you will learn how to automatically verify that your binary is indeed portable (not accidentally dynamically linked to non-essential libraries).

[Tutorial 7: Verifying binary portability with libcheck](TUTORIAL-7-VERIFYING-PORTABILITY-WITH-LIBCHECK.md)
