#!/bin/bash
set -e

PKG_CONFIG_VERSION=0.28
ZLIB_VERSION=1.2.8
OPENSSL_VERSION=1.0.2d

source /hbb_build/functions.sh
source /hbb_build/environment.sh
MAKE_CONCURRENCY=2

#########################

header "Updating system"
run yum update -y

header "Installing compiler toolchain"
run yum install -y gcc gcc-c++ make curl file diffutils patch \
	perl


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
fi


### zlib

function install_zlib()
{
	local PREFIX="$1"
	local EXTRA_CFLAGS="$2"

	header "Installing zlib $ZLIB_VERSION static libraries $EXTRA_CFLAGS"
	download_and_extract zlib-$ZLIB_VERSION.tar.gz \
		zlib-$ZLIB_VERSION \
		http://zlib.net/zlib-$ZLIB_VERSION.tar.gz

	(
		activate_holy_build_box "$PREFIX" "$EXTRA_CFLAGS"
		run ./configure --prefix=$PREFIX --static
		run make -j$MAKE_CONCURRENCY install
	)
	if [[ "$?" != 0 ]]; then false; fi

	echo "Leaving source directory"
	popd >/dev/null
}

if [[ "$SKIP_ZLIB" != 1 ]]; then
	install_zlib /hbb_nopic
	install_zlib /hbb_pic -fPIC
fi


### OpenSSL

function install_openssl()
{
	local PREFIX="$1"
	local EXTRA_CFLAGS="$2"

	header "Installing OpenSSL $OPENSSL_VERSION static libraries $EXTRA_CFLAGS"
	download_and_extract openssl-$OPENSSL_VERSION.tar.gz \
		openssl-$OPENSSL_VERSION \
		http://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz

	(
		activate_holy_build_box "$PREFIX" "$EXTRA_CFLAGS"
		run ./config --prefix=$PREFIX --openssldir=$PREFIX/openssl \
			threads zlib no-shared no-sse2 -fvisibility=hidden $EXTRA_CFLAGS
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
	install_openssl /hbb_pic -fPIC
fi


### Finalizing

if [[ "$SKIP_FINALIZE" != 1 ]]; then
	header "Finalizing"

	run cp /hbb_build/environment.sh /hbb/activate_func.sh
	run cp /hbb_build/activate_pic.sh /hbb_pic/activate
	run cp /hbb_build/activate_nopic.sh /hbb_nopic/activate
	run yum clean -y all
	run rm -rf /hbb_build
fi
