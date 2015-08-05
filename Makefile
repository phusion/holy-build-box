.PHONY: all test

all:
	docker build --rm -t phusion/holy-build-box .

test:
	echo "*** You should run: SKIP_FINALIZE=1 linux32 bash /hbb_build/build.sh"
	docker run -t -i --rm -v `pwd`:/hbb_build:ro phusion/centos-5-32 bash
