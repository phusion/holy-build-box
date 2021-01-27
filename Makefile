VERSION = 3.0.2
MAJOR_VERSION = 3.0

.PHONY: all 64 test64 tags release

all: 64

64:
	docker build --rm --squash -t phusion/holy-build-box-64:$(VERSION) -f Dockerfile-64 --pull .

test64:
	@echo "*** You should run: SKIP_FINALIZE=1 bash /hbb_build/build.sh"
	docker run -t -i --rm -e DISABLE_OPTIMIZATIONS=1 -v `pwd`/image:/hbb_build:ro centos:7 bash

tags:
	docker tag phusion/holy-build-box-64:$(VERSION) phusion/holy-build-box-64:$(MAJOR_VERSION)
	docker tag phusion/holy-build-box-64:$(VERSION) phusion/holy-build-box-64:latest

release: tags
	docker push phusion/holy-build-box-64:$(VERSION)
	docker push phusion/holy-build-box-64:$(MAJOR_VERSION)
	docker push phusion/holy-build-box-64:latest
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"
