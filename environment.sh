function activate_holy_build_box() {
	local PREFIX="$1"
	local EXTRA_CFLAGS="$2"

	export PATH=$PREFIX/bin:$PATH
	export C_INCLUDE_PATH=$PREFIX/include
	export CPLUS_INCLUDE_PATH=$PREFIX/include
	export LIBRARY_PATH=$PREFIX/lib
	export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:/usr/lib/pkgconfig

	local COMPILER_FLAGS="-O2 -I/hbb/include -L/hbb/lib -fvisibility=hidden $EXTRA_CFLAGS"
	export CFLAGS="$COMPILER_FLAGS"
	export CXXFLAGS="$COMPILER_FLAGS"
	echo "Holy build box activated"
	echo "Prefix: $PREFIX"
	echo "Compiler flags: $COMPILER_FLAGS"
	echo
}
