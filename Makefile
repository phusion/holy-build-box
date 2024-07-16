VERSION = 4.0.0
ifneq ($VERSION, edge)
MAJOR_VERSION := $(shell awk -v OFS=. -F. '{print $$1,$$2}' <<< $(VERSION))
endif
OWNER = phusion
DISABLE_OPTIMIZATIONS = 0
IMAGE = $(OWNER)/holy-build-box

.PHONY: build test tags push release

build:
	docker buildx build --platform "linux/amd64" --rm -t $(IMAGE)-amd64:$(VERSION) --pull --build-arg DISABLE_OPTIMIZATIONS=$(DISABLE_OPTIMIZATIONS) .
	docker buildx build --platform "linux/arm64" --rm -t $(IMAGE)-arm64:$(VERSION) --pull --build-arg DISABLE_OPTIMIZATIONS=$(DISABLE_OPTIMIZATIONS) .

test:
	docker run -it --platform "linux/amd64" --rm -e SKIP_FINALIZE=1 -e DISABLE_OPTIMIZATIONS=1 -v $$(pwd)/image:/hbb_build:ro rockylinux:8 bash /hbb_build/build.sh
	docker run -it --platform "linux/arm64" --rm -e SKIP_FINALIZE=1 -e DISABLE_OPTIMIZATIONS=1 -v $$(pwd)/image:/hbb_build:ro rockylinux:8 bash /hbb_build/build.sh

tags:
ifdef MAJOR_VERSION
	docker tag $(IMAGE):$(VERSION)-arm64 $(IMAGE):$(MAJOR_VERSION)-arm64
	docker tag $(IMAGE):$(VERSION)-amd64 $(IMAGE):$(MAJOR_VERSION)-amd64
	docker tag $(IMAGE):$(VERSION)-arm64 $(IMAGE):latest-arm64
	docker tag $(IMAGE):$(VERSION)-amd64 $(IMAGE):latest-amd64
endif

push: tags
	docker push $(IMAGE):$(VERSION)-amd64
	docker push $(IMAGE):$(VERSION)-arm64
ifdef MAJOR_VERSION
	docker push $(IMAGE):$(MAJOR_VERSION)-amd64
	docker push $(IMAGE):$(MAJOR_VERSION)-arm64
	docker push $(IMAGE):latest-amd64
	docker push $(IMAGE):latest-arm64
endif

release: push
	docker manifest create $(IMAGE):$(VERSION) $(IMAGE):$(VERSION)-amd64 $(IMAGE):$(VERSION)-arm64
ifdef MAJOR_VERSION
	docker manifest create $(IMAGE):$(MAJOR_VERSION) $(IMAGE):$(MAJOR_VERSION)-amd64 $(IMAGE):$(MAJOR_VERSION)-arm64
	docker manifest create $(IMAGE):latest $(IMAGE):latest-amd64 $(IMAGE):latest-arm64
	docker manifest push $(IMAGE):$(MAJOR_VERSION)
endif
	docker manifest push $(IMAGE):$(VERSION)
	docker manifest push $(IMAGE):latest
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"
