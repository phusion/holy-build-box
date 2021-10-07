# Tutorial 1: Basics

[Tutorial index](README.md#tutorials) | [Skip to Tutorial 2: Compilation via a script >>](TUTORIAL-2-COMPILATION-SCRIPT.md)

Welcome to the Holy Build Box introductory tutorial. This tutorial serves to give you a feel of what Holy Build Box is and how it works.

## Prerequisite knowledge

Holy Build Box is based on Docker. So to use Holy Build Box, you must be at least adept at using Docker. Please [read the Docker documentation](https://docs.docker.com/) first. If you are not familiar with Docker, then these tutorials will probably make little sense to you.

We also assume that you are adept at using the C/C++ compilation toolchain. You should be comfortable with using the compiler, make, autotools, environment variables etc. Holy Build Box will probably make little sense to you otherwise.

## The environment

Holy Build Box consists of one Docker image: `foobarwidget/holy-build-box-x64`, for building x86\_64 binaries.

> Support for x86 was dropped in Holy Build Box 3. Support for other architectures may be introduced in the future.

Start a Bash shell inside the Holy Build Box environment so that you can look around and inspect things:

    $ docker run -t -i --rm ghcr.io/foobarwidget/holy-build-box-x64 bash
    container#

When you are done, type `exit` to exit the shell:

    container# exit

## Compilation

You can compile a binary using Holy Build Box by invoking `gcc` or `g++` inside an image.

For example, suppose that you have a `hello.c` in the current working directory:

~~~c
#include <stdio.h>

int
main() {
    printf("hello world\n");
    return 0;
}
~~~

Compile it with:

    docker run -t -i --rm \
      -v `pwd`:/io \
      ghcr.io/foobarwidget/holy-build-box-x64 \
      /hbb_exe/activate-exec \
      bash -x -c 'gcc $CFLAGS /io/hello.c -o /io/hello $LDFLAGS'

Verify that it works:

    $ ./hello
    hello world

## Holy Build Box environment activation

Note that `gcc` is preceded by a "magical" invocation to `/hbb_exe/activate-exec`. What is this?

The `activate-exec` command sets various environment variables -- such as `PATH`, `CFLAGS` and `C_INCLUDE_PATH` -- so that the compiler toolchain can find various software that is included in Holy Build Box. It then executes the command specified in its parameters -- that is, gcc.

The reason why this is needed because some of the software inside the Holy Build Box environment is not installed via YUM, but compiled from source instead. They are installed in `/hbb*`, so the compiler toolchain won't find them by default.

Activating the Holy Build Box environment is important. Without activation, a large part of Holy Build Box does not work. Holy Build Box should be activated as early as possible.

This also explains why the gcc call is wrapped inside a `bash` call, and why inside the Bash command we reference `$CFLAGS` and `$LDFLAGS`. We want the compiler to respect the Holy Build Box compilation and linker flags.

The various `/hbb*` directories and the environment variables are explained in the [Environment structure](ENVIRONMENT-STRUCTURE.md) guide and in [Tutorial 5: Using library variants](TUTORIAL-5-LIBRARY-VARIANTS.md).

### Environment variable values

We encourage you to inspect the environment variables set by the Holy Build Box activation script:

    $ docker run -t -i --rm \
      ghcr.io/foobarwidget/holy-build-box-x64 \
      /hbb_exe/activate-exec \
      bash
    Holy build box activated
    Prefix: /hbb_exe
    CFLAGS: -O2 -fvisibility=hidden -I/hbb_exe/include
    LDFLAGS: -L/hbb_exe -static-libstdc++
    STATICLIB_CFLAGS: -O2 -fvisibility=hidden -I/hbb_exe/include
    SHLIB_CFLAGS: -O2 -fvisibility=hidden -I/hbb_exe/include
    SHLIB_LDFLAGS: -L/hbb_exe/lib

    container# echo $CFLAGS
    -O2 -fvisibility=hidden -I/hbb_exe/include
    container# echo $LDFLAGS
    -L/hbb_exe -static-libstdc++
    container# exit

## Conclusion

Please head to [Tutorial 2: Compilation via a script](TUTORIAL-2-COMPILATION-SCRIPT.md).
