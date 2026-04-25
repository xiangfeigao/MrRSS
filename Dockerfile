# 多阶段构建 MrRSS 服务器版本
FROM golang:1.25-alpine AS builder

# 安装构建依赖
RUN apk add --no-cache git nodejs npm

WORKDIR /build

# 复制源码
COPY . .

# 构建前端
RUN cd frontend && \
    npm ci --silent && \
    npm run build

# 构建服务器版本（关键：-tags server）
RUN go build -tags server -o mrrss-server .

# 最终运行镜像
FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

COPY --from=builder /build/mrrss-server .

EXPOSE 1234

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:1234/api/version || exit 1

CMD ["./mrrss-server"]
