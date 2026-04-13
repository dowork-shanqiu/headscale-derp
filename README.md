# headscale-derp

[![Release](https://img.shields.io/github/v/release/dowork-shanqiu/headscale-derp?style=flat-square)](https://github.com/dowork-shanqiu/headscale-derp/releases/latest)
[![Docker Image](https://img.shields.io/badge/ghcr.io-headscale--derp-blue?style=flat-square&logo=docker)](https://github.com/dowork-shanqiu/headscale-derp/pkgs/container/headscale-derp)
[![License](https://img.shields.io/github/license/dowork-shanqiu/headscale-derp?style=flat-square)](LICENSE)

本仓库负责自动构建并发布用于 [headscale](https://github.com/juanfont/headscale) 的 **DERP 中继服务器**（`derper`）。每次推送 `v*.*.*` 格式的 Git 标签，CI 流水线将自动：

- 编译适用于 `linux/amd64`、`linux/arm64`、`linux/arm/v7` 的 `derper` 二进制文件；
- 构建并推送多架构 Docker 镜像到 [GitHub Container Registry](https://github.com/dowork-shanqiu/headscale-derp/pkgs/container/headscale-derp)；
- 在 [Releases](https://github.com/dowork-shanqiu/headscale-derp/releases) 页面附上二进制文件与 `SHA256SUMS.txt`。

---

## 目录

- [什么是 DERP？](#什么是-derp)
- [快速开始](#快速开始)
  - [使用 Docker（推荐）](#使用-docker推荐)
  - [直接下载二进制](#直接下载二进制)
- [headscale 配置](#headscale-配置)
- [常用参数](#常用参数)
- [发布新版本](#发布新版本)
- [许可证](#许可证)

---

## 什么是 DERP？

DERP（Detoured Encrypted Routing Protocol）是 Tailscale / headscale 提供的加密中继协议。当两个节点无法直接建立点对点连接时，流量会通过 DERP 服务器中转。自建 DERP 服务器可以降低延迟并增强隐私性。

---

## 快速开始

### 使用 Docker（推荐）

```bash
docker run -d \
  --name derper \
  --restart unless-stopped \
  -p 443:443/tcp \
  -p 3478:3478/udp \
  ghcr.io/dowork-shanqiu/headscale-derp:latest \
  -hostname your.derp.example.com \
  -certmode manual \
  -certdir /certs \
  -a :443 \
  -stun
```

> **提示**：若需要自动申请 Let's Encrypt 证书，可将 `-certmode manual` 改为 `-certmode letsencrypt`，并确保 443 端口对公网开放。

使用 `docker-compose`：

```yaml
services:
  derper:
    image: ghcr.io/dowork-shanqiu/headscale-derp:latest
    restart: unless-stopped
    ports:
      - "443:443/tcp"
      - "3478:3478/udp"
    volumes:
      - ./certs:/certs:ro
    command:
      - -hostname=your.derp.example.com
      - -certmode=manual
      - -certdir=/certs
      - -a=:443
      - -stun
```

### 直接下载二进制

从 [Releases](https://github.com/dowork-shanqiu/headscale-derp/releases/latest) 页面下载对应架构的二进制文件：

```bash
# 以 linux/amd64 为例
VERSION=1.0.0
curl -L -o derper \
  "https://github.com/dowork-shanqiu/headscale-derp/releases/download/v${VERSION}/derper-linux-amd64"
chmod +x derper

# 验证 SHA256
curl -L -o SHA256SUMS.txt \
  "https://github.com/dowork-shanqiu/headscale-derp/releases/download/v${VERSION}/SHA256SUMS.txt"
sha256sum -c SHA256SUMS.txt --ignore-missing
```

启动：

```bash
./derper -hostname your.derp.example.com -certmode letsencrypt -a :443 -stun
```

---

## headscale 配置

在 headscale 的配置文件（默认 `/etc/headscale/config.yaml`）中添加自定义 DERP 服务器：

```yaml
derp:
  server:
    enabled: false
  urls: []
  paths:
    - /etc/headscale/derp.yaml
```

创建 `/etc/headscale/derp.yaml`：

```yaml
regions:
  900:
    regionid: 900
    regioncode: custom
    regionname: My Custom DERP
    nodes:
      - name: 900a
        regionid: 900
        hostname: your.derp.example.com
        stunport: 3478
        derpport: 443
```

重启 headscale 后，新节点将自动使用此 DERP 服务器。

---

## 常用参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `-hostname` | — | 对外暴露的域名（**必填**） |
| `-a` | `:443` | 监听地址与端口 |
| `-stun` | `false` | 同时启用 STUN 服务（UDP 3478） |
| `-certmode` | `letsencrypt` | 证书模式：`letsencrypt` 或 `manual` |
| `-certdir` | — | `manual` 模式下证书目录 |
| `-verify-clients` | `false` | 是否校验客户端（需配合 headscale 使用） |

更多参数请运行：

```bash
derper --help
```

---

## 发布新版本

向本仓库推送符合 `v*.*.*` 格式的 Git 标签即可触发 CI 自动发布：

```bash
git tag v1.2.3
git push origin v1.2.3
```

CI 将自动完成构建、打包、发布 Release 及推送 Docker 镜像。

---

## 许可证

本仓库的构建脚本与配置文件遵循 [MIT License](LICENSE)。  
`derper` 本身由 Tailscale 团队开发，遵循其原始开源协议（BSD-3-Clause）。
