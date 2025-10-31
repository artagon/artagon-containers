REGISTRY ?= ghcr.io/artagon/artagon-containers
TYPE ?= chainguard
FLAVOR ?= jdk25
PLATFORMS ?= linux/amd64,linux/arm64
SOURCE_DATE_EPOCH ?= $(shell date +%s)
ENV_DIR := .env
SBOM_DIR := sbom

define image_tag
$(shell case $(1) in \
  chainguard) case $(2) in \
      jdk25) echo "chainguard-jdk25";; \
      jdk26ea) echo "chainguard-jdk26ea";; \
      jdk26valhalla) echo "chainguard-jdk26valhalla";; \
    esac ;; \
  distroless) case $(2) in \
      jdk25) echo "distroless-jre25";; \
      jdk26ea) echo "distroless-jre26ea";; \
      jdk26valhalla) echo "distroless-jre26valhalla";; \
    esac ;; \
  ubi9) case $(2) in \
      jdk25) echo "ubi9-jdk25";; \
      jdk26ea) echo "ubi9-jdk26ea";; \
      jdk26valhalla) echo "ubi9-jdk26valhalla";; \
    esac ;; \
esac)
endef

.PHONY: all resolve build push sbom scan sign attest lint versions clean

all: build

resolve:
	mkdir -p $(ENV_DIR)
	./scripts/resolve_jdk.sh --type=$(TYPE) --flavor=$(FLAVOR) --arch=amd64 --output=$(ENV_DIR)/$(TYPE)-$(FLAVOR)-amd64.env
	./scripts/resolve_jdk.sh --type=$(TYPE) --flavor=$(FLAVOR) --arch=arm64 --output=$(ENV_DIR)/$(TYPE)-$(FLAVOR)-arm64.env

build:
	docker buildx bake $(call image_tag,$(TYPE),$(FLAVOR)) --set *.args.SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH)

push:
	docker buildx bake $(call image_tag,$(TYPE),$(FLAVOR)) --set *.args.SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) --push

sbom:
	mkdir -p $(SBOM_DIR)
	syft $(REGISTRY):$(call image_tag,$(TYPE),$(FLAVOR)) -o cyclonedx-json > $(SBOM_DIR)/$(TYPE)-$(FLAVOR).cdx.json

scan:
	trivy image --exit-code 1 --severity HIGH,CRITICAL $(REGISTRY):$(call image_tag,$(TYPE),$(FLAVOR))
	grype $(REGISTRY):$(call image_tag,$(TYPE),$(FLAVOR))

sign:
	COSIGN_EXPERIMENTAL=1 cosign sign --yes $(REGISTRY):$(call image_tag,$(TYPE),$(FLAVOR))

attest: sbom
	COSIGN_EXPERIMENTAL=1 cosign attest \
		--predicate $(SBOM_DIR)/$(TYPE)-$(FLAVOR).cdx.json \
		--type cyclonedx \
		$(REGISTRY):$(call image_tag,$(TYPE),$(FLAVOR))

lint:
	hadolint images/chainguard/Dockerfile.* images/distroless/Dockerfile.* images/ubi9/Dockerfile.*
	dockle --exit-code 1 $(REGISTRY):$(call image_tag,$(TYPE),$(FLAVOR)) || true

versions:
	./scripts/print_versions.sh

clean:
	rm -rf $(ENV_DIR) $(SBOM_DIR)/*.json
