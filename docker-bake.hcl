variable "REGISTRY" {
  default = "ghcr.io/artagon/artagon-containers"
}

variable "SOURCE_DATE_EPOCH" {
  default = ""
}

target "common" {
  context   = "."
  args = {
    SOURCE_DATE_EPOCH = SOURCE_DATE_EPOCH
  }
  platforms = ["linux/amd64", "linux/arm64"]
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
  inherits   = ["common"]
  dockerfile = "images/chainguard/Dockerfile.jdk25"
  args = {
    FLAVOR = "jdk25"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:chainguard-jdk25"]
}

target "chainguard-jdk25-musl" {
  inherits = ["chainguard-jdk25"]
  args = {
    LIBC = "musl"
  }
  tags     = ["${REGISTRY}:chainguard-jdk25-musl"]
}

target "chainguard-jdk26ea" {
  inherits   = ["common"]
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
  inherits   = ["common"]
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
  inherits   = ["common"]
  dockerfile = "images/distroless/Dockerfile.jre25"
  args = {
    FLAVOR = "jdk25"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:distroless-jre25"]
}

target "distroless-jre25-musl" {
  inherits   = ["common"]
  dockerfile = "images/distroless/Dockerfile.jre25"
  args = {
    FLAVOR = "jdk25"
    LIBC   = "musl"
  }
  tags = ["${REGISTRY}:distroless-jre25-musl"]
}

target "distroless-jre26ea" {
  inherits   = ["common"]
  dockerfile = "images/distroless/Dockerfile.jre26ea"
  args = {
    FLAVOR = "jdk26ea"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:distroless-jre26ea"]
}

target "distroless-jre26ea-musl" {
  inherits   = ["common"]
  dockerfile = "images/distroless/Dockerfile.jre26ea"
  args = {
    FLAVOR = "jdk26ea"
    LIBC   = "musl"
  }
  tags = ["${REGISTRY}:distroless-jre26ea-musl"]
}

target "distroless-jre26valhalla" {
  inherits   = ["common"]
  dockerfile = "images/distroless/Dockerfile.jre26valhalla"
  args = {
    FLAVOR = "jdk26valhalla"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:distroless-jre26valhalla"]
}

target "distroless-jre26valhalla-musl" {
  inherits   = ["common"]
  dockerfile = "images/distroless/Dockerfile.jre26valhalla"
  args = {
    FLAVOR = "jdk26valhalla"
    LIBC   = "musl"
  }
  tags = ["${REGISTRY}:distroless-jre26valhalla-musl"]
}

# UBI9

target "ubi9-jdk25" {
  inherits   = ["common"]
  dockerfile = "images/ubi9/Dockerfile.jdk25"
  args = {
    FLAVOR = "jdk25"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:ubi9-jdk25"]
}

target "ubi9-jdk26ea" {
  inherits   = ["common"]
  dockerfile = "images/ubi9/Dockerfile.jdk26ea"
  args = {
    FLAVOR = "jdk26ea"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:ubi9-jdk26ea"]
}

target "ubi9-jdk26valhalla" {
  inherits   = ["common"]
  dockerfile = "images/ubi9/Dockerfile.jdk26valhalla"
  args = {
    FLAVOR = "jdk26valhalla"
    LIBC   = "glibc"
  }
  tags = ["${REGISTRY}:ubi9-jdk26valhalla"]
}
