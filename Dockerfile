ARG GCL_VERSION=308.0.0-alpine

FROM google/cloud-sdk:${GCL_VERSION}
ARG HELM_VERSION=v3.3.1
ENV HOME=/home

RUN apk add --update ca-certificates \
 && apk add --no-cache curl git openssl bash

# install helm
RUN curl --silent --show-error --fail --location --output get_helm.sh https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get
RUN chmod 700 get_helm.sh
RUN ./get_helm.sh --version "${HELM_VERSION}"
RUN rm get_helm.sh

RUN helm env
RUN chmod -R a=rwx /home

# install helm-kubeval
RUN helm plugin install https://github.com/instrumenta/helm-kubeval

# install helm-values
RUN git clone https://github.com/shihyuho/helm-values.git 
# helm 3 removed the option "home" to get helms home-path, so "helm home" won't work with helm 3.
# therefore we need to set the helm home-path manually since the install-binary uses "helm home" to determine helms home path. 
RUN sed -i 's+"$(helm home)/plugins/helm-values"+"/home/.local/share/helm/plugins/helm-values"+g' helm-values/install-binary.sh
RUN mkdir /home/.local/share/helm/plugins/helm-values
RUN ./helm-values/install-binary.sh
RUN rm -rf helm-values

ENTRYPOINT ["helm"]
CMD ["help"]