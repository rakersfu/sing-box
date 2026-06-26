FROM alpine:3.20

WORKDIR /app

ARG SING_BOX_VERSION=1.12.24

RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup && \
    apk add --no-cache wget tar ca-certificates && \
    wget -q https://github.com/SagerNet/sing-box/releases/download/v${SING_BOX_VERSION}/sing-box-${SING_BOX_VERSION}-linux-amd64.tar.gz && \
    tar -xzf sing-box-${SING_BOX_VERSION}-linux-amd64.tar.gz && \
    mv sing-box-${SING_BOX_VERSION}-linux-amd64/sing-box ./ && \
    rm -rf sing-box-${SING_BOX_VERSION}-linux-amd64* \
           sing-box-${SING_BOX_VERSION}-linux-amd64.tar.gz \
           /var/cache/apk/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 配置文件复制与赋权，如果是入口文件启动，就注释掉这部分
COPY config.json .
RUN chown appuser:appgroup config.json && \
    chmod 640 config.json

USER appuser

EXPOSE 8080

# 使用 entrypoint 更新配置然后执行 CMD（CMD 可被 docker run 覆盖）
#ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["./sing-box", "run", "-c", "config.json"]
