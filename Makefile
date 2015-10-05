VERSION = 1.0.0
MAJOR_VERSION = 1.0

.PHONY: all 32 64 test tag_latest release

all: 32 64

32:
	docker build --rm -t phusion/holy-build-box-32:$(MAJOR_VERSION) -f Dockerfile-32 --pull .

64:
	docker build --rm -t phusion/holy-build-box-64:$(MAJOR_VERSION) -f Dockerfile-64 --pull .

test:
	echo "*** You should run: SKIP_FINALIZE=1 linux32 bash /hbb_build/build.sh"
	docker run -t -i --rm -v `pwd`/image:/hbb_build:ro phusion/centos-5-32 bash

tag_latest:
	docker tag -f phusion/holy-build-box-32:$(MAJOR_VERSION) phusion/holy-build-box-32:latest
	docker tag -f phusion/holy-build-box-64:$(MAJOR_VERSION) phusion/holy-build-box-64:latest

release: tag_latest
	docker push phusion/holy-build-box-32
	docker push phusion/holy-build-box-64
	@echo "*** Don't forget to create a tag. git tag rel-$(MAJOR_VERSION) && git push origin rel-$(MAJOR_VERSION)"
