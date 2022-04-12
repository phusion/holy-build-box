VERSION = 3.0.5
MAJOR_VERSION = 3.0
ARCH = x64
OWNER = foobarwidget
DISABLE_OPTIMIZATIONS = 0
IMAGE = ghcr.io/$(OWNER)/holy-build-box-$(ARCH)

.PHONY: build test tags release

build:
	docker build --rm -t $(IMAGE):$(VERSION) -f Dockerfile-$(ARCH) --pull --build-arg DISABLE_OPTIMIZATIONS=$(DISABLE_OPTIMIZATIONS) .

test:
	@echo "*** You should run: SKIP_FINALIZE=1 bash /hbb_build/build.sh"
	docker run -t -i --rm -e DISABLE_OPTIMIZATIONS=1 -v $$(pwd)/image:/hbb_build:ro centos:7 bash

tags:
	docker tag $(IMAGE):$(VERSION) $(IMAGE):$(MAJOR_VERSION)
	docker tag $(IMAGE):$(VERSION) $(IMAGE):latest

release: tags
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):$(MAJOR_VERSION)
	docker push $(IMAGE):latest
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"
