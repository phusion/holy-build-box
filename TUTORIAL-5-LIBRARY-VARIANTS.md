# Tutorial 5: Library variants

[<< Back to Tutorial 4: Tweaking the application's build system](TUTORIAL-4-TWEAKING-APPS.md) | [Tutorial index](README.md#tutorials) | [Skip to Tutorial 6: Introducing additional static libraries >>](TUTORIAL-6-ADDITIONAL-STATIC-LIBS.md)

Holy Build Box provides 3 different variants of its static libraries, each compiled with different compilation flags.

Your application must also be compiled with matching compilation flags. The activation script of each variant sets `CFLAGS`, `CXXFLAGS` and other environment variables, which most applications' build system will automatically pick up.

## Available variants

 * **`nopic`**

   This is the variant that you have worked with so far in these tutorials. This is a good default variant to use. No special compilation options are used.

   Compilation flags: `-O2 -fvisibility=hidden`<br>
   Activation command: `/hbb_nopic/activate-exec`<br>
   Activation source script: `/hbb_nopic/activate`

 * **`pic`**

   This variant is compiled with `-fPIC`. This variant is useful if you plan on linking static libraries into dynamic libraries, e.g. when compiling Ruby native extensions or NPM native extensions.

   Compilation flags: `-O2 -fvisibility=hidden -fPIC`<br>
   Activation command: `/hbb_pic/activate-exec`<br>
   Activation source script: `/hbb_pic/activate`

 * **`deadstrip_hardened_pie`**

   This variant is compiled with security hardening flags and with dead-code elimination flags. This variant is especially suitable for compiling binaries for use in production environments.

   The following security hardening features are enabled:

    * Protection against stack overflows and stack smashing
    * Extra bounds checking in common functions
    * Load time address randomization
    * Read-only global offset table

   **Warning**: the enabled security features are not compatible with `-O3`.

   The dead-code elimination flags allow the compiler to eliminate unused code, which makes your binaries as small as possible.

   Compilation flags: `-O2 -fvisibility=hidden -ffunction-sections -fdata-sections -fstack-protector -fPIE -D_FORTIFY_SOURCE=2 -Wl,--gc-sections -pie -Wl,-z,relro`<br>
   Activation command: `/deadstrip_hardened_pie/activate-exec`<br>
   Activation source script: `/deadstrip_hardened_pie/activate`

## Example: compiling Nginx with the `deadstrip_hardened_pie`

Let's see what happens if we compile Nginx with the `deadstrip_hardened_pie` variant. The Nginx binary that we compiled in [tutorial 4](TUTORIAL-4-TWEAKING-APPS.md) was x MB after stripping its debugging symbols:

    $ strip --strip-all nginx
    $ ls -lh nginx
    ...

Modify the compilation script to load `/hbb_deadstrip_hardened_pie/activate` instead of `/hbb_nopic/activate`. Change this line...

    source /hbb_nopic/activate

...to:

    source /hbb_deadstrip_hardened_pie/activate

Then invoke the compilation script:

    docker run -t -i --rm \
      -v `pwd`:/io \
      phusion/holy-build-box-64:latest \
      bash /io/compile.sh

Let's take a look at the Nginx binary now:

    $ strip --strip-all nginx
    $ ls -lh nginx
    ...

It is now only x MB! We saved y MB.

We can also see that the security hardening flag are enabled inside the executable:

    TODO

## Conclusion

You have now learned about the different library variants. Next up, you will learn what to do if your application has additional dependencies that are not included in Holy Build Box.

[Tutorial 6: Introducing additional static libraries >>](TUTORIAL-6-ADDITIONAL-STATIC-LIBS.md)
