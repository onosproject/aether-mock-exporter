# SPDX-FileCopyrightText: 2022-present Intel Corporation
# SPDX-FileCopyrightText: 2020-present Open Networking Foundation <info@opennetworking.org>
#
# SPDX-License-Identifier: Apache-2.0


# If any command in a pipe has nonzero status, return that status
SHELL = bash -o pipefail

export CGO_ENABLED=1
export GO111MODULE=on

.PHONY: build

KIND_CLUSTER_NAME           ?= kind
DOCKER_REPOSITORY           ?= onosproject/
ONOS_SDCORE_ADAPTER_VERSION ?= latest

build-tools:=$(shell if [ ! -d "./build/build-tools" ]; then cd build && git clone https://github.com/onosproject/build-tools.git; fi)
include ./build/build-tools/make/onf-common.mk

all: build images

images: # @HELP build simulators image
images: aether-mock-exporter-docker

# @HELP build the go binary in the cmd/aether-mock-exporter package
build:
	go build -o build/_output/aether-mock-exporter ./cmd/aether-mock-exporter

test: build deps license linters
	go test -cover -race github.com/onosproject/aether-mock-exporter/pkg/...
	go test -cover -race github.com/onosproject/aether-mock-exporter/cmd/...

jenkins-test:  # @HELP run the unit tests and source code validation producing a junit style report for Jenkins
jenkins-test: build deps license linters
	TEST_PACKAGES=github.com/onosproject/aether-mock-exporter/... ./build/build-tools/build/jenkins/make-unit

aether-mock-exporter-docker:
	docker build . -f Dockerfile \
	-t ${DOCKER_REPOSITORY}aether-mock-exporter:${ONOS_SDCORE_ADAPTER_VERSION}

kind: # @HELP build Docker images and add them to the currently configured kind cluster
kind: images kind-only

kind-only: # @HELP deploy the image without rebuilding first
kind-only:
	@if [ "`kind get clusters`" = '' ]; then echo "no kind cluster found" && exit 1; fi
	kind load docker-image --name ${KIND_CLUSTER_NAME} ${DOCKER_REPOSITORY}aether-mock-exporter:${ONOS_SDCORE_ADAPTER_VERSION}

publish: # @HELP publish version on github and dockerhub
	./build/build-tools/publish-version ${VERSION} onosproject/aether-mock-exporter

jenkins-publish: # @HELP Jenkins calls this to publish artifacts
	./build/bin/push-images
	./build/build-tools/release-merge-commit

clean:: # @HELP remove all the build artifacts
	rm -rf ./build/_output
	rm -rf ./vendor
	rm -rf ./cmd/aether-mock-exporter/aether-mock-exporter
