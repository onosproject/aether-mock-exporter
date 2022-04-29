# SPDX-FileCopyrightText: 2022-present Intel Corporation
# SPDX-FileCopyrightText: 2020-present Open Networking Foundation <info@opennetworking.org>
#
# SPDX-License-Identifier: Apache-2.0

FROM onosproject/golang-build:v1.0.0 as build

ENV EXPORTER_ROOT=$GOPATH/src/github.com/onosproject/aether-mock-exporter
ENV CGO_ENABLED=0

RUN mkdir -p $EXPORTER_ROOT/

COPY . $EXPORTER_ROOT/

RUN cat $EXPORTER_ROOT/go.mod

RUN cd $EXPORTER_ROOT && GO111MODULE=on go build -o /go/bin/aether-mock-exporter ./cmd/aether-mock-exporter

FROM alpine:3.11
RUN apk add bash openssl curl libc6-compat

ENV HOME=/home/sdcore-adapter

RUN mkdir $HOME
WORKDIR $HOME

COPY --from=build /go/bin/aether-mock-exporter /usr/local/bin/

