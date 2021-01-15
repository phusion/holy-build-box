# shellcheck shell=bash

RESET=$'\e[0m'
BOLD=$'\e[1m'
YELLOW=$'\e[33m'
BLUE_BG=$'\e[44m'

function header()
{
	local title="$1"
	echo
	echo "${BLUE_BG}${YELLOW}${BOLD}${title}${RESET}"
	echo "------------------------------------------"
}

function run()
{
	echo "+ $*"
	"$@"
}

function download_and_extract()
{
	local BASENAME="$1"
	local DIRNAME="$2"
	local URL="$3"
	local regex='\.bz2$'

	if [[ ! -e "/tmp/$BASENAME" ]]; then
		run rm -f "/tmp/$BASENAME.tmp"
		run curl --fail -L -o "/tmp/$BASENAME.tmp" "$URL"
		run mv "/tmp/$BASENAME.tmp" "/tmp/$BASENAME"
	fi
	if [[ "$URL" =~ $regex ]]; then
		run tar xjf "/tmp/$BASENAME"
	else
		run tar xzf "/tmp/$BASENAME"
	fi

	echo "Entering $RUNTIME_DIR/$DIRNAME"
	# shellcheck disable=SC2164
	pushd "$DIRNAME" >/dev/null
}

function eval_bool()
{
	local VAL="$1"
	[[ "$VAL" = 1 || "$VAL" = true || "$VAL" = yes || "$VAL" = y ]]
}
