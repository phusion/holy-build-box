function activate_holy_build_box() {
	local PREFIX="$1"
	local EXTRA_CFLAGS="$2"
	local EXTRA_LDFLAGS="$3"
	local EXTRA_STATICLIB_CFLAGS="$4"
	local SHLIB_CFLAGS="$5"
	local SHLIB_LDFLAGS=""

	export PATH=$PREFIX/bin:/hbb/bin:$PATH
	export C_INCLUDE_PATH=$PREFIX/include
	export CPLUS_INCLUDE_PATH=$PREFIX/include
	export LIBRARY_PATH=$PREFIX/lib
	export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:/usr/lib/pkgconfig

	local MINIMAL_CFLAGS="-O2 -fvisibility=hidden -I$PREFIX/include -L$PREFIX/lib"
	export CFLAGS="$MINIMAL_CFLAGS $EXTRA_CFLAGS"
	export CXXFLAGS="$MINIMAL_CFLAGS $EXTRA_CFLAGS"
	export LDFLAGS="-L$PREFIX/lib $EXTRA_LDFLAGS"
	export STATICLIB_CFLAGS="$MINIMAL_CFLAGS $EXTRA_STATICLIB_CFLAGS"
	export SHLIB_CFLAGS="$MINIMAL_CFLAGS $EXTRA_SHLIB_CFLAGS"
	export SHLIB_CXXFLAGS="$MINIMAL_CFLAGS $EXTRA_SHLIB_CFLAGS"
	export SHLIB_LDFLAGS="-L$PREFIX/lib $EXTRA_SHLIB_LDFLAGS"

	if [[ "$O3_ALLOWED" = "" ]]; then
		export O3_ALLOWED=true
	fi

	echo "Holy build box activated"
	echo "Prefix: $PREFIX"
	echo "CFLAGS: $CFLAGS"
	echo "LDFLAGS: $LDFLAGS"
	echo "STATICLIB_CFLAGS: $STATICLIB_CFLAGS"
	echo "SHLIB_CFLAGS: $SHLIB_CFLAGS"
	echo "SHLIB_LDFLAGS: $SHLIB_LDFLAGS"
	if ! $O3_ALLOWED; then
		echo "-O3 is not allowed when using these compiler flags."
	fi
	echo
}
