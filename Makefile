.PHONY: all 32 64 test

all: 32 64

32:
	docker build --rm -t phusion/holy-build-box-32 -f Dockerfile-32 --pull .

64:
	docker build --rm -t phusion/holy-build-box-64 -f Dockerfile-64 --pull .

test:
	echo "*** You should run: SKIP_FINALIZE=1 linux32 bash /hbb_build/build.sh"
	docker run -t -i --rm -v `pwd`:/hbb_build:ro phusion/centos-5-32 bash
