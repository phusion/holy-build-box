VERSION = 4.0.2
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

.PHONY: build_amd64 test_amd64 tags_amd64 push_amd64 build_arm64 test_arm64 tags_arm64 push_arm64 export_amd64 export_arm64 release pull_amd64 pull_arm64 cross_tag_arm64 cross_tag_amd64 pull cross_tag tag_latest

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

tag_latest: tags_amd64 tags_arm64

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

export_amd64: tags_amd64
	docker save -o hbb_amd64.tar $(IMAGE):$(VERSION)-amd64

export_arm64: tags_arm64
	docker save -o hbb_arm64.tar $(IMAGE):$(VERSION)-arm64

release: push_amd64 push_arm64
	docker manifest create $(IMAGE):$(VERSION) $(IMAGE):$(VERSION)-amd64 $(IMAGE):$(VERSION)-arm64
	docker manifest push $(IMAGE):$(VERSION)
ifdef MAJOR_VERSION
	docker manifest rm $(IMAGE):$(MAJOR_VERSION) || true
	docker manifest create $(IMAGE):$(MAJOR_VERSION) $(IMAGE):$(MAJOR_VERSION)-amd64 $(IMAGE):$(MAJOR_VERSION)-arm64
	docker manifest push $(IMAGE):$(MAJOR_VERSION)
	docker manifest rm $(IMAGE):latest || true
	docker manifest create $(IMAGE):latest $(IMAGE):latest-amd64 $(IMAGE):latest-arm64
	docker manifest push $(IMAGE):latest
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"
endif

pull_amd64:
	docker pull $(IMAGE):$(VERSION)-amd64

pull_arm64:
	docker pull $(IMAGE):$(VERSION)-arm64

pull: pull_amd64 pull_arm64

cross_tag_amd64:
	docker tag ghcr.io/$(OWNER)/holy-build-box:$(VERSION)-amd64 $(IMAGE):$(VERSION)-amd64

cross_tag_arm64:
	docker tag ghcr.io/$(OWNER)/holy-build-box:$(VERSION)-arm64 $(IMAGE):$(VERSION)-arm64

cross_tag: cross_tag_amd64 cross_tag_arm64
