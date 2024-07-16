# Tutorial 5: Using library variants

[<< Back to Tutorial 4: Tweaking the application's build system](TUTORIAL-4-TWEAKING-APPS.md) | [Tutorial index](README.md#tutorials) | [Skip to Tutorial 6: Introducing additional static libraries >>](TUTORIAL-6-ADDITIONAL-STATIC-LIBS.md)

Holy Build Box provides [several different variants](LIBRARY-VARIANTS.md) of its static libraries, each compiled with different compilation flags and thus meant for different situations. So we in the tutorials we have only used the `exe` variant. In this tutorial, we will show you how to use the `exe_gc_hardened`. The provided static libraries this variant are compiled with security hardening flags and dead code elimination flags.

Your application must also be compiled with matching compilation flags. The activation script of each variant sets `CFLAGS`, `CXXFLAGS` [and other environment variables](ENVIRONMENT-STRUCTURE.md), which most applications' build system will automatically pick up.

## Example: compiling Nginx with the `exe_gc_hardened`

Let's see what happens if we compile Nginx with the `exe_gc_hardened` variant. The Nginx binary that we compiled in [tutorial 4](TUTORIAL-4-TWEAKING-APPS.md) was 3.1 MB after stripping its debugging symbols:

    $ strip --strip-all nginx
    $ ls -lh nginx
    -rwxr-xr-x 1 hongli hongli 2,7M sep 28 13:43 nginx*

It also wasn't compiled with any security hardening flags:

    $ docker run -t -i --rm \
      -v `pwd`/nginx:/exe:ro \
      ghcr.io/phusion/holy-build-box/hbb-64 \
      /hbb_exe_gc_hardened/activate-exec \
      hardening-check -b /exe
    ...
    Position Independent Executable: no, normal executable!
    Stack protected: no, not found!
    Fortify Source functions: no, only unprotected functions found!
    Read-only relocations: no, not found!
    Immediate binding: no, not found! (ignored)

Modify the compilation script to load `/hbb_exe_gc_hardened/activate` instead of `/hbb_exe/activate`. Change this line...

    source /hbb_exe/activate

...to:

    source /hbb_exe_gc_hardened/activate

Then invoke the compilation script:

    docker run -t -i --rm \
      -v `pwd`:/io \
      ghcr.io/phusion/holy-build-box/hbb-64 \
      bash /io/compile.sh

Let's take a look at the Nginx binary now:

    $ strip --strip-all nginx
    $ ls -lh nginx
    -rwxr-xr-x 1 hongli hongli 2,6M sep 28 13:44 nginx*

The Nginx binary is now 2.8 MB. We saved about 300 KB.

We can also see that the security hardening flag are enabled inside the binary:

    $ docker run -t -i --rm \
      -v `pwd`/nginx:/exe:ro \
      ghcr.io/phusion/holy-build-box/hbb-64 \
      /hbb_exe_gc_hardened/activate-exec \
      hardening-check -b /exe
    ...
    Position Independent Executable: yes
    Stack protected: yes
    Fortify Source functions: yes (some protected functions found)
    Read-only relocations: yes
    Immediate binding: no, not found! (ignored)

**Tip**: when using the `exe_gc_hardened`, we recommend that you call `hardening-check` from your compilation script after compilation is finished.

## The entire compilation script

~~~bash
#!/bin/bash
set -e

# Activate Holy Build Box environment.
source /hbb_exe_gc_hardened/activate

set -x

# Extract and enter source
tar xzf /io/nginx-1.8.0.tar.gz
cd nginx-1.8.0

# Compile
sed -i 's|-lssl -lcrypto|-lssl -lcrypto -lz -ldl|' auto/lib/openssl/conf
./configure --without-http_rewrite_module --with-http_ssl_module --with-ld-opt="$LDFLAGS"
make
make install

# Verify result
hardening-check -b /usr/local/nginx/sbin/nginx

# Copy result to host
cp /usr/local/nginx/sbin/nginx /io/
~~~

## Conclusion

You have now learned about the different library variants. Next up, you will learn what to do if your application has additional dependencies that are not included in Holy Build Box.

[Tutorial 6: Introducing additional static libraries >>](TUTORIAL-6-ADDITIONAL-STATIC-LIBS.md)
