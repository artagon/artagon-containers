{
  description = "artagon-containers development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Container tools
            docker
            docker-buildx

            # GitHub Actions testing
            act
            actionlint

            # Security & signing
            cosign
            syft
            grype
            trivy

            # GitHub CLI
            gh

            # Build tools
            gnumake
            jq
            yq-go

            # Python for scripts
            python312
          ];

          shellHook = ''
            echo "artagon-containers dev environment"
            echo ""
            echo "Available tools:"
            echo "  act          - Run GitHub Actions locally"
            echo "  actionlint   - Lint workflow files"
            echo "  cosign       - Container signing"
            echo "  trivy/grype  - Vulnerability scanning"
            echo ""
            echo "Quick commands:"
            echo "  make lint-workflows  - Validate workflow syntax"
            echo "  make test-ci         - Run CI workflow locally"
            echo ""
          '';
        };
      }
    );
}
