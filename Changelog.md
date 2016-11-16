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
