# Securing the build environment

When you run a command inside the Holy Build Box Docker container, it runs as the root user. This has security implications. Docker and the Linux kernel do their best to confine the command within the limits of the container, but this mechanism is not perfect: security bugs do exist, occasionally allowing code inside a container to escape the container into the host system.

We recommend running as many commands inside the Docker container *without* root privileges as possible. This adds an extra layer of defense against security vulnerabilities. Holy Build Box provides some mechanisms to allow you to easily run commands without root privileges.

## Why secure the build environment?

You may wonder whether such security precautions are necessary. After all, if you are only using Holy Build Box to build binaries, then why bother at all? It is because security is hard, and history has taught us that security exploits can follow unpredictable paths. You may think that it does not matter, until someone one day finds a clever way to exploit this into a much bigger issue. And if following security precautions is almost free, why not do it just in case? By investing just a little bit of time you can potentially save yourself from a big disaster later.

## The `setuser` command: running a command as a specific user

The Holy Build Box image contains the `/hbb/bin/setuser` command. This command allows you to run a command as a specific user. Its invocation is as follows:

    /hbb/bin/setuser <USERNAME> <COMMAND...>

This example shows how you can run the compile.sh script from [tutorial 2](TUTORIAL-2-COMPILATION-SCRIPT.md) under the `builder` user account using the setuser command:

    docker run -t -i --rm \
      -v `pwd`:/io \
      ghcr.io/phusion/holy-build-box/hbb-64 \
      /hbb/bin/setuser builder \
      bash /io/compile.sh

## The `builder` user

The Holy Build Box image provides a user account called `builder`. Its UID and GID are 9327. Unless you have specific needs, we recommend you to use this user account.

## Creating your own user account

If you need your own user account with your own UID and username, then we recommend that you create this user inside your compilation script. Use the `groupadd` and `adduser` command to do this.

For example, we can modify the script from [tutorial 2](TUTORIAL-2-COMPILATION-SCRIPT.md) as follows in order to run compilation commands under the `app` user (with UID 1234):

~~~bash
#!/bin/bash
set -e

# Activate Holy Build Box environment.
source /hbb_exe/activate

set -x

# Create user account
groupadd -g 1234 app
adduser --uid 1234 --gid 1234 app

# Extract and enter source
cd /tmp
setuser app tar xzf /io/hello-2.10.tar.gz
cd hello-2.10

# Compile
setuser app ./configure
setuser app make
make install

# Copy result to host
cp /usr/local/bin/hello /io/
~~~

Note that the above example calls `setuser` in order to run specific commands (but not all of them) under the `app` account. Because `setuser`, `groupadd` and `adduser` require root privileges, the compilation script itself must be run with root privileges:

    docker run -t -i --rm \
      -v `pwd`:/io \
      ghcr.io/phusion/holy-build-box/hbb-64 \
      bash /io/compile.sh
