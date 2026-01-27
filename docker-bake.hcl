variable "REGISTRY" {
  default = "ghcr.io/artagon/artagon-containers"
}

variable "SOURCE_DATE_EPOCH" {
  default = ""
}

# Base image digests - populated from versions/*.lock files
# Override via: docker buildx bake --set *.args.WOLFI_DIGEST=sha256:...
# Or set environment variables before running bake
variable "WOLFI_DIGEST" {
  default = ""
}

variable "ALPINE_DIGEST" {
  default = ""
}

variable "UBI9_DIGEST" {
  default = ""
}

variable "UBI9_MINIMAL_DIGEST" {
  default = ""
}

variable "DISTROLESS_DIGEST" {
  default = ""
}

target "common" {
  context   = "."
  args = {
    SOURCE_DATE_EPOCH = SOURCE_DATE_EPOCH
  }
  platforms = ["linux/amd64", "linux/arm64"]
}

# Common args for Chainguard images (Wolfi + Alpine bases)
target "common-chainguard" {
  args = {
    WOLFI_DIGEST  = WOLFI_DIGEST
    ALPINE_DIGEST = ALPINE_DIGEST
  }
}

# Common args for Distroless images
target "common-distroless" {
  args = {
    WOLFI_DIGEST      = WOLFI_DIGEST
    ALPINE_DIGEST     = ALPINE_DIGEST
    DISTROLESS_DIGEST = DISTROLESS_DIGEST
  }
}

# Common args for UBI9 images
target "common-ubi9" {
  args = {
    BUILDER_DIGEST = UBI9_DIGEST
  }
}

group "default" {
  targets = [
    "chainguard-jdk25",
    "chainguard-jdk25-musl",
    "chainguard-jdk26ea",
    "chainguard-jdk26ea-musl",
    "chainguard-jdk26valhalla",
    "chainguard-jdk26valhalla-musl",
    "distroless-jre25",
    "distroless-jre25-musl",
    "distroless-jre26ea",
    "distroless-jre26ea-musl",
    "distroless-jre26valhalla",
    "distroless-jre26valhalla-musl",
    "ubi9-jdk25",
    "ubi9-jdk26ea",
    "ubi9-jdk26valhalla",
  ]
}

# Chainguard

target "chainguard-jdk25" {
  inherits   = ["common", "common-chainguard"]
  dockerfile = "images/chainguard/Dockerfile.jdk25"
  target     = "runtime-glibc"
  args = {
    FLAVOR = "jdk25"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:chainguard-jdk25"]
}

target "chainguard-jdk25-musl" {
  inherits = ["chainguard-jdk25"]
  target   = "runtime-musl"
  args = {
    LIBC = "musl"
  }
  tags     = ["${REGISTRY}:chainguard-jdk25-musl"]
}

target "chainguard-jdk26ea" {
  inherits   = ["common", "common-chainguard"]
  dockerfile = "images/chainguard/Dockerfile.jdk26ea"
  args = {
    FLAVOR = "jdk26ea"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:chainguard-jdk26ea"]
}

target "chainguard-jdk26ea-musl" {
  inherits = ["chainguard-jdk26ea"]
  args = {
    LIBC = "musl"
  }
  tags     = ["${REGISTRY}:chainguard-jdk26ea-musl"]
}

target "chainguard-jdk26valhalla" {
  inherits   = ["common", "common-chainguard"]
  dockerfile = "images/chainguard/Dockerfile.jdk26valhalla"
  args = {
    FLAVOR = "jdk26valhalla"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:chainguard-jdk26valhalla"]
}

target "chainguard-jdk26valhalla-musl" {
  inherits = ["chainguard-jdk26valhalla"]
  args = {
    LIBC = "musl"
  }
  tags     = ["${REGISTRY}:chainguard-jdk26valhalla-musl"]
}

# Distroless

target "distroless-jre25" {
  inherits   = ["common", "common-distroless"]
  dockerfile = "images/distroless/Dockerfile.jre25"
  args = {
    FLAVOR = "jdk25"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:distroless-jre25"]
}

target "distroless-jre25-musl" {
  inherits   = ["common", "common-distroless"]
  dockerfile = "images/distroless/Dockerfile.jre25"
  args = {
    FLAVOR = "jdk25"
    LIBC   = "musl"
  }
  tags = ["${REGISTRY}:distroless-jre25-musl"]
}

target "distroless-jre26ea" {
  inherits   = ["common", "common-distroless"]
  dockerfile = "images/distroless/Dockerfile.jre26ea"
  args = {
    FLAVOR = "jdk26ea"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:distroless-jre26ea"]
}

target "distroless-jre26ea-musl" {
  inherits   = ["common", "common-distroless"]
  dockerfile = "images/distroless/Dockerfile.jre26ea"
  args = {
    FLAVOR = "jdk26ea"
    LIBC   = "musl"
  }
  tags = ["${REGISTRY}:distroless-jre26ea-musl"]
}

target "distroless-jre26valhalla" {
  inherits   = ["common", "common-distroless"]
  dockerfile = "images/distroless/Dockerfile.jre26valhalla"
  args = {
    FLAVOR = "jdk26valhalla"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:distroless-jre26valhalla"]
}

target "distroless-jre26valhalla-musl" {
  inherits   = ["common", "common-distroless"]
  dockerfile = "images/distroless/Dockerfile.jre26valhalla"
  args = {
    FLAVOR = "jdk26valhalla"
    LIBC   = "musl"
  }
  tags = ["${REGISTRY}:distroless-jre26valhalla-musl"]
}

# UBI9

target "ubi9-jdk25" {
  inherits   = ["common", "common-ubi9"]
  dockerfile = "images/ubi9/Dockerfile.jdk25"
  args = {
    FLAVOR = "jdk25"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:ubi9-jdk25"]
}

target "ubi9-jdk26ea" {
  inherits   = ["common", "common-ubi9"]
  dockerfile = "images/ubi9/Dockerfile.jdk26ea"
  args = {
    FLAVOR = "jdk26ea"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:ubi9-jdk26ea"]
}

target "ubi9-jdk26valhalla" {
  inherits   = ["common", "common-ubi9"]
  dockerfile = "images/ubi9/Dockerfile.jdk26valhalla"
  args = {
    FLAVOR = "jdk26valhalla"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:ubi9-jdk26valhalla"]
}

# CI Targets

target "common-ci" {
  inherits = ["common"]
  args = {
    BUILD_TARGET = "ci"
  }
  platforms = ["linux/amd64"]
}

target "ci-chainguard-jdk25" {
  inherits = ["chainguard-jdk25", "common-ci"]
  tags     = ["${REGISTRY}:ci-chainguard-jdk25"]
}

target "ci-chainguard-jdk25-musl" {
  inherits = ["chainguard-jdk25-musl", "common-ci"]
  tags     = ["${REGISTRY}:ci-chainguard-jdk25-musl"]
}

target "ci-chainguard-jdk26ea" {
  inherits = ["chainguard-jdk26ea", "common-ci"]
  tags     = ["${REGISTRY}:ci-chainguard-jdk26ea"]
}

target "ci-chainguard-jdk26ea-musl" {
  inherits = ["chainguard-jdk26ea-musl", "common-ci"]
  tags     = ["${REGISTRY}:ci-chainguard-jdk26ea-musl"]
}

target "ci-chainguard-jdk26valhalla" {
  inherits = ["chainguard-jdk26valhalla", "common-ci"]
  tags     = ["${REGISTRY}:ci-chainguard-jdk26valhalla"]
}

target "ci-chainguard-jdk26valhalla-musl" {
  inherits = ["chainguard-jdk26valhalla-musl", "common-ci"]
  tags     = ["${REGISTRY}:ci-chainguard-jdk26valhalla-musl"]
}

target "ci-distroless-jre25" {
  inherits = ["distroless-jre25", "common-ci"]
  tags     = ["${REGISTRY}:ci-distroless-jre25"]
}

target "ci-distroless-jre25-musl" {
  inherits = ["distroless-jre25-musl", "common-ci"]
  tags     = ["${REGISTRY}:ci-distroless-jre25-musl"]
}

target "ci-distroless-jre26ea" {
  inherits = ["distroless-jre26ea", "common-ci"]
  tags     = ["${REGISTRY}:ci-distroless-jre26ea"]
}

target "ci-distroless-jre26ea-musl" {
  inherits = ["distroless-jre26ea-musl", "common-ci"]
  tags     = ["${REGISTRY}:ci-distroless-jre26ea-musl"]
}

target "ci-distroless-jre26valhalla" {
  inherits = ["distroless-jre26valhalla", "common-ci"]
  tags     = ["${REGISTRY}:ci-distroless-jre26valhalla"]
}

target "ci-distroless-jre26valhalla-musl" {
  inherits = ["distroless-jre26valhalla-musl", "common-ci"]
  tags     = ["${REGISTRY}:ci-distroless-jre26valhalla-musl"]
}

target "ci-ubi9-jdk25" {
  inherits = ["ubi9-jdk25", "common-ci"]
  tags     = ["${REGISTRY}:ci-ubi9-jdk25"]
}

target "ci-ubi9-jdk26ea" {
  inherits = ["ubi9-jdk26ea", "common-ci"]
  tags     = ["${REGISTRY}:ci-ubi9-jdk26ea"]
}

target "ci-ubi9-jdk26valhalla" {
  inherits = ["ubi9-jdk26valhalla", "common-ci"]
  tags     = ["${REGISTRY}:ci-ubi9-jdk26valhalla"]
}

group "ci" {
  targets = [
    "ci-chainguard-jdk25",
    "ci-chainguard-jdk25-musl",
    "ci-chainguard-jdk26ea",
    "ci-chainguard-jdk26ea-musl",
    "ci-chainguard-jdk26valhalla",
    "ci-chainguard-jdk26valhalla-musl",
    "ci-distroless-jre25",
    "ci-distroless-jre25-musl",
    "ci-distroless-jre26ea",
    "ci-distroless-jre26ea-musl",
    "ci-distroless-jre26valhalla",
    "ci-distroless-jre26valhalla-musl",
    "ci-ubi9-jdk25",
    "ci-ubi9-jdk26ea",
    "ci-ubi9-jdk26valhalla",
  ]
}
