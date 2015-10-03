# Tutorial 2: Compilation via a script

[<< Back to Tutorial 1: Basics](TUTORIAL-1-BASICS.md) | [Tutorial index](README.md#tutorials) | [Skip to Tutorial 3: Static linking dependencies >>](TUTORIAL-3-STATIC-LINKING-DEPS.md)

Besides very simple use cases, compiling your application probably takes more than just running a single gcc command. To support more advanced cases, you should write a script in which you call the commands that are necessary for compiling your application.

The principle behind using Holy Build Box with such a script is as follows:

 1. Run a Holy Build Box Docker container, with a volume mount to a directory on the host.
 2. The volume mount is to contain the application's source code.
 3. Run the script inside the container.
 4. The script copies the resulting binaries to the volume mount.

## Preparation

Consider that most applications are compiled using the well-known autotools commands:

    ./configure &&
      make &&
      make install

One such program is [GNU hello](https://www.gnu.org/software/hello/). GNU hello is packaged inside a tarball `hello-2.10.tar.gz`. Let's download it first:

    curl -LO http://ftp.gnu.org/gnu/hello/hello-2.10.tar.gz

## Writing the compilation script

Next, write a script that extracts the tarball and runs the compilation commands. Let's call that script `compile.sh`:

~~~
#!/bin/bash
set -e

# Activate Holy Build Box environment.
source /hbb_exe/activate

set -x

# Extract and enter source
tar xzf /io/hello-2.10.tar.gz
cd hello-2.10

# Compile
./configure
make
make install

# Copy result to host
cp /usr/local/bin/hello /io/
~~~

## Invoking the compilation script

Put `compile.sh` in the same directory as `hello-2.10.tar.gz`. Then invoke the Holy Build Box environment:

    docker run -t -i --rm \
      -v `pwd`:/io \
      phusion/holy-build-box-64:latest \
      bash /io/compile.sh

## Verify that it works

Afterwards, you should find a `hello` binary in your current working directory.

    $ ./hello
    Hello, world!

## The Holy Build Box environment activation script

Note the line `source /hbb_exe/activate`. In tutorial 1, you learned about the `activate-exec` command and that it's important to activate the Holy Build Box environment before doing anything else. So why do we use `activate` now instead of `activate-exec`? And what's with the `source` command?

The `activate` script also sets Holy Build Box environment variables, just like `activate-exec`. The difference is that `activate` is designed to be "sourced" from Bash -- to be directly executed within the same Bash process, as opposed to executing it as a separate process. This is necessary because environment variables in Unix are only activated inside the originating process and child processes -- they do not propagate to parent processes or other processes.

Instead of sourcing the `activate` script from within `compile.sh`, you could also wrap `compile.sh` around `activate-exec`, like this:

    docker run -t -i --rm \
      -v `pwd`:/io \
      phusion/holy-build-box-64:latest \
      /hbb_exe/activate-exec \
      bash /io/compile.sh

This is an equally valid approach. Throughout this tutorial series, we will be using the `source` approach, but the choice is yours.

## $CFLAGS and $LDFLAGS

In tutorial 1, you had to pass `$CFLAGS` and `$LDFLAGS` to the compiler. So why didn't you have to do it this time?

It is because GNU hello is using the autotools build system, which automatically passes `$CFLAGS` and `$LDFLAGS` to the compiler and the linker. This is great because so many applications use autotools. However, not every application uses autotools, so sometimes we will have to tweak the build system a little bit so that `$CFLAGS` and `$LDFLAGS` are passed.

## Conclusion

You have now learned how to compile an application inside the Holy Build Box environment. Next up, we will learn how to statically link to dependencies.

[Tutorial 3: Static linking dependencies >>](TUTORIAL-3-STATIC-LINKING-DEPS.md)
