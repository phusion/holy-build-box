VERSION = 2.0.0-beta
MAJOR_VERSION = 2
HUBUSER ?= kdmurray91
PROJECT ?= kdm-hbb
IMGNAME = $(HUBUSER)/$(PROJECT)

.PHONY: all 32 64 test tags release

all: 32 64

32:
	docker build --rm -t $(IMGNAME)-32:$(VERSION) -f Dockerfile-32 --pull .

64:
	docker build --rm -t $(IMGNAME)-64:$(VERSION) -f Dockerfile-64 --pull .

test:
	echo "*** You should run: SKIP_FINALIZE=1 linux32 bash /hbb_build/build.sh"
	docker run -t -i --rm -v `pwd`/image:/hbb_build:ro toopher/centos-i386:centos6 bash

tags:
	docker tag $(IMGNAME)-32:$(VERSION) $(IMGNAME)-32:$(MAJOR_VERSION)
	docker tag $(IMGNAME)-64:$(VERSION) $(IMGNAME)-64:$(MAJOR_VERSION)
	docker tag $(IMGNAME)-32:$(VERSION) $(IMGNAME)-32:latest
	docker tag $(IMGNAME)-64:$(VERSION) $(IMGNAME)-64:latest

release: tags
	docker push $(IMGNAME)-32
	docker push $(IMGNAME)-64
	@echo "*** Don't forget to create a tag:"
	@echo ""
	@echo "   git tag rel-$(VERSION) && git push origin rel-$(VERSION)"
