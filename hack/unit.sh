#!/bin/sh

set -eux

IS_CONTAINER=${IS_CONTAINER:-false}
ARTIFACTS=${ARTIFACTS:-/tmp}
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"

if [ "${IS_CONTAINER}" != "false" ]; then
  eval "$(go env)"
  cd "${GOPATH}"/src/github.com/metal3-io/baremetal-operator
  export XDG_CACHE_HOME="/tmp/.cache"
  go test -v ./pkg/... ./cmd/... -coverprofile "${ARTIFACTS}"/cover.out
else
  "${CONTAINER_RUNTIME}" run --rm \
    --env IS_CONTAINER=TRUE \
    --env DEPLOY_KERNEL_URL=http://172.22.0.1/images/ironic-python-agent.kernel \
    --env DEPLOY_RAMDISK_URL=http://172.22.0.1/images/ironic-python-agent.initramfs \
    --env IRONIC_ENDPOINT=http://localhost:6385/v1/ \
    --env IRONIC_INSPECTOR_ENDPOINT=http://localhost:5050/v1/ \
    --volume "${PWD}:/go/src/github.com/metal3-io/baremetal-operator:ro,z" \
    --entrypoint sh \
    --workdir /go/src/github.com/metal3-io/baremetal-operator \
    registry.hub.docker.com/library/golang:1.12 \
    /go/src/github.com/metal3-io/baremetal-operator/hack/unit.sh "${@}"
fi;
