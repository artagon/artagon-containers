REGISTRY ?= ghcr.io/artagon/artagon-containers
TYPE ?= chainguard
FLAVOR ?= jdk25
PLATFORMS ?= linux/amd64,linux/arm64
SOURCE_DATE_EPOCH ?= $(shell date +%s)
ENV_DIR := .env
SBOM_DIR := sbom

IMAGE_TAG_chainguard_jdk25 := chainguard-jdk25
IMAGE_TAG_chainguard_jdk26ea := chainguard-jdk26ea
IMAGE_TAG_chainguard_jdk26valhalla := chainguard-jdk26valhalla
IMAGE_TAG_distroless_jdk25 := distroless-jre25
IMAGE_TAG_distroless_jdk26ea := distroless-jre26ea
IMAGE_TAG_distroless_jdk26valhalla := distroless-jre26valhalla
IMAGE_TAG_ubi9_jdk25 := ubi9-jdk25
IMAGE_TAG_ubi9_jdk26ea := ubi9-jdk26ea
IMAGE_TAG_ubi9_jdk26valhalla := ubi9-jdk26valhalla

define image_tag
$($(strip IMAGE_TAG_$(1)_$(2)))
endef

.PHONY: all resolve build build-ci push sbom scan sign attest lint versions clean

all: build

resolve:
	mkdir -p $(ENV_DIR)
	./scripts/resolve_jdk.sh --type=$(TYPE) --flavor=$(FLAVOR) --arch=amd64 --output=$(ENV_DIR)/$(TYPE)-$(FLAVOR)-amd64.env
	./scripts/resolve_jdk.sh --type=$(TYPE) --flavor=$(FLAVOR) --arch=arm64 --output=$(ENV_DIR)/$(TYPE)-$(FLAVOR)-arm64.env

build:
	docker buildx bake $(call image_tag,$(TYPE),$(FLAVOR)) --set *.args.SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH)

build-ci:
	docker buildx bake ci-$(call image_tag,$(TYPE),$(FLAVOR)) --set *.args.SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) --set *.args.BUILD_TARGET=ci


push:
	docker buildx bake $(call image_tag,$(TYPE),$(FLAVOR)) --set *.args.SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) --push

sbom:
	mkdir -p $(SBOM_DIR)
	syft $(REGISTRY):$(call image_tag,$(TYPE),$(FLAVOR)) -o cyclonedx-json > $(SBOM_DIR)/$(TYPE)-$(FLAVOR).cdx.json

scan:
	trivy image --exit-code 1 --severity HIGH,CRITICAL $(REGISTRY):$(call image_tag,$(TYPE),$(FLAVOR))
	grype $(REGISTRY):$(call image_tag,$(TYPE),$(FLAVOR))

sign:
	@digest=$$(docker buildx imagetools inspect $(REGISTRY):$(call image_tag,$(TYPE),$(FLAVOR)) --format '{{json .Manifest.Digest}}' | tr -d '"'); \
	if [ -z "$$digest" ]; then \
		echo "Unable to resolve digest for $(REGISTRY):$(call image_tag,$(TYPE),$(FLAVOR))" >&2; \
		exit 1; \
	fi; \
	COSIGN_EXPERIMENTAL=1 cosign sign --yes $(REGISTRY)@$$digest

attest: sbom
	COSIGN_EXPERIMENTAL=1 cosign attest \
		--predicate $(SBOM_DIR)/$(TYPE)-$(FLAVOR).cdx.json \
		--type cyclonedx \
		$(REGISTRY):$(call image_tag,$(TYPE),$(FLAVOR))

lint:
	hadolint images/chainguard/Dockerfile.* images/distroless/Dockerfile.* images/ubi9/Dockerfile.*
	DOCKER_CONTENT_TRUST=1 dockle --exit-code 1 $(REGISTRY):$(call image_tag,$(TYPE),$(FLAVOR))

versions:
	./scripts/print_versions.sh

clean:
	rm -rf $(ENV_DIR) $(SBOM_DIR)/*.json
