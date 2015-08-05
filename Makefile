.PHONY: all test

all:
	docker build --rm -t phusion/holy-build-box .

test:
	echo "Run: linux32 bash /hbb_build/build.sh"
	docker run -t -i --rm -v `pwd`:/hbb_build:ro phusion/centos-5-32 bash
