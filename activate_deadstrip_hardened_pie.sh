source /hbb/activate_func.sh
export O3_ALLOWED=false
activate_holy_build_box /hbb_deadstrip_hardened_pie \
	"-ffunction-sections -fdata-sections -fstack-protector -fPIE -D_FORTIFY_SOURCE=2" \
	"-Wl,--gc-sections -pie -Wl,-z,relro"
