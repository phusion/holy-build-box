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

.PHONY: build test tags push release

ifeq ($(BUILD_AMD64),0)
_build_amd64 := 0
else
_build_amd64 := 1
endif

ifeq ($(BUILD_ARM64),0)
_build_arm64 := 0
else
_build_arm64 := 1
endif

build:
ifeq ($(_build_amd64),1)
	docker buildx build --platform "linux/amd64" --rm -t $(IMAGE)-amd64:$(VERSION) --pull --build-arg DISABLE_OPTIMIZATIONS=$(DISABLE_OPTIMIZATIONS) .
endif
ifeq ($(_build_arm64),1)
	docker buildx build --platform "linux/arm64" --rm -t $(IMAGE)-arm64:$(VERSION) --pull --build-arg DISABLE_OPTIMIZATIONS=$(DISABLE_OPTIMIZATIONS) .
endif

test:
ifeq ($(_build_amd64),1)
	docker run -it --platform "linux/amd64" --rm -e SKIP_FINALIZE=1 -e DISABLE_OPTIMIZATIONS=1 -v $$(pwd)/image:/hbb_build:ro rockylinux:8 bash /hbb_build/build.sh
endif
ifeq ($(_build_arm64),1)
	docker run -it --platform "linux/arm64" --rm -e SKIP_FINALIZE=1 -e DISABLE_OPTIMIZATIONS=1 -v $$(pwd)/image:/hbb_build:ro rockylinux:8 bash /hbb_build/build.sh
endif

tags:
ifdef MAJOR_VERSION
ifeq ($(_build_amd64),1)
	docker tag $(IMAGE):$(VERSION)-amd64 $(IMAGE):$(MAJOR_VERSION)-amd64
endif
ifeq ($(_build_arm64),1)
	docker tag $(IMAGE):$(VERSION)-arm64 $(IMAGE):$(MAJOR_VERSION)-arm64
endif
ifeq ($(_build_amd64),1)
	docker tag $(IMAGE):$(VERSION)-amd64 $(IMAGE):latest-amd64
endif
ifeq ($(_build_arm64),1)
	docker tag $(IMAGE):$(VERSION)-arm64 $(IMAGE):latest-arm64
endif
endif

push: tags
ifeq ($(_build_amd64),1)
	docker push $(IMAGE):$(VERSION)-amd64
endif
ifeq ($(_build_arm64),1)
	docker push $(IMAGE):$(VERSION)-arm64
endif
ifdef MAJOR_VERSION
ifeq ($(_build_amd64),1)
	docker push $(IMAGE):$(MAJOR_VERSION)-amd64
endif
ifeq ($(_build_arm64),1)
	docker push $(IMAGE):$(MAJOR_VERSION)-arm64
endif
ifeq ($(_build_amd64),1)
	docker push $(IMAGE):latest-amd64
endif
ifeq ($(_build_arm64),1)
	docker push $(IMAGE):latest-arm64
endif
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
