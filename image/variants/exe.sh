# shellcheck shell=bash

# shellcheck source=image/activate_func.sh
source /hbb/activate_func.sh
activate_holy_build_box /hbb_exe \
	"" \
	"-static-libstdc++" \
	"" \
	"" \
	"-static-libstdc++"
