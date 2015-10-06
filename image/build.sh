#!/bin/bash
set -e

M4_VERSION=1.4.17
AUTOCONF_VERSION=2.69
AUTOMAKE_VERSION=1.15
LIBTOOL_VERSION=2.4.6
PKG_CONFIG_VERSION=0.28
CCACHE_VERSION=3.2.3
CMAKE_VERSION=3.3.2
CMAKE_MAJOR_VERSION=3.3
PYTHON_VERSION=2.7.10
GCC_LIBSTDCXX_VERSION=4.8.2
ZLIB_VERSION=1.2.8
OPENSSL_VERSION=1.0.2d
CURL_VERSION=7.44.0
SQLITE_VERSION=3081101
SQLITE_YEAR=2015

source /hbb_build/functions.sh
source /hbb_build/activate_func.sh

SKIP_TOOLS=${SKIP_TOOLS:-false}
SKIP_LIBS=${SKIP_LIBS:-false}
SKIP_FINALIZE=${SKIP_FINALIZE:-false}

SKIP_M4=${SKIP_M4:-$SKIP_TOOLS}
SKIP_AUTOCONF=${SKIP_AUTOCONF:-$SKIP_TOOLS}
SKIP_AUTOMAKE=${SKIP_AUTOMAKE:-$SKIP_TOOLS}
SKIP_LIBTOOL=${SKIP_LIBTOOL:-$SKIP_TOOLS}
SKIP_PKG_CONFIG=${SKIP_PKG_CONFIG:-$SKIP_TOOLS}
SKIP_CCACHE=${SKIP_CCACHE:-$SKIP_TOOLS}
SKIP_CMAKE=${SKIP_CMAKE:-$SKIP_TOOLS}
SKIP_PYTHON=${SKIP_PYTHON:-$SKIP_TOOLS}

SKIP_LIBSTDCXX=${SKIP_LIBSTDCXX:-$SKIP_LIBS}
SKIP_ZLIB=${SKIP_ZLIB:-$SKIP_LIBS}
SKIP_OPENSSL=${SKIP_OPENSSL:-$SKIP_LIBS}
SKIP_CURL=${SKIP_CURL:-$SKIP_LIBS}
SKIP_SQLITE=${SKIP_SQLITE:-$SKIP_LIBS}

MAKE_CONCURRENCY=2
VARIANTS='exe exe_gc_hardened shlib'
export PATH=/hbb/bin:$PATH

#########################

header "Initializing"
run mkdir -p /hbb /hbb/bin
run cp /hbb_build/libcheck /hbb/bin/
run cp /hbb_build/hardening-check /hbb/bin/
run cp /hbb_build/activate_func.sh /hbb/activate_func.sh

for VARIANT in $VARIANTS; do
	run mkdir -p /hbb_$VARIANT
	run cp /hbb_build/activate-exec /hbb_$VARIANT/
	run cp /hbb_build/variants/$VARIANT.sh /hbb_$VARIANT/activate
done

header "Updating system"
run yum update -y
run yum install -y curl

header "Installing compiler toolchain"
cd /etc/yum.repos.d
# GCC 4.8 for CentOS 5: http://braaten-family.org/ed/blog/2014-05-28-devtools-for-centos/
run curl -LOS http://people.centos.org/tru/devtools-2/devtools-2.repo
cd /
run yum install -y devtoolset-2-gcc devtoolset-2-gcc-c++ devtoolset-2-binutils \
	make file diffutils patch perl bzip2 which openssl-devel
source /opt/rh/devtoolset-2/enable


### m4

if ! eval_bool "$SKIP_M4"; then
	header "Installing m4 $M4_VERSION"
	download_and_extract m4-$M4_VERSION.tar.gz \
		m4-$M4_VERSION \
		http://ftp.gnu.org/gnu/m4/m4-$M4_VERSION.tar.gz

	run ./configure --prefix=/hbb --disable-shared --enable-static
	run make -j$MAKE_CONCURRENCY
	run make install-strip

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf m4-$M4_VERSION
fi


### autoconf

if ! eval_bool "$SKIP_AUTOCONF"; then
	header "Installing autoconf $AUTOCONF_VERSION"
	download_and_extract autoconf-$AUTOCONF_VERSION.tar.gz \
		autoconf-$AUTOCONF_VERSION \
		http://ftp.gnu.org/gnu/autoconf/autoconf-$AUTOCONF_VERSION.tar.gz

	run ./configure --prefix=/hbb --disable-shared --enable-static
	run make -j$MAKE_CONCURRENCY
	run make install-strip

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf autoconf-$AUTOCONF_VERSION
fi


### automake

if ! eval_bool "$SKIP_AUTOMAKE"; then
	header "Installing automake $AUTOMAKE_VERSION"
	download_and_extract automake-$AUTOMAKE_VERSION.tar.gz \
		automake-$AUTOMAKE_VERSION \
		http://ftp.gnu.org/gnu/automake/automake-$AUTOMAKE_VERSION.tar.gz

	run ./configure --prefix=/hbb --disable-shared --enable-static
	run make -j$MAKE_CONCURRENCY
	run make install-strip

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf automake-$AUTOMAKE_VERSION
fi


### libtool

if ! eval_bool "$SKIP_LIBTOOL"; then
	header "Installing libtool $LIBTOOL_VERSION"
	download_and_extract libtool-$LIBTOOL_VERSION.tar.gz \
		libtool-$LIBTOOL_VERSION \
		http://ftp.gnu.org/gnu/libtool/libtool-$LIBTOOL_VERSION.tar.gz

	run ./configure --prefix=/hbb --disable-shared --enable-static
	run make -j$MAKE_CONCURRENCY
	run make install-strip

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf libtool-$LIBTOOL_VERSION
fi


### pkg-config

if ! eval_bool "$SKIP_PKG_CONFIG"; then
	header "Installing pkg-config $PKG_CONFIG_VERSION"
	download_and_extract pkg-config-$PKG_CONFIG_VERSION.tar.gz \
		pkg-config-$PKG_CONFIG_VERSION \
		http://pkgconfig.freedesktop.org/releases/pkg-config-$PKG_CONFIG_VERSION.tar.gz

	run ./configure --prefix=/hbb --with-internal-glib
	run rm -f /hbb/bin/*pkg-config
	run make -j$MAKE_CONCURRENCY install-strip

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf pkg-config-$PKG_CONFIG_VERSION
fi


### ccache

if ! eval_bool "$SKIP_CCACHE"; then
	header "Installing ccache $CCACHE_VERSION"
	download_and_extract ccache-$CCACHE_VERSION.tar.gz \
		ccache-$CCACHE_VERSION \
		http://samba.org/ftp/ccache/ccache-$CCACHE_VERSION.tar.gz

	run ./configure --prefix=/hbb
	run make -j$MAKE_CONCURRENCY install
	run strip --strip-all /hbb/bin/ccache

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf ccache-$CCACHE_VERSION
fi


### CMake

if ! eval_bool "$SKIP_CMAKE"; then
	header "Installing CMake $CMAKE_VERSION"
	download_and_extract cmake-$CMAKE_VERSION.tar.gz \
		cmake-$CMAKE_VERSION \
		http://www.cmake.org/files/v$CMAKE_MAJOR_VERSION/cmake-$CMAKE_VERSION.tar.gz

	run ./configure --prefix=/hbb --no-qt-gui --parallel=$MAKE_CONCURRENCY
	run make -j$MAKE_CONCURRENCY
	run make install
	run strip --strip-all /hbb/bin/cmake

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf cmake-$CMAKE_VERSION
fi


### Python

if ! eval_bool "$SKIP_PYTHON"; then
	header "Installing Python $PYTHON_VERSION"
	run yum install -y openssl-devel
	download_and_extract Python-$PYTHON_VERSION.tgz \
		Python-$PYTHON_VERSION \
		https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz

	run ./configure --prefix=/hbb
	run make -j$MAKE_CONCURRENCY install
	run strip --strip-all /hbb/bin/python
	run strip --strip-debug /hbb/lib/python*/lib-dynload/*.so

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf Python-$PYTHON_VERSION

	# These were installed as part of openssl-devel
	run yum remove -y openssl-devel e2fsprogs-devel keyutils-libs-devel \
		krb5-devel libselinux-devel libsepol-devel zlib-devel

	# Install setuptools and pip
	curl -OL --fail https://bootstrap.pypa.io/ez_setup.py
	python ez_setup.py
	rm -f ez_setup.py
	easy_install pip
fi


## libstdc++

function install_libstdcxx()
{
	local VARIANT="$1"
	local PREFIX="/hbb_$VARIANT"

	header "Installing libstdc++ static libraries: $VARIANT"
	download_and_extract gcc-$GCC_LIBSTDCXX_VERSION.tar.gz \
		gcc-$GCC_LIBSTDCXX_VERSION \
		http://mirror2.babylon.network/gcc/releases/gcc-$GCC_LIBSTDCXX_VERSION/gcc-$GCC_LIBSTDCXX_VERSION.tar.bz2

	(
		source "$PREFIX/activate"
		run rm -rf ../gcc-build
		run mkdir ../gcc-build
		echo "+ Entering /gcc-build"
		cd ../gcc-build

		export CFLAGS="$STATICLIB_CFLAGS"
		export CXXFLAGS="$STATICLIB_CXXFLAGS"
		../gcc-$GCC_LIBSTDCXX_VERSION/libstdc++-v3/configure \
			--prefix=$PREFIX --disable-multilib \
			--disable-libstdcxx-visibility --disable-shared
		run make -j$MAKE_CONCURRENCY
		run mkdir -p $PREFIX/lib
		run cp src/.libs/libstdc++.a $PREFIX/lib/
		run cp libsupc++/.libs/libsupc++.a $PREFIX/lib/
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf gcc-$GCC_LIBSTDCXX_VERSION
	run rm -rf gcc-build
}

if ! eval_bool "$SKIP_LIBSTDCXX"; then
	for VARIANT in $VARIANTS; do
		install_libstdcxx $VARIANT
	done
fi


### zlib

function install_zlib()
{
	local VARIANT="$1"
	local PREFIX="/hbb_$VARIANT"

	header "Installing zlib $ZLIB_VERSION static libraries: $VARIANT"
	download_and_extract zlib-$ZLIB_VERSION.tar.gz \
		zlib-$ZLIB_VERSION \
		http://zlib.net/zlib-$ZLIB_VERSION.tar.gz

	(
		source "$PREFIX/activate"
		export CFLAGS="$STATICLIB_CFLAGS"
		run ./configure --prefix=$PREFIX --static
		run make -j$MAKE_CONCURRENCY
		run make install
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf zlib-$ZLIB_VERSION
}

if ! eval_bool "$SKIP_ZLIB"; then
	for VARIANT in $VARIANTS; do
		install_zlib $VARIANT
	done
fi


### OpenSSL

function install_openssl()
{
	local VARIANT="$1"
	local PREFIX="/hbb_$VARIANT"

	header "Installing OpenSSL $OPENSSL_VERSION static libraries: $PREFIX"
	download_and_extract openssl-$OPENSSL_VERSION.tar.gz \
		openssl-$OPENSSL_VERSION \
		http://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz

	(
		source "$PREFIX/activate"

		# OpenSSL already passes optimization flags regardless of CFLAGS
		export CFLAGS=`echo "$STATICLIB_CFLAGS" | sed 's/-O2//'`
		run ./config --prefix=$PREFIX --openssldir=$PREFIX/openssl \
			threads zlib no-shared no-sse2 $CFLAGS $LDFLAGS

		if ! $O3_ALLOWED; then
			echo "+ Modifying Makefiles"
			find . -name Makefile | xargs sed -i -e 's|-O3|-O2|g'
		fi

		run make
		run make install_sw
		run strip --strip-all "$PREFIX/bin/openssl"
		if [[ "$VARIANT" = exe_gc_hardened ]]; then
			run hardening-check -b "$PREFIX/bin/openssl"
		fi
		run sed -i 's/^Libs:.*/Libs: -L${libdir} -lssl -lcrypto -ldl/' $PREFIX/lib/pkgconfig/openssl.pc
		run sed -i 's/^Libs.private:.*/Libs.private: -L${libdir} -lssl -lcrypto -ldl -lz/' $PREFIX/lib/pkgconfig/openssl.pc
		run sed -i 's/^Libs:.*/Libs: -L${libdir} -lssl -lcrypto -ldl/' $PREFIX/lib/pkgconfig/libssl.pc
		run sed -i 's/^Libs.private:.*/Libs.private: -L${libdir} -lssl -lcrypto -ldl -lz/' $PREFIX/lib/pkgconfig/libssl.pc
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf openssl-$OPENSSL_VERSION
}

if ! eval_bool "$SKIP_OPENSSL"; then
	for VARIANT in $VARIANTS; do
		install_openssl $VARIANT
	done
	run mv /hbb_exe_gc_hardened/bin/openssl /hbb/bin/
	for VARIANT in $VARIANTS; do
		run rm -f /hbb_$VARIANT/bin/openssl
	done
fi


### libcurl

function install_curl()
{
	local VARIANT="$1"
	local PREFIX="/hbb_$VARIANT"

	header "Installing Curl $CURL_VERSION static libraries: $PREFIX"
	download_and_extract curl-$CURL_VERSION.tar.gz \
		curl-$CURL_VERSION \
		http://curl.haxx.se/download/curl-$CURL_VERSION.tar.bz2

	(
		source "$PREFIX/activate"
		export CFLAGS="$STATICLIB_CFLAGS"
		./configure --prefix="$PREFIX" --disable-shared --disable-debug --enable-optimize --disable-werror \
			--disable-curldebug --enable-symbol-hiding --disable-ares --disable-manual --disable-ldap --disable-ldaps \
			--disable-rtsp --disable-dict --disable-ftp --disable-ftps --disable-gopher --disable-imap \
			--disable-imaps --disable-pop3 --disable-pop3s --without-librtmp --disable-smtp --disable-smtps \
			--disable-telnet --disable-tftp --disable-smb --disable-versioned-symbols \
			--without-libmetalink --without-libidn --without-libssh2 --without-libmetalink --without-nghttp2 \
			--with-ssl
		run make -j$MAKE_CONCURRENCY
		run make install
		if [[ "$VARIANT" = exe_gc_hardened ]]; then
			run hardening-check -b "$PREFIX/bin/curl"
		fi
		run rm -f "$PREFIX/bin/curl"
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf curl-$CURL_VERSION
}

if ! eval_bool "$SKIP_CURL"; then
	for VARIANT in $VARIANTS; do
		install_curl $VARIANT
	done
fi


### SQLite

function install_sqlite()
{
	local VARIANT="$1"
	local PREFIX="/hbb_$VARIANT"

	header "Installing SQLite $SQLITE_VERSION static libraries: $PREFIX"
	download_and_extract sqlite-autoconf-$SQLITE_VERSION.tar.gz \
		sqlite-autoconf-$SQLITE_VERSION \
		http://www.sqlite.org/$SQLITE_YEAR/sqlite-autoconf-$SQLITE_VERSION.tar.gz

	(
		source "$PREFIX/activate"
		export CFLAGS="$STATICLIB_CFLAGS"
		export CXXFLAGS="$STATICLIB_CXXFLAGS"
		run ./configure --prefix="$PREFIX" --enable-static \
			--disable-shared --disable-dynamic-extensions
		run make -j$MAKE_CONCURRENCY
		run make install
		if [[ "$VARIANT" = exe_gc_hardened ]]; then
			run hardening-check -b "$PREFIX/bin/sqlite3"
		fi
		run strip --strip-all "$PREFIX/bin/sqlite3"
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf sqlite-autoconf-$SQLITE_VERSION
}

if ! eval_bool "$SKIP_SQLITE"; then
	for VARIANT in $VARIANTS; do
		install_sqlite $VARIANT
	done
	run mv /hbb_exe_gc_hardened/bin/sqlite3 /hbb/bin/
	for VARIANT in $VARIANTS; do
		run rm -f /hbb_$VARIANT/bin/sqlite3
	done
fi


### Finalizing

if ! eval_bool "$SKIP_FINALIZE"; then
	header "Finalizing"
	run yum clean -y all
	run rm -rf /hbb_build /tmp/*
	for VARIANT in $VARIANTS; do
		run rm -rf /hbb_$VARIANT/share/man
	done
fi
