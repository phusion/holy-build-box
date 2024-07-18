VERSION = 4.0.0
ifneq ($VERSION, edge)
MAJOR_VERSION := $(shell awk -v OFS=. -F. '{print $$1,$$2}' <<< $(VERSION))
endif
ifeq ($(GITHUB_ACTIONS),true)
IMG_REPO = ghcr.io
else
IMG_REPO = docker.io
endif
OWNER = phusion
DISABLE_OPTIMIZATIONS = 0
IMAGE = $(IMG_REPO)/$(OWNER)/holy-build-box

.PHONY: build_amd64 test_amd64 tags_amd64 push_amd64 build_arm64 test_arm64 tags_arm64 push_arm64 release

build_amd64:
	docker buildx build --load --platform "linux/amd64" --rm -t $(IMAGE):$(VERSION)-amd64 --pull --build-arg DISABLE_OPTIMIZATIONS=$(DISABLE_OPTIMIZATIONS) .

build_arm64:
	docker buildx build --load --platform "linux/arm64" --rm -t $(IMAGE):$(VERSION)-arm64 --pull --build-arg DISABLE_OPTIMIZATIONS=$(DISABLE_OPTIMIZATIONS) .

test_amd64:
	docker run -it --platform "linux/amd64" --rm -e SKIP_FINALIZE=1 -e DISABLE_OPTIMIZATIONS=1 -v $$(pwd)/image:/hbb_build:ro rockylinux:8 bash /hbb_build/build.sh

test_arm64:
	docker run -it --platform "linux/arm64" --rm -e SKIP_FINALIZE=1 -e DISABLE_OPTIMIZATIONS=1 -v $$(pwd)/image:/hbb_build:ro rockylinux:8 bash /hbb_build/build.sh

tags_amd64:
ifdef MAJOR_VERSION
	docker tag $(IMAGE):$(VERSION)-amd64 $(IMAGE):$(MAJOR_VERSION)-amd64
	docker tag $(IMAGE):$(VERSION)-amd64 $(IMAGE):latest-amd64
endif

tags_arm64:
ifdef MAJOR_VERSION
	docker tag $(IMAGE):$(VERSION)-arm64 $(IMAGE):$(MAJOR_VERSION)-arm64
	docker tag $(IMAGE):$(VERSION)-arm64 $(IMAGE):latest-arm64
endif

push_amd64: tags_amd64
	docker push $(IMAGE):$(VERSION)-amd64
ifdef MAJOR_VERSION
	docker push $(IMAGE):$(MAJOR_VERSION)-amd64
	docker push $(IMAGE):latest-amd64
endif

push_arm64: tags_arm64
	docker push $(IMAGE):$(VERSION)-arm64
ifdef MAJOR_VERSION
	docker push $(IMAGE):$(MAJOR_VERSION)-arm64
	docker push $(IMAGE):latest-arm64
endif

release: push_amd64 push_arm64
	docker manifest create $(IMAGE):$(VERSION) $(IMAGE):$(VERSION)-amd64 $(IMAGE):$(VERSION)-arm64
	docker manifest push $(IMAGE):$(VERSION)
ifdef MAJOR_VERSION
	docker manifest create $(IMAGE):$(MAJOR_VERSION) $(IMAGE):$(MAJOR_VERSION)-amd64 $(IMAGE):$(MAJOR_VERSION)-arm64
	docker manifest create $(IMAGE):latest $(IMAGE):latest-amd64 $(IMAGE):latest-arm64
	docker manifest push $(IMAGE):$(MAJOR_VERSION)
	docker manifest push $(IMAGE):latest
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"
endif
