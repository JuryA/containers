# PoC Dockerfile demonstrating Bitnami vs Nix artifacts
ARG BASE_IMAGE=debian:bookworm-slim
ARG BASE_SOURCE=bitnami

FROM ${BASE_IMAGE} AS bitnami
# placeholder for existing Bitnami download
RUN mkdir -p /opt/bitnami && echo bitnami > /opt/bitnami/placeholder

FROM ${BASE_IMAGE} AS nix
ADD app-rootfs.tar.gz /

FROM ${BASE_SOURCE}
RUN groupadd --system --gid 1001 bitnami 2>/dev/null || true \
    && useradd --system --uid 1001 --gid bitnami --shell /bin/bash bitnami 2>/dev/null || true
USER 1001
ENTRYPOINT ["/bin/bash"]
CMD ["-c", "echo runtime"]
