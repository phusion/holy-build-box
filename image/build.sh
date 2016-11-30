#!/bin/bash
set -e

BOOST_VERSION=1.62.0
PKG_CONFIG_VERSION=0.29.1
CCACHE_VERSION=3.3.3
CMAKE_VERSION=3.6.3
CMAKE_MAJOR_VERSION=3.6
ZLIB_VERSION=1.2.8
BZIP2_VERSION=1.0.6
OPENSSL_VERSION=1.0.2j
CURL_VERSION=7.51.0
SQLITE_VERSION=3150100
SQLITE_YEAR=2016

source /hbb_build/functions.sh
source /hbb_build/activate_func.sh

SKIP_TOOLS=${SKIP_TOOLS:-false}
SKIP_LIBS=${SKIP_LIBS:-false}
SKIP_FINALIZE=${SKIP_FINALIZE:-false}

SKIP_PKG_CONFIG=${SKIP_PKG_CONFIG:-$SKIP_TOOLS}
SKIP_CCACHE=${SKIP_CCACHE:-$SKIP_TOOLS}
SKIP_CMAKE=${SKIP_CMAKE:-$SKIP_TOOLS}

SKIP_ZLIB=${SKIP_ZLIB:-$SKIP_LIBS}
SKIP_BOOST=${SKIP_BOOST:-$SKIP_LIBS}
SKIP_BZIP2=${SKIP_BZIP2:-$SKIP_LIBS}
SKIP_OPENSSL=${SKIP_OPENSSL:-$SKIP_LIBS}
SKIP_CURL=${SKIP_CURL:-$SKIP_LIBS}
SKIP_SQLITE=${SKIP_SQLITE:-$SKIP_LIBS}

MAKE_CONCURRENCY=${MAKE_CONCURRENCY:-2}
VARIANTS='exe exe_gc_hardened shlib'
export PATH=/hbb/bin:$PATH

#########################

header "Initializing"
run mkdir -p /hbb /hbb/bin
run cp /hbb_build/libcheck /hbb/bin/
run cp /hbb_build/hardening-check /hbb/bin/
run cp /hbb_build/setuser /hbb/bin/
run cp /hbb_build/activate_func.sh /hbb/activate_func.sh
run cp /hbb_build/hbb-activate /hbb/activate
run cp /hbb_build/activate-exec /hbb/activate-exec

run groupadd -g 9327 builder
run adduser --uid 9327 --gid 9327 builder

for VARIANT in $VARIANTS; do
	run mkdir -p /hbb_$VARIANT
	run cp /hbb_build/activate-exec /hbb_$VARIANT/
	run cp /hbb_build/variants/$VARIANT.sh /hbb_$VARIANT/activate
done

header "Updating system"
run yum update -y
run yum install -y curl epel-release centos-release-scl-rh

# Enable autotools-latest EPEL
run yum install -y https://www.softwarecollections.org/en/scls/praiskup/autotools/epel-6-x86_64/download/praiskup-autotools-epel-6-x86_64.noarch.rpm

header "Installing compiler toolchain"
cd /
run yum install -y devtoolset-4-gcc devtoolset-4-gcc-c++ \
		devtoolset-4-binutils  make file diffutils \
		patch perl bzip2 which gzip autotools-latest python27

activate_scl
export PATH=/hbb/bin:$PATH

### bzip2
function install_bzip2()
{
	local VARIANT="$1"
	local PREFIX="/hbb_$VARIANT"

	header "Installing bzip2 $BZIP2_VERSION static libraries: $VARIANT"
	download_and_extract bzip2-$BZIP2_VERSION.tar.gz \
		bzip2-$BZIP2_VERSION \
		http://bzip.org/${BZIP2_VERSION}/bzip2-$BZIP2_VERSION.tar.gz

	(
		source "$PREFIX/activate"
		export CFLAGS="$STATICLIB_CFLAGS"
		run make -j$MAKE_CONCURRENCY
		run make install PREFIX=$PREFIX
		run rm -f $PREFIX/bin/bz* $PREFIX/bin/bunzip2
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf bzip2-$BZIP2_VERSION
}

if ! eval_bool "$SKIP_BZIP2"; then
	for VARIANT in $VARIANTS; do
		install_bzip2 $VARIANT
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


### BOOST
function install_boost()
{
	local VARIANT="$1"
	local PREFIX="/hbb_$VARIANT"

	header "Installing boost $BOOST_VERSION static libraries: $VARIANT"

	local underscore_version=$(echo $BOOST_VERSION | sed 's/\./_/g')
	local url=http://downloads.sourceforge.net/project/boost/boost/${BOOST_VERSION}/boost_${underscore_version}.tar.bz2
	download_and_extract boost_$BOOST_VERSION.tar.bz2 \
		boost_$underscore_version $url

	(
		source "$PREFIX/activate"
		export CFLAGS="$STATICLIB_CFLAGS"
		run ./bootstrap.sh
		run ./b2 -j$MAKE_CONCURRENCY --prefix=$PREFIX   \
			--without-mpi --without-python              \
			threading=multi variant=release link=static \
			install
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf boost_$underscore_version
}

if ! eval_bool "$SKIP_BOOST"; then
	for VARIANT in $VARIANTS; do
		install_boost $VARIANT
	done
fi

### pkg-config

if ! eval_bool "$SKIP_PKG_CONFIG"; then
	header "Installing pkg-config $PKG_CONFIG_VERSION"
	download_and_extract pkg-config-$PKG_CONFIG_VERSION.tar.gz \
		pkg-config-$PKG_CONFIG_VERSION \
		https://pkgconfig.freedesktop.org/releases/pkg-config-$PKG_CONFIG_VERSION.tar.gz

	(
		activate_holy_build_box_deps_installation_environment
		run ./configure --prefix=/hbb --with-internal-glib
		run rm -f /hbb/bin/*pkg-config
		run make -j$MAKE_CONCURRENCY install-strip
	)
	if [[ "$?" != 0 ]]; then false; fi

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

	(
		activate_holy_build_box_deps_installation_environment
		run ./configure --prefix=/hbb
		run make -j$MAKE_CONCURRENCY install
		run strip --strip-all /hbb/bin/ccache
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf ccache-$CCACHE_VERSION
fi


### CMake

if ! eval_bool "$SKIP_CMAKE"; then
	header "Installing CMake $CMAKE_VERSION"
	download_and_extract cmake-$CMAKE_VERSION.tar.gz \
		cmake-$CMAKE_VERSION \
		https://cmake.org/files/v$CMAKE_MAJOR_VERSION/cmake-$CMAKE_VERSION.tar.gz

	(
		activate_holy_build_box_deps_installation_environment
		run ./configure --prefix=/hbb --no-qt-gui --parallel=$MAKE_CONCURRENCY
		run make -j$MAKE_CONCURRENCY
		run make install
		run strip --strip-all /hbb/bin/cmake
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf cmake-$CMAKE_VERSION
fi

### Finalizing

if ! eval_bool "$SKIP_FINALIZE"; then
	header "Finalizing"
	run yum clean -y all
	run rm -rf /hbb/share/doc /hbb/share/man
	run rm -rf /hbb_build /tmp/*
	for VARIANT in $VARIANTS; do
		run rm -rf /hbb_$VARIANT/share/doc /hbb_$VARIANT/share/man
	done
fi
