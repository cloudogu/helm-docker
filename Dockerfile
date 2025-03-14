ARG ALPINE_VERSION=3.15.7
FROM alpine:${ALPINE_VERSION} as base

FROM base as builder
ARG HELM_VERSION=3.17.2
# Kubeval does not have tags, so we use a commit
ARG HELM_KUBEVAL_VERSION=7476464
ARG HELM_VALUES_VERSION=1.2.0

# Make helm install everything in defined folder
ENV HOME=/helm

RUN apk add --no-cache curl git bash gnupg outils-sha256 

RUN wget -q -O helm.tar.gz https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz 
RUN wget -q -O helm.tar.gz.asc https://github.com/helm/helm/releases/download/v${HELM_VERSION}/helm-v${HELM_VERSION}-linux-amd64.tar.gz.asc
RUN wget -q -O helm.tar.gz.sha256 https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256 
RUN tar -xf helm.tar.gz 
# Without the two spaces the check fails!
RUN echo "$(cat helm.tar.gz.sha256)  helm.tar.gz" | sha256sum -c
RUN mkdir -p ${HOME}
RUN wget -q https://raw.githubusercontent.com/helm/helm/main/KEYS -O- | gpg --import
RUN gpg --batch --verify helm.tar.gz.asc helm.tar.gz
RUN mv linux-amd64/helm /usr/local/bin 

# install helm-kubeval via git commit (no tags present)
RUN git clone -n https://github.com/instrumenta/helm-kubeval ${HOME}/.local/share/helm/plugins/helm-kubeval && \
    cd ${HOME}/.local/share/helm/plugins/helm-kubeval && \
    git checkout ${HELM_KUBEVAL_VERSION} && \
    HELM_PLUGIN_DIR=$(pwd) scripts/install.sh && \
    rm -rf .git

# install helm-values
RUN git clone --depth 1 --branch ${HELM_VALUES_VERSION} https://github.com/shihyuho/helm-values /tmp/helm-values
# helm 3 removed the option "home" to get helms home-path, so "helm home" won't work with helm 3
# therefore we need to set the helm home-path manually since the install-binary uses "helm home" to determine helms home path
RUN sed -i 's+"$(helm home)/plugins/helm-values"+"${HOME}/.local/share/helm/plugins/helm-values"+g' /tmp/helm-values/install-binary.sh
RUN mkdir -p ${HOME}/.local/share/helm/plugins/helm-values
RUN /tmp/helm-values/install-binary.sh

# Allow using the helm folder for all users. E.g. Jenkins runs container with its own user and group
RUN chmod a=rwx -R ${HOME}

# Move to folder so we can copy everything 
RUN mkdir -p /dist/usr/local/bin
RUN mv /usr/local/bin/helm /dist/usr/local/bin 
RUN mv ${HOME} /dist/helm 


FROM base
# These can be found out via "helm env"
ENV HELM_CACHE_HOME="/helm/.cache/helm" \
    HELM_CONFIG_HOME="/helm/.config/helm" \
    HELM_DATA_HOME="/helm/.local/share/helm" \
    HELM_PLUGINS="/helm/.local/share/helm/plugins" \
    HELM_REGISTRY_CONFIG="/helm/.config/helm/registry.json" \
    HELM_REPOSITORY_CACHE="/helm/.cache/helm/repository" \
    HELM_REPOSITORY_CONFIG="/helm/.config/helm/repositories.yaml" \
    # Make kubeval binary available on the PATH as well
    PATH="/helm/.local/share/helm/plugins/helm-kubeval/bin:$PATH"
 
RUN apk add --update --no-cache ca-certificates curl git openssl bash
COPY --from=builder /dist /

ENTRYPOINT ["helm"]
CMD ["help"]