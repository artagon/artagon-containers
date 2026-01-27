#!/usr/bin/env python3
"""Resolve image digests for all tags using docker buildx imagetools."""

import json
import os
import subprocess


def main():
    tags = os.environ["TAGS"].split()
    image = os.environ["IMAGE"]
    digest_map = {}

    for tag in tags:
        result = subprocess.check_output(
            ["docker", "buildx", "imagetools", "inspect", f"{image}:{tag}", "--format", "{{json .Manifest.Digest}}"],
            text=True,
        ).strip().strip('"')
        digest_map[tag] = result

    print(json.dumps(digest_map))


if __name__ == "__main__":
    main()
