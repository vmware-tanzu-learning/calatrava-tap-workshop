FROM quay.io/eduk8s/base-environment:master as builder

USER root

WORKDIR /build

RUN curl -Lo pivnet https://github.com/pivotal-cf/pivnet-cli/releases/download/v3.0.1/pivnet-linux-amd64-3.0.1

RUN install -o root -g root -m 0755 pivnet /usr/local/bin/pivnet

ARG PIVNET_TOKEN
RUN pivnet login --api-token=$PIVNET_TOKEN

RUN pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version='1.1.0' --product-file-id=1191987
RUN mkdir tanzu-cluster-essentials
RUN tar -xvf tanzu-cluster-essentials-linux-amd64-1.1.0.tgz -C ./tanzu-cluster-essentials
RUN fix-permissions ./tanzu-cluster-essentials

RUN pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='1.1.0' --product-file-id=1190781

RUN curl -Lo terraform.zip https://releases.hashicorp.com/terraform/1.1.3/terraform_1.1.3_linux_amd64.zip
RUN unzip terraform.zip
RUN chmod a+x terraform

RUN mkdir -p /home/eduk8s/tanzu
ENV HOME=/home/eduk8s
RUN tar -xvf tanzu-framework-linux-amd64.tar -C /home/eduk8s/tanzu

WORKDIR /home/eduk8s/tanzu
RUN install cli/core/v0.11.2/tanzu-core-linux_amd64 /usr/local/bin/tanzu
ENV TANZU_CLI_NO_INIT=true
RUN tanzu plugin install --local cli all
# Next line is according to documentation -- but doesn't work!
#RUN tanzu plugin install --local cli/standalone all

RUN fix-permissions /home/eduk8s

FROM quay.io/eduk8s/base-environment:master

USER root

RUN yum install -y openssl

# Add our own CA root file to the trusted certs
COPY ./.certs/VMwareRoot.crt /etc/pki/ca-trust/source/anchors
RUN update-ca-trust

COPY --from=builder --chown=0:0 \
  /build/tanzu-cluster-essentials/kapp \
  /build/tanzu-cluster-essentials/ytt \
  /build/terraform \
  /usr/local/bin/tanzu \
  /usr/local/bin/

RUN chmod a+x /usr/local/bin/kapp /usr/local/bin/ytt /usr/local/bin/terraform /usr/local/bin/tanzu

COPY --chown=1001:0 --from=builder /home/eduk8s/.cache /home/eduk8s/.cache
COPY --chown=1001:0 --from=builder /home/eduk8s/.local /home/eduk8s/.local

COPY --chown=1001:0 --from=builder /build/tanzu-cluster-essentials /home/eduk8s/tanzu-cluster-essentials

COPY --chown=1001:0 . /home/eduk8s/

USER 1001

ENV TANZU_CLI_NO_INIT=true

RUN mv /home/eduk8s/workshop /opt/workshop

RUN fix-permissions /home/eduk8s

