## Version 3.0.1 (release date 2020-01-25)

 * Fixed installing pip. Pip was not properly installed in 3.0.0.

## Version 3.0.0 (release date 2020-01-17)

 * Moved to CentOS 7. This makes binaries compatible with Linux distributions that have glibc >= 2.17. This means compatibility with Linux distributions released around 2013-2015, such as:

    - Red Hat Enterprise Linux 7
    - Ubuntu 14.06
    - Debian 8

 * Tooling versions changed as part of the CentOS 7 move:

    - GCC 9.3.1 (good C++14 support)
    - m4 1.4.16
    - autoconf 2.69
    - automake 1.13.4
    - libtool 2.4.2
    - pkg-config 0.27.1
    - Python 2.7.5

 * Upgraded OpenSSL to 1.1.1i.

 * Dropped support for building x86 binaries.

## Version 2.2.0 (release date 2020-01-16)

 * Fixed C++ std::thread support when statically linking libstdc++
 * Made the image smaller by removing redundant versions of OpenSSL and curl.
 * Updated autoconf to 2.70.
 * Updated automake to 1.16.3.
 * Updated ccache to 3.7.12.
 * Updated CMake to 3.19.3.
 * Updated OpenSSL to 1.0.2u.
 * Updated curl to 7.74.0.
 * Updated Git to 2.30.0.
 * Updated SQLite to 2020-3340000.

## Version 2.1.0 (release date 2020-01-15)

 * Fixed YUM repository URLs so that YUM still works despite CentOS 6 having reached end-of-life.
 * Devtoolset updated to 8 (on x86\_64 only).
 * CMake updated to 3.16.4.
 * Git 2.25.1 added.

## Version 2.0.1 (release date 2019-01-03)

 * Changed libcheck script to use readelf internally instead of ldd, to remove confusing output.

## Version 2.0.0 (release date 2018-12-20)

 * Moved to CentOS 6.
 * Updated system curl means we can grab tarballs from https urls.
 * Updated devtoolset to version 7.
 * automake updated to 1.16.1
 * ccache updated to 3.5
 * CMake updated to 3.13.2
 * libcurl updated to 7.63.0
 * gcc_libstdcxx updated to 7.3.0
 * m4 updated to 1.4.18
 * Openssl updated to 1.0.2q
 * pkg_config updated to 0.29.2
 * Python updated to 2.7.15
 * SQLite updated to 2018-3260000

## Version 1.2.3 (release date 2018-09-21)

 * OpenSSL has been upgraded to 1.0.2p.
 * libcurl has been upgraded to 7.61.1.
 * ccache has been upraded to 3.4.3.
 * SQLite has been upgraded to 2018-3250000.

## Version 1.2.2 (release date 2018-06-11)

 * OpenSSL has been upgraded to 1.0.2o.
 * libcurl has been upgraded to 7.60.0.
 * SQLite has been upgraded to 2018-3240000.

## Version 1.2.1 (release date 2017-05-04)

 * OpenSSL has been upgraded to 1.0.2k.
 * libcurl has been upgraded to 7.54.0.
 * libzlib has been upgraded to 1.2.11.

## Version 1.2.0 (release date 2016-11-16)

 * Python has been upgraded to 2.7.12.
 * OpenSSL has been upgraded to 1.0.2j.
 * ccache has been upgraded to 3.3.3.
 * CMake has been upgraded to 3.6.3.
 * libcurl has been upgraded to 7.51.0.
 * SQLite has been upgraded to 2016-3150100.
 * Removes the unnecessary setuptools zip file in the root directory.
 * Adds a default mechanism for running builds without root privileges. See the "Securing the build environment" guide for more information.
 * [EPEL](https://fedoraproject.org/wiki/EPEL) is now enabled inside the Holy Build Box image.

## Version 1.1.0 (release date 2016-07-13)

 * Fixes problems with building the Docker image due to so many web servers these days switching to HTTPS with strict cryptographic settings that aren't supported by CentOS 5's default OpenSSL version.
 * Python is now built with OpenSSL and HTTPS support.
 * Setuptools and pip are now included.
 * OpenSSL has been upgraded to 1.0.2h.
 * ccache has been upgraded to 3.2.6.
 * CMake has been upgraded to 3.6.0.
 * libcurl has been upgraded to 7.49.1.
 * SQLite has been upgraded to 2016-3130000.

## Version 1.0.0 (release date 2015-10-05)

 * Initial release.
