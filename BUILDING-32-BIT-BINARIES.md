# Building 32-bit binaries

Holy Build Box also provides the Docker image `phusion/holy-build-box-32`. This image contains a 32-bit CentOS environment, and is suitable for building 32-bit executables. This image is used in the same way as the 64 variant, BUT you have to prepend any commands with a call to `linux32`. This ensures that all processes inside the container will think that it's running on a 32-bit system, despite the fact that the kernel is 64-bit. If you do not call `linux32`, then some applications' build systems will become confused: they will try to invoke the compiler with 64-bit compilation flags, which of course fails because the actual environment is 32-bit.

For example, instead of invoking this...

    docker run -t -i --rm \
      -v `pwd`:/io \
      phusion/holy-build-box-64:latest \
      bash /io/compile.sh

...invoke this:

    docker run -t -i --rm \
      -v `pwd`:/io \
      phusion/holy-build-box-32:latest \
      linux32 bash /io/compile.sh
