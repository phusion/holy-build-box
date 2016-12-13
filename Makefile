VERSION = 2.0.0-a4
MAJOR_VERSION = 2
HUBUSER ?= kdmurray91
PROJECT ?= kdm-hbb
IMGNAME = $(HUBUSER)/$(PROJECT)

.PHONY: all 32 64 test tags tag-32 tag-64 release rel-32 rel-64

all: 32 64

32:
	docker build --rm -t $(IMGNAME)-32:$(VERSION) -f Dockerfile-32 --pull .

64:
	docker build --rm -t $(IMGNAME)-64:$(VERSION) -f Dockerfile-64 --pull .

test:
	echo "*** You should run: SKIP_FINALIZE=1 linux32 bash /hbb_build/build.sh"
	docker run -t -i --rm -v `pwd`/image:/hbb_build:ro toopher/centos-i386:centos6 bash

tags: tag-32 tag-64

tag-32:
	docker tag $(IMGNAME)-32:$(VERSION) $(IMGNAME)-32:$(MAJOR_VERSION)
	docker tag $(IMGNAME)-32:$(VERSION) $(IMGNAME)-32:latest

tag-64:
	docker tag $(IMGNAME)-64:$(VERSION) $(IMGNAME)-64:$(MAJOR_VERSION)
	docker tag $(IMGNAME)-64:$(VERSION) $(IMGNAME)-64:latest

rel-32: tag-32
	docker push $(IMGNAME)-32

rel-64: tag-64
	docker push $(IMGNAME)-64

release: rel-32 rel-64
	@echo "*** Don't forget to create a tag:"
	@echo ""
	@echo "   git tag rel-$(VERSION) && git push origin rel-$(VERSION)"
