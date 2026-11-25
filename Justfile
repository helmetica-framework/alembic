# Tool versions. Renovate reads the comment directly above each variable.
# renovate: datasource=go depName=github.com/google/go-jsonnet
jsonnet_version := "v0.22.0"
jsonnet := "go run github.com/google/go-jsonnet/cmd/jsonnet@" + jsonnet_version
jsonnetfmt := "go run github.com/google/go-jsonnet/cmd/jsonnetfmt@" + jsonnet_version

# renovate: datasource=go depName=sigs.k8s.io/kustomize/kustomize/v5
kustomize_version := "v5.8.3"
kustomize := "go run sigs.k8s.io/kustomize/kustomize/v5@" + kustomize_version

# Test instances, one per platform. Add a new tests/<name>.jsonnet here.
instances := "kind talos openshift4"

# Output directories. Override before the recipe: `just vendor_dir=.work/x vendor`.
vendor_dir    := "vendor"
manifests_dir := "manifests"
golden_dir    := "tests/golden"

# List the recipes.
default:
    @just --list

# Vendor every upstream kustomize dir at its pinned tag into vendor/.
vendor:
    #!/usr/bin/env bash
    set -euo pipefail
    {{jsonnet}} -S hack/vendor.jsonnet \
        | KUSTOMIZE="{{kustomize}}" hack/vendor.sh "{{vendor_dir}}"

# Write the golden files of all test instances.
gen-golden: vendor
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{golden_dir}}"
    for i in {{instances}}; do
        echo "rendering $i"
        rm -rf "{{golden_dir}}/$i"
        {{jsonnet}} -S -c -m "{{golden_dir}}/$i" \
            --tla-code-file settings="tests/$i.jsonnet" \
            tests/render.jsonnet >/dev/null
    done

# Fail if vendor/, manifests/ or tests/golden/ are out of date.
golden-diff: vendor
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf .work/golden-diff
    just vendor_dir=.work/golden-diff/vendor vendor
    just golden_dir=.work/golden-diff/golden gen-golden
    # Empty output dirs are not committed, so create them before diffing.
    mkdir -p "{{vendor_dir}}" "{{manifests_dir}}" "{{golden_dir}}"
    diff -ru "{{vendor_dir}}" .work/golden-diff/vendor
    diff -ru "{{golden_dir}}" .work/golden-diff/golden

# Fail if a jsonnet file is not formatted.
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    mapfile -t files < <(find . \( -name .git -o -name vendor -o -name .work \) -prune -o \
        \( -name '*.jsonnet' -o -name '*.libsonnet' \) -print)
    if [ ${#files[@]} -gt 0 ]; then
        {{jsonnetfmt}} --test --pad-arrays -- "${files[@]}"
    fi

# Format all jsonnet files.
fmt:
    #!/usr/bin/env bash
    set -euo pipefail
    mapfile -t files < <(find . \( -name .git -o -name vendor -o -name .work \) -prune -o \
        \( -name '*.jsonnet' -o -name '*.libsonnet' \) -print)
    if [ ${#files[@]} -gt 0 ]; then
        {{jsonnetfmt}} --in-place --pad-arrays -- "${files[@]}"
    fi

# Build the docs as they appear on docs.helmetica.io; fails on warnings
docs:
    GOTOOLCHAIN=auto GOEXPERIMENT=jsonv2 go run github.com/helmetica-framework/rosarium@v0.1.0 preview .

# Build the docs and serve them on http://localhost:2020
docs-serve:
    GOTOOLCHAIN=auto GOEXPERIMENT=jsonv2 go run github.com/helmetica-framework/rosarium@v0.1.0 preview . --serve :2020
