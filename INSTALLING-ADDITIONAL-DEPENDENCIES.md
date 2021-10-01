# Installing additional dependencies

Any non-trivial application has dependencies. Although Holy Build Box supplies a number of popular dependencies, there will probably come a time when you need to install additional dependencies. This tutorial teaches you how to do that.

**Table of contents**

 * [The high-level approach](#the-high-level-approach)
 * [Creating an extended Holy Build Box image](#creating-an-extended-holy-build-box-image)
 * [Using the extended image](#using-the-extended-image)
 * [Installing dependencies that are applications, through YUM](#installing-dependencies-that-are-applications-through-yum)
 * [Installing dependencies that are applications, from source](#installing-dependencies-that-are-applications-from-source)
 * [Installing dependencies that are libraries](#installing-dependencies-that-are-libraries)

## The high-level approach

The first question that needs to be answered is: where does installing dependencies fit in the overall build process?

One possible answer is to install dependencies as part of the application build process. This is what we've shown you in [Tutorial 6: Introducing additional static libraries](TUTORIAL-6-ADDITIONAL-STATIC-LIBS.md). In this case, you simply extend your application build script with instructions to install dependencies.

While this is a perfectly sound method, it is not the one we recommend. Dependencies are something that rarely change compared to applications themselves, so if you build your application many times then you also end up rebuilding your dependencies many times, which wastes a lot of time (although this is somewhat mitigated by [using ccache](CACHING-WITH-CCACHE.md)).

So instead, we advocate an approach in which you extend the Holy Build Box Docker image with your own dependencies. You then use this extended image (instead of the original Holy Build Box image) to build your application.

## Creating an extended Holy Build Box image

To extend the Holy Build Box image you need to create a Dockerfile. This Dockerfile needs to set the Holy Build Box image as its base, and needs to run instructions to install your desired dependencies.

Suppose that your application is called `foo`. Let's start by making a directory for your project and adding a Dockerfile and a dependency install script:

    $ mkdir foo_builder
    $ cd foo_builder
    $ editor Dockerfile
    $ editor install-deps.sh

Here's how your Dockerfile should look like:

~~~
# Note: this example assumes Holy Build Box 3.0.
# Specify the actual desired version here. You can see the list
# of available versions in our Changelog:
# https://github.com/FooBarWidget/holy-build-box/blob/master/Changelog.md
FROM foobarwidget/holy-build-box-x64:3.0
ADD install-deps.sh /install-deps.sh
RUN bash /install-deps.sh && rm -f /install-deps.sh
~~~

Your install-deps.sh is to contain instructions for actually installing the desired dependencies:

~~~bash
#!/bin/bash
set -e

...your instructions here...
~~~

What do you need to take care of inside this script? We'll cover that in subsequent subsections. For now, you just need to know that you can build your Docker image using `docker build`:

    $ docker build -t your_organization/buildbox .

This will create a Docker image named `your_organization/buildbox`. The image contains the original Holy Build Box, plus whatever you chose to install in your install-deps.sh. You can customize the name as you see fit, but throughout the rest of this guide we shall assume that the image name is `your_organization/buildbox`.

## Using the extended image

Now that you have an extended image, you can use it in the same way as the original Holy Build Box image was used to compile your application. Suppose that you want to compile the hello world program from [tutorial 2](TUTORIAL-2-COMPILATION-SCRIPT.md). You need to run:

    docker run -t -i --rm \
      -v `pwd`:/io \
      your_organization/buildbox \
      bash /io/compile.sh

Note that the only thing that changed compared to tutorial 2 is the image name.

## Installing dependencies that are applications, through YUM

If the dependency you want to install is an application, then the preferred way to install that is via YUM. For example, suppose that your application's build system requires the [dialog](https://en.wikipedia.org/wiki/Dialog_(software)) tool (because it may need to display a warning dialog) and the [Ruby](http://www.ruby-lang.org) programming language (because it uses the `rake` tool, the Ruby counterpart of `make`). Then here's what you should put in your install-deps.sh:

~~~bash
yum install -y dialog ruby
~~~

## Installing dependencies that are applications, from source

It is not always a good idea, or even a possibility, to install an application-type dependency via YUM. YUM may not contain the application you need, or may not contain the version you need. In that case you will have to install the dependency from source.

Here's what you need to put in your install-deps.sh to install dialog from source, for example:

~~~bash
#!/bin/bash
set -ex

# (1) Activate the Holy Build Box
# **dependency installation** environment.
source /hbb/activate

# (2) Install dependencies needed by dialog.
yum install -y ncurses-devel

# Download and extract dialog.
cd /tmp
curl --fail -L -O http://invisible-island.net/datafiles/release/dialog.tar.gz
tar xzf dialog.tar.gz
cd dialog*

# (3) Install dialog.
./configure --prefix=/hbb
make
make install-strip
~~~

Some code in the above example script deserve special attention:

 1. Holy Build Box contains a special environment for the purpose of installing application-type dependencies. The "Activate the Holy Build Box dependency installation environment" code activates this environment. For example, it sets various environment variables so that the script can find a suitable compiler.

    Note that we did not activate any of the [library variant environments](TUTORIAL-5-USING-LIBRARY-VARIANTS.md). That's because the library variant environments are meant for compiling the final application, with specific static linking flags. A dependency application, that we only use for the purpose of compiling the final application, does not need to be portable and so does not need to be statically linked to anything (dynamic linking is fine). The dependency installation environment does not contain any compiler flags for static linking.

 2. Your application-type dependency may have dependencies on its own. You should install these with YUM when possible. If that's not possible then you need to install them from source, as documented in subsection [Installing dependencies that are libraries](#installing-dependencies-that-are-libraries).

 3. Here we configure 'dialog' to install to the prefix /hbb. This is a good default place to install to because the Holy Build Box activation scripts ensure that /hbb/bin is in PATH, that libraries in /hbb/lib are accessible, etc. But you are not obliged to install to /hbb: you could also choose to install to /usr/local or whereever you want, as long as you ensure that whatever you install is accessible by your build scripts.

## Installing dependencies that are libraries

If the dependency you want to install is a library, then you have several options:

 * If this library will be (directly or indirectly) linked into the final application that you want to compile, then you *must* install this library from source, as a static library, using the same library variant that you will use to compile the final application. As we explained in [tutorial 6](TUTORIAL-6-ADDITIONAL-STATIC-LIBS.md), don't install such libraries from YUM.

   You can learn more about compiling such libraries in [Tutorial 6: Introducing additional static libraries](TUTORIAL-6-ADDITIONAL-STATIC-LIBS.md).

 * If this library will not be linked into the final application, and you only need it in order to compile another dependency, then you may install it either from YUM or from source. The ncurses-devel dependency in the previous example is a good example of this.

   To compile such libraries, use the "dependencies installation environment" as documented in earlier in this guide. Do not use any library variants.
