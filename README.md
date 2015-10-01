# System for building cross-distribution Linux binaries

<img src="http://phusion.github.io/holy-build-box/img/logo.png">

Holy Build Box is a system for building "portable" binaries for Linux: binaries that work on pretty much any Linux distribution. This works by providing an easy-to-use compilation environment with an old glibc version. Holy Build Box can produce x86 and x86-64 binaries.

**Resources:**: [Website](http://phusion.github.io/holy-build-box/) | [Issue tracker](https://github.com/phusion/holy-build-box/issues)

**Table of contents**

 * [Problem introduction](#problem-introduction)
   - [Glibc symbols](#glibc-symbols)
   - [Why statically linking to glibc is a bad idea](#why-statically-linking-to-glibc-is-a-bad-idea)
   - [Dynamic libraries](#dynamic-libraries)
 * [Features](#features)
 * [Getting started](#getting-started)
   - [Tutorials](#tutorials)
   - [Guides](#guides)
 * [FAQ](#faq)
   - [Who should be interested in portable Linux binaries?](#who-should-be-interested-in-portable-linux-binaries)
   - [Which operating systems does Holy Build Box support?](#which-operating-systems-does-holy-build-box-support)
   - [Static linking introduces security problems. How do you deal with this?](#static-linking-introduces-security-problems-how-do-you-deal-with-this)
   - [How does Holy Build Box compare to using Docker to package up an application?](#how-does-holy-build-box-compare-to-using-docker-to-package-up-an-application)
   - [How does Holy Build Box compare to Go?](#how-does-holy-build-box-compare-to-go)
   - [Is Holy Build Box suitable for all applications?](#is-holy-build-box-suitable-for-all-applications)
   - [How should I deal with interpreted applications, such as ones written in Ruby, Python or Node.js?](#how-should-i-deal-with-interpreted-applications-such-as-ones-written-in-ruby-python-or-nodejs)
   - [Why the name "Holy Build Box"?](#why-the-name-holy-build-box)

------

## Problem introduction

If you have ever tried to build a C/C++ Linux binary, then you will probably have noticed that it may not run on other Linux distributions, or even other versions of the same Linux distribution. This happens even if your application does not use newer APIs. This is in stark contrast to Windows binaries, which tend to on pretty much every Windows machine. There are many reasons why this is so. This section introduces you to each problem, and whether and how Holy Build Box solves that problem.

### Glibc symbols

The most prominent reason why binaries aren't portable is glibc symbols. When you try to run an older Linux distribution a binary that is compiled on a newer Linux distribution, you may see an error message like this:

    ./foo: /lib/libc.so.6: version `GLIBC_2.11' not found

Each function in glibc -- each *symbol* -- actually has multiple versions. This allows the glibc developers to change the behavior of a function without breaking backwards compatibility with applications that happen to rely on bugs or implementation-specific behavior. During the linking phase, the linker "helpfully" links against the most recent version of the symbol. The thing is, glibc introduces new symbol versions very often, resulting in binaries that will most likely depend on a recent glibc.

The only way to tell the compiler and linker to use older symbol versions is by using linker scripts. However, this requires you to specify the version for each and every symbol, which is an undoable task.

Holy Build Box solves the glibc symbol problem by providing a tightly-controlled build environment that contains an old version of glibc.

### Why statically linking to glibc is a bad idea

The glibc symbol problem can be solved by statically linking to glibc. However, this is not the approach that Holy Build Box advocates. Statically linking to glibc wastes a lot of space. A simple 200 KB program can suddenly become 5 MB.

Statically linking to glibc also introduces various runtime problems. For example, such binaries are not able to call `dlopen()`, so applications which want to load plugins at runtime aren't compatible with this approach.

### Dynamic libraries

Another prominent reason why binaries aren't portable is dynamic libraries. Any non-trivial application has dependencies, but every distribution has different library versions.

It is awkward to ship a binary to users, only for them to discover that they need to install some library first before your binary works. Even if your user accepts that they need to install some library, that still does not fully solve the problem, because newer distributions may ship a newer yet binary-incompatible version of a dependency library. So just compiling your application on an older distribution is not enough.

The solution is to statically link to dependencies. Note that we are *not advocating static linking of everything*: the Holy Build Box approach is to statically link to all dependencies, except for glibc and other system libraries that are found on pretty much every Linux distribution, such as libpthread and libm.

There are some problems with static linking though. Performing static linking as we advocate it, is very awkward on most systems for the following reasons:

 1. Many build system tools are only designed with dynamic linking in mind, and require many tweaks before they work with static linking.

    Example: the default OpenSSL pkg-config entries do not work with static linking at all.

 2. If the build environment is not tightly controlled, then various build systems may pull in too many dependencies.

    Example: suppose that you have installed libssh on your workstation because some utility application that you use requires it. Now suppose that you are trying to produce a portable binary of some third-party application. That application's build system automatically detects whether libssh is installed, and if so, links to it. However, you do not want that application to have SSH functionality. To produce the desired binary, you now need to uninstall libssh, thereby breaking the utility application that you are using.

 3. The static libraries provided by your distribution may not be compiled with the flags you want.

Holy Build Box solves problem #2 by providing a tightly-controlled build environment that is isolated from your host environment. This works through Docker: Holy Build Box is a Docker image.

Holy Build Box partially solves problem #1 and #3 by providing static versions of often-used libraries that tend to be a pain to set up for proper static linking. Holy Build Box even provides multiple versions of these libraries, compiled with different compilation flags.

## Features

### Isolated build environment based on Docker and CentOS 5

The Holy Build Box environment is built on CentOS 5. This allows it to produce binaries that work on pretty much any x86 and x86-64 Linux distribution released since 2007.

The environment is bare-bones with almost nothing installed. Besides the basics, only a compiler toolchain is provided:

 * GCC 4.1.2 (C and C++ support)
 * GNU make
 * pkg-config 0.28
 * ccache 3.2.3
 * CMake 3.3.2
 * Python 2.7.10

### Included static libraries

Holy Build Box also includes static versions of certain libraries. These libraries are more recent than the ones shipped with CentOS 5.

 * zlib 1.2.8
 * OpenSSL 1.0.2d
 * curl and libcurl 7.44.0

These libraries are provided in multiple variants, each compiled with different compilation flags. The different variants will be covered with in [Tutorial 5: Library variants](TUTORIAL-5-LIBRARY-VARIANTS.md).

### Security hardening

Holy Build Box makes it easy to compile your application with special security hardening features:

 * Protection against stack overflows and stack smashing
 * Extra bounds checking in common functions
 * Load time address randomization
 * Read-only global offset table

This is covered in [Tutorial 5: Library variants](TUTORIAL-5-LIBRARY-VARIANTS.md) and in the [Security hardening binaries](SECURITY-HARDENING-BINARIES.md).

## Getting started

<a name="tutorials"></a>

Tutorials:

 * [Tutorial 1: Basics](TUTORIAL-1-BASICS.md)
 * [Tutorial 2: Compilation via a script](TUTORIAL-2-COMPILATION-SCRIPT.md)
 * [Tutorial 3: Static linking to dependencies](TUTORIAL-3-STATIC-LINKING-DEPS.md)
 * [Tutorial 4: Tweaking the application's build system](TUTORIAL-4-TWEAKING-APPS.md)
 * [Tutorial 5: Library variants](TUTORIAL-5-LIBRARY-VARIANTS.md)
 * [Tutorial 6: Introducing additional static libraries](TUTORIAL-6-ADDITIONAL-STATIC-LIBS.md)
 * [Tutorial 7: Verifying binary portability with libcheck](TUTORIAL-7-VERIFYING-PORTABILITY-WITH-LIBCHECK.md)

<a name="guides"></a>

Guides:

 * [Environment structure](ENVIRONMENT-STRUCTURE.md)
 * [Which system libraries are considered essential?](ESSENTIAL-SYSTEM-LIBRARIES.md)
 * [Security hardening binaries](SECURITY-HARDENING-BINARIES.md)
 * [Building 32-bit binaries](BUILDING-32-BIT-BINARIES.md)
 * [Caching compilation results with ccache](CACHING-WITH-CCACHE.md)
 * [The special problem of libcurl SSL certificate authorities](LIBCURL-SSL-CERTIFICATE-AUTHORITIES.md)

## FAQ

### Who should be interested in portable Linux binaries?

Holy Build Box is made for developers that fit the following criteria:

 * You want to distribute binaries for your C/C++ applications to end users.
 * There are many people in your userbase with low to medium system administration skill, and you want your users to be able to easily use your applications, so you want to avoid asking them to compile from source.
 * You are wary of having to invest a disproportionate amount of time into building platform-specific packages. You want something that works for the majority of your users, without having to invest too much time.
 * You want your users to be easily able to use the latest versions of your software, so waiting for distributions to package your application is not an option.

If you identify with all of the above points, then Holy Build Box is for you.

Intepreted applications whose interpreters are written in C or C++ -- such as Ruby, Python or Node.js -- [are also supported](#how-should-i-deal-with-interpreted-applications-such-as-ones-written-in-ruby-python-or-nodejs), though indirectly.

Some non-developers (i.e. users) may object to the idea of distributing portable binaries. A common objecting is as follows:

> "Applications should be packaged through the distribution's native packaging system. Everything else is either broken, inconvenient or insecure."

 Packaging applications using distributions' native packaging systems requires a lot of investment from the developer, both in time and in system resources. Many of them are poorly documented. For example, documentation on making Debian packages is hard to find, scattered all over the place, is poorly-written, it often outdated and is hard to understand. On top of that, complying to distributions' packaging guidelines is a lot of work, even more than learning about the packaging system in the first place.

 If you are a purist, then you may not care how much time a developer has to invest. You may believe that your native packaging system is the only correct way. That is a valid stand point, but please consider that this stand point may not seem so reasonable to developers. Developers have to target a lot more users than just you. The task soon becomes unwieldly for the developer when they have to invest a huge amount of time into 3 different packaging systems and 12 different distribution versions. It is also not *fun* for the developer.

 We at Phusion spent 3 months trying to package [the Passenger application server](https://www.phusionpassenger.com/) for Debian and Ubuntu. We spent another 2 months doing the same for Red Hat distributions. Altogether, we spent 5 months during which we did not fix a single bug or introduce a single feature.

 We think that distributing portable binaries is a reasonable tradeoff. For all but the most hardcore system administrators who insist on native packages, portable binaries is good enough. Hardcore system administrators are of course still free to wait until their favorite distribution has packaged the application.

### Which operating systems does Holy Build Box support?

Holy Build Box only supports x86 and x86-64 linux.

OS X is not supported. Windows is not supported. Other Unices are not supported. Other CPU architectures, such as ARM, are not supported.

### Static linking introduces security problems. How do you deal with this?

We update the library versions in Holy Build Box regularly. However, application developers will need to recompile their applications on a regular basis too.

There is no way to automatically update application dependencies without recompilation, while also ensuring that their binaries are portable. The two things are mutually incompatible. There is no solution to this.

If you are an application developer, you should consider the tradeoff. Do your users like having a binary that Just Works(tm)? Do they like this enough that won't mind that an `apt-get upgrade` won't patch security issues in your application's dependencies, and that they need to wait for an update from you? Are you committed to checking your dependencies' security status and updating your binaries regularly?

### How does Holy Build Box compare to using Docker to package up an application?

Docker also solves the portability problem, but it gives the application a very different feel. The application is no longer just a binary. Users will have to install Docker and will have to learn how to use Docker commands in order to use your application. Your users may not particularly care about Docker: maybe they just want to use your application without having to learn about anything else.

Docker also requires a fairly recent kernel. Linux distributions released before ~2014 don't tend to have a recent enough kernel for Docker. So if you have any RHEL 5 users, then Docker is out of the question.

And finally, Docker images are much larger than binaries produced by Holy Build Box. Docker images contain entire Linux distributions and weight in the order of hundreds of MB in the average case, or tens of MB if you really did your best to optimize things. Binaries produced by Holy Build Box can be just a few MBs.

On the other hand, compiling an application using Holy Build Box requires advanced knowledge on the C/C++ compiler toolchain. You will regularly run into situations where you need to tweak the build system a little bit before the application properly compiles with static linking. If you are not skilled at using the C/C++ compiler toolchain, then using Docker is easier because it is much more "fire and forget".

### How does Holy Build Box compare to Go?

The Go compiler also produces portable Linux binaries. Holy Build Box is meant for existing C/C++ applications. In general, Go is a more productive language than C/C++. So if you are writing a new application, then using Go is an excellent choice. Otherwise, Holy Build Box is for you.

For example, the main reason why we made Holy Build Box was to be able to produce portable binaries for [the Phusion Passenger application server](https://www.phusionpassenger.com) and [Traveling Ruby](http://phusion.github.io/traveling-ruby/). Passenger is a mature codebase written in C++ so we can't just change it entirely to Go. Likewise, Ruby is written in C.

### Is Holy Build Box suitable for all applications?

No. Holy Build Box is mainly designed to compile headless applications such as CLI tools, servers and daemons. For example: [Phusion Passenger](https://www.phusionpassenger.com/), Nginx, [Traveling Ruby](http://phusion.github.io/traveling-ruby/).

Supporting graphical applications such as those based on GTK, Qt, SDL, OpenGL etc is outside the scope of this project. This doesn't mean that they cannot be made to work, but it's not something we are interested in so we have put no effort into that.

### How should I deal with interpreted applications, such as ones written in Ruby, Python or Node.js?

We recommend that you compile the interpreter with Holy Build Box, and that you package both the interpreter and the application in a single package. If your application makes use of any interpreter extensions, then you should compile those with Holy Build Box too.

We have specific recommendations for some languages:

#### Ruby

Take a look at [Traveling Ruby](http://phusion.github.io/traveling-ruby/). The approach taken by Traveling Ruby is exactly what we recommended. Traveling Ruby uses Holy Build Box to build its Linux binaries.

#### Node.js

If your application has no dependencies on NPM modules with native extensions, then there is no need to use Holy Build Box. You can just download a Node.js binary from www.nodejs.org and package it together with your application and your `npm_modules` directory. The binaries shipped by www.nodejs.org are already portable and work across Linux distributions.

If your application has a dependency on an NPM module with native extension, either directly or indirectly, then you should compile Node.js and your NPM modules with Holy Build Box. When done, package the compiled Node.js, `npm_modules` directory and your application.

### Why the name "Holy Build Box"?

Around 2004, I (Hongli Lai) participated in a now-defunct open source project called Autopackage. Back then we were in the middle of the Linux-on-the-desktop hype. One of the things people complained most about was software installation. Every distribution had its own way of installing things, and binaries compiled on one distribution doesn't work on another. This was considered problematic because, as a developer, it is so painful to distribute software to end users. See also the FAQ entry [Who should be interested in portable Linux binaries?](#who-should-be-interested-in-portable-linux-binaries).

This problem actually still exists -- it was never resolved.

Anyway, the Autopackage project sought to solve this problem by introducing a cross-distribution package manager. We soon realized that solving the packaging aspect only partially solved the problem. Regarldess of the packaging, the binaries that were packaged still need to work across Linux distributions.

We saw that Mozilla was able to produce Firefox binaries that work on all Linux distributions. We found out that they did that by constructing a server with a special, tightly-controlled environment that contained an old glibc.

Back in 2004, virtualization was almost non-existent. All Autopackage team members were either high school or college team members. We were only barely able to afford our computers. Constructing a special server just for the purpose of compiling portable binaries was expensive: it meant buying a new computer. The entire idea of constructing such a server was so over our heads that we named Mozilla's build server a "holy build box".

We wanted to give developers a way to produce portable binaries without asking them to construct a holy build box. Virtualization was not a realistic option back then: we could not imagine that many people would want to buy a new computer only for the purpose of producing portable binaries, especially seeing that Windows developers didn't have to do that either. So wrote a set of scripts which automates the linker script approach. However, this approach was found to be too buggy.

Autopackage eventually went defunct because of resistance from distributors. I guess that people weren't *truly* interested in Linux succeeding on the desktop, despite how many people complained about it.

Anyway, fast forward to 2015. Virtualization and containerization is now cheap is ubiquitous. Thus the holy build box approach is now viable.
