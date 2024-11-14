FROM alpine:3.16 as certs
RUN apk --update add ca-certificates

FROM golang:1.22.3 as build
RUN go install go.opentelemetry.io/collector/cmd/builder@v0.111.0 \
    && mv /go/bin/builder /go/bin/ocb

WORKDIR /go/src
COPY . .
RUN ocb --config builder-config.yaml

# Use debian
FROM debian:12-slim

ARG USER_UID=10001
ARG OTEL_BIN=/go/src/otelcol-dev/otelcol-dev
USER ${USER_UID}

COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build --chmod=755 ${OTEL_BIN} /otelcol-contrib
COPY otelcol-contrib.yaml /etc/otelcol-contrib/config.yaml
ENTRYPOINT ["/otelcol-contrib"]
CMD ["--config", "/etc/otelcol-contrib/config.yaml"]
EXPOSE 4317 55678 55679
