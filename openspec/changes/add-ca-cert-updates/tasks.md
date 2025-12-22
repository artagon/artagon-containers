# Tasks: CA Certificate Updates

- [ ] Modify `images/chainguard/Dockerfile.jdk25` to install `ca-certificates` in runtime stages.
- [ ] Modify `images/chainguard/Dockerfile.jdk26ea` to install `ca-certificates` in runtime stages.
- [ ] Modify `images/chainguard/Dockerfile.jdk26valhalla` to install `ca-certificates` in runtime stages.
- [ ] Modify `images/ubi9/Dockerfile.jdk25` to update `ca-certificates` in runtime stage.
- [ ] Modify `images/ubi9/Dockerfile.jdk26ea` to update `ca-certificates` in runtime stage.
- [ ] Modify `images/ubi9/Dockerfile.jdk26valhalla` to update `ca-certificates` in runtime stage.
- [ ] Add comments to `images/distroless/Dockerfile.*` explaining the base image update strategy.
- [ ] Verify builds pass and logs show package activity.
