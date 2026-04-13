# syntax=docker/dockerfile:1

ARG GO_VERSION=1.24
ARG ALPINE_VERSION=3.21

# ─── 构建阶段 ─────────────────────────────────────────────────────────────────
FROM golang:${GO_VERSION}-alpine AS builder

RUN apk add --no-cache git ca-certificates tzdata

ARG DERPER_VERSION=latest

# 拉取 tailscale 源码并编译 derper
RUN if [ "$DERPER_VERSION" = "latest" ]; then \
      go install tailscale.com/cmd/derper@latest; \
    else \
      go install tailscale.com/cmd/derper@v${DERPER_VERSION}; \
    fi

# ─── 运行阶段 ─────────────────────────────────────────────────────────────────
FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache ca-certificates tzdata

COPY --from=builder /go/bin/derper /usr/local/bin/derper

# 默认端口：HTTPS 443、STUN 3478
EXPOSE 443/tcp 3478/udp

ENTRYPOINT ["derper"]
CMD ["--help"]
