#!/bin/bash
set -e

PKG_CONFIG_VERSION=0.28
CCACHE_VERSION=3.2.3
CMAKE_VERSION=3.3.2
CMAKE_MAJOR_VERSION=3.3
ZLIB_VERSION=1.2.8
OPENSSL_VERSION=1.0.2d
CURL_VERSION=7.44.0

source /hbb_build/functions.sh
source /hbb_build/activate_func.sh

MAKE_CONCURRENCY=2
export PATH=/hbb/bin:$PATH

#########################

header "Initializing"
run mkdir -p /hbb /hbb/bin
run mkdir -p /hbb_nopic /hbb_pic /hbb_deadstrip_hardened_pie
run cp /hbb_build/libcheck /hbb/bin/
run cp /hbb_build/activate_func.sh /hbb/activate_func.sh

run cp /hbb_build/activate-exec /hbb_nopic/
run cp /hbb_build/activate-exec /hbb_pic/
run cp /hbb_build/activate-exec /hbb_deadstrip_hardened_pie/

run cp /hbb_build/activate_nopic.sh /hbb_nopic/activate
run cp /hbb_build/activate_pic.sh /hbb_pic/activate
run cp /hbb_build/activate_deadstrip_hardened_pie.sh /hbb_deadstrip_hardened_pie/activate

header "Updating system"
run yum update -y

header "Installing compiler toolchain"
run yum install -y gcc gcc-c++ make curl file diffutils patch \
	perl bzip2


### pkg-config

if [[ "$SKIP_PKG_CONFIG" != 1 ]]; then
	header "Installing pkg-config $PKG_CONFIG_VERSION"
	download_and_extract pkg-config-$PKG_CONFIG_VERSION.tar.gz \
		pkg-config-$PKG_CONFIG_VERSION \
		http://pkgconfig.freedesktop.org/releases/pkg-config-$PKG_CONFIG_VERSION.tar.gz

	run ./configure --prefix=/hbb --with-internal-glib
	run make -j$MAKE_CONCURRENCY install-strip

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf pkg-config-$PKG_CONFIG_VERSION
fi


### ccache

if [[ "$SKIP_CCACHE" != 1 ]]; then
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

if [[ "$SKIP_CMAKE" != 1 ]]; then
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


### zlib

function install_zlib()
{
	local PREFIX="$1"

	header "Installing zlib $ZLIB_VERSION static libraries: $PREFIX"
	download_and_extract zlib-$ZLIB_VERSION.tar.gz \
		zlib-$ZLIB_VERSION \
		http://zlib.net/zlib-$ZLIB_VERSION.tar.gz

	(
		source "$PREFIX/activate"
		run ./configure --prefix=$PREFIX --static
		run make -j$MAKE_CONCURRENCY install
		run strip --strip-debug "$PREFIX/lib/libz.a"
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf zlib-$ZLIB_VERSION
}

if [[ "$SKIP_ZLIB" != 1 ]]; then
	install_zlib /hbb_nopic
	install_zlib /hbb_pic
	install_zlib /hbb_deadstrip_hardened_pie
fi


### OpenSSL

function install_openssl()
{
	local PREFIX="$1"

	header "Installing OpenSSL $OPENSSL_VERSION static libraries: $PREFIX"
	download_and_extract openssl-$OPENSSL_VERSION.tar.gz \
		openssl-$OPENSSL_VERSION \
		http://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz

	(
		source "$PREFIX/activate"
		if $O3_ALLOWED; then
			run ./config --prefix=$PREFIX --openssldir=$PREFIX/openssl \
				threads zlib no-shared no-sse2 -fvisibility=hidden $MINIMAL_CFLAGS
		else
			run ./config --prefix=$PREFIX --openssldir=$PREFIX/openssl \
				threads zlib no-shared no-sse2 -fvisibility=hidden -O2 $MINIMAL_CFLAGS
			echo "+ Modifying Makefiles"
			find . -name Makefile | xargs sed -i -e 's|-O3||g'
		fi
		run make
		run make install_sw
		run strip --strip-all $PREFIX/bin/openssl
		run strip --strip-debug $PREFIX/lib/libcrypto.a
		run strip --strip-debug $PREFIX/lib/libssl.a
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

if [[ "$SKIP_OPENSSL" != 1 ]]; then
	install_openssl /hbb_nopic
	install_openssl /hbb_pic
	install_openssl /hbb_deadstrip_hardened_pie
fi


### libcurl

function install_curl()
{
	local PREFIX="$1"

	header "Installing Curl $CURL_VERSION static libraries: $PREFIX"
	download_and_extract curl-$CURL_VERSION.tar.gz \
		curl-$CURL_VERSION \
		http://curl.haxx.se/download/curl-$CURL_VERSION.tar.bz2

	(
		source "$PREFIX/activate"
		./configure --prefix="$PREFIX" --disable-shared --disable-debug --enable-optimize --disable-werror \
			--disable-curldebug --enable-symbol-hiding --disable-ares --disable-manual --disable-ldap --disable-ldaps \
			--disable-rtsp --disable-dict --disable-ftp --disable-ftps --disable-gopher --disable-imap \
			--disable-imaps --disable-pop3 --disable-pop3s --without-librtmp --disable-smtp --disable-smtps \
			--disable-telnet --disable-tftp --disable-smb --disable-versioned-symbols \
			--without-libmetalink --without-libidn --without-libssh2 --without-libmetalink --without-nghttp2 \
			--with-ssl
		run make -j$MAKE_CONCURRENCY install-strip
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf curl-$CURL_VERSION
}

if [[ "$SKIP_CURL" != 1 ]]; then
	install_curl /hbb_nopic
	install_curl /hbb_pic
	install_curl /hbb_deadstrip_hardened_pie
fi


### Finalizing

if [[ "$SKIP_FINALIZE" != 1 ]]; then
	header "Finalizing"
	run yum clean -y all
	run rm -rf /hbb_build /tmp/*
fi
