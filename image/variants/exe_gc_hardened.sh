# shellcheck shell=bash

# shellcheck source=image/activate_func.sh
source /hbb/activate_func.sh
# Fortify Source requires optimizations, though no higher than -O2.
export DISABLE_OPTIMIZATIONS=false
export O3_ALLOWED=false
activate_holy_build_box /hbb_exe_gc_hardened \
	"-ffunction-sections -fdata-sections -fstack-protector -D_FORTIFY_SOURCE=2 -fPIE" \
	"-static-libstdc++ -Wl,--gc-sections -pie -Wl,-z,relro" \
	"-ffunction-sections -fdata-sections -fstack-protector -D_FORTIFY_SOURCE=2 -fPIE" \
	"-ffunction-sections -fdata-sections -fstack-protector -D_FORTIFY_SOURCE=2 -fPIC" \
	"-static-libstdc++"
