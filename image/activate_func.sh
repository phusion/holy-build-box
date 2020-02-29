function activate_holy_build_box_deps_installation_environment() {
	if [ `uname -m` != x86_64 ]; then
		DEVTOOLSET_VER=7
	else
		DEVTOOLSET_VER=8
	fi
	source /opt/rh/devtoolset-${DEVTOOLSET_VER}/enable
	export PATH=/hbb/bin:$PATH
	export C_INCLUDE_PATH=/hbb/include
	export CPLUS_INCLUDE_PATH=/hbb/include
	export LIBRARY_PATH=/hbb/lib
	export PKG_CONFIG_PATH=/hbb/lib/pkgconfig:/usr/lib/pkgconfig
	export CPPFLAGS=-I/hbb/include
	export LDPATHFLAGS="-L/hbb/lib -Wl,-rpath,/hbb/lib"
	export LDFLAGS="$LDPATHFLAGS"
	export LD_LIBRARY_PATH=/hbb/lib

	echo "Holy build box dependency installation environment activated"
}

function activate_holy_build_box() {
	local PREFIX="$1"
	local EXTRA_CFLAGS="$2"
	local EXTRA_LDFLAGS="$3"
	local EXTRA_STATICLIB_CFLAGS="$4"
	local EXTRA_SHLIB_CFLAGS="$5"
	local EXTRA_SHLIB_LDFLAGS="$6"

	if [ `uname -m` != x86_64 ]; then
		DEVTOOLSET_VER=7
	else
		DEVTOOLSET_VER=8
	fi
	source /opt/rh/devtoolset-${DEVTOOLSET_VER}/enable

	export PATH=$PREFIX/bin:/hbb/bin:$PATH
	export C_INCLUDE_PATH=$PREFIX/include
	export CPLUS_INCLUDE_PATH=$PREFIX/include
	export LIBRARY_PATH=$PREFIX/lib
	export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:/usr/lib/pkgconfig
	export LD_LIBRARY_PATH=/hbb/lib:$PREFIX/lib

	export CPPFLAGS="-I$PREFIX/include"
	export LDPATHFLAGS="-L$PREFIX/lib"
	local MINIMAL_CFLAGS="-g -O2 -fvisibility=hidden $CPPFLAGS"

	export CFLAGS="$MINIMAL_CFLAGS $EXTRA_CFLAGS"
	export CXXFLAGS="$MINIMAL_CFLAGS $EXTRA_CFLAGS"
	export LDFLAGS="$LDPATHFLAGS $EXTRA_LDFLAGS"
	export STATICLIB_CFLAGS="$MINIMAL_CFLAGS $EXTRA_STATICLIB_CFLAGS"
	export STATICLIB_CXXFLAGS="$MINIMAL_CFLAGS $EXTRA_STATICLIB_CFLAGS"
	export SHLIB_CFLAGS="$MINIMAL_CFLAGS $EXTRA_SHLIB_CFLAGS"
	export SHLIB_CXXFLAGS="$MINIMAL_CFLAGS $EXTRA_SHLIB_CFLAGS"
	export SHLIB_LDFLAGS="$LDPATHFLAGS $EXTRA_SHLIB_LDFLAGS"

	if [[ "$O3_ALLOWED" = "" ]]; then
		export O3_ALLOWED=true
	fi

	echo "Holy build box activated"
	echo "Prefix: $PREFIX"
	echo "CFLAGS/CXXFLAGS: $CFLAGS"
	echo "LDFLAGS: $LDFLAGS"
	echo "STATICLIB_CFLAGS: $STATICLIB_CFLAGS"
	echo "SHLIB_CFLAGS: $SHLIB_CFLAGS"
	echo "SHLIB_LDFLAGS: $SHLIB_LDFLAGS"
	if ! $O3_ALLOWED; then
		echo "-O3 is not allowed when using these compiler flags."
	fi
	echo
}
