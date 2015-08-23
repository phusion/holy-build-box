function activate_holy_build_box() {
	local PREFIX="$1"
	local EXTRA_CFLAGS="$2"
	local EXTRA_LDFLAGS="$3"

	export PATH=$PREFIX/bin:/hbb/bin:$PATH
	export C_INCLUDE_PATH=$PREFIX/include
	export CPLUS_INCLUDE_PATH=$PREFIX/include
	export LIBRARY_PATH=$PREFIX/lib
	export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:/usr/lib/pkgconfig

	export MINIMAL_CFLAGS="-I$PREFIX/include -L$PREFIX/lib $EXTRA_CFLAGS $EXTRA_LDFLAGS"
	local FULL_CFLAGS="-O2 -fvisibility=hidden $MINIMAL_CFLAGS"
	export CFLAGS="$FULL_CFLAGS"
	export CXXFLAGS="$FULL_CFLAGS"
	export LDFLAGS="-L$PREFIX/lib $EXTRA_LDFLAGS"

	if [[ "$O3_ALLOWED" = "" ]]; then
		export O3_ALLOWED=true
	fi

	echo "Holy build box activated"
	echo "Prefix: $PREFIX"
	echo "Compiler flags: $FULL_CFLAGS"
	echo "Linker flags: $LDFLAGS"
	if ! $O3_ALLOWED; then
		echo "-O3 is not allowed when using these compiler flags."
	fi
	echo
}
