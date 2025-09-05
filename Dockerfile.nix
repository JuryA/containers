# PoC Dockerfile demonstrating Bitnami vs Nix artifacts
ARG BASE_IMAGE=debian:bookworm-slim
FROM ${BASE_IMAGE} AS bitnami
# placeholder for existing Bitnami download
RUN mkdir -p /opt/bitnami && echo bitnami > /opt/bitnami/placeholder

FROM ${BASE_IMAGE} AS nix
ADD app-rootfs.tar.gz /

FROM ${BASE_IMAGE}
ARG BASE_SOURCE=bitnami
COPY --from=${BASE_SOURCE} / /
USER 1001
ENTRYPOINT ["/bin/bash"]
CMD ["-c", "echo runtime"]
