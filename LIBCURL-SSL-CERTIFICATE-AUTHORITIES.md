# Caveat: libcurl SSL certificate authorities

If you use libcurl to perform HTTPS requests, then libcurl requires a list of certificate authorities. If you do not provide libcurl with such a list (through `CURLOPT_CAINFO`) then libcurl will attempt to use the operating system's default certificate authority list. However, every Linux distribution stores this list in a different location. Distributions customize their libcurl packages to tell libcurl where their default list is.

If you use Holy Build Box to statically link to libcurl, then libcurl cannot use the operating system's default certificate authority list, because it does not know where it is.

Our recommended solution is to:

 1. Ship a certificate authority list with your application. For example, you can use the [CentOS 8 certificate authority list](https://github.com/FooBarWidget/traveling-ruby/blob/main/shared/ca-bundle.crt).
 2. Start your application a wrapper script, which sets the `SSL_CERT_FILE` environment variable to the shipped certificate authority list, prior to starting the application.

Suppose that your binary is called `foo.bin`, your wrapper script called `foo`, and your certificate authority list file `ca-bundle.crt`. Assuming they are all located in the same directory, here is how the wrapper script could look like:

~~~bash
#!/bin/bash
set -e

dir=`dirname "$0"`
dir=`cd "$dir" && pwd`

export SSL_CERT_FILE="$dir/ca-bundle.crt"
exec "$dir/foo.bin" "$@"
~~~
