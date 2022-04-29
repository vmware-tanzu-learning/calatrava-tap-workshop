#!/bin/bash
#
# Execute all of the commands in the lab to set up a 'full'
# TAP install, secured with self-signed certificates.

source ~/tap/environment.sh

if [[ "${TANZUNET_USERNAME}" == "" || "${TANZUNET_USERNAME}" == "<replace-this>" ]]
then
  echo "Please edit the 'environment.sh' file before running this script"
  exit 1
fi

set -x
set -e

export KUBECONFIG=~/terraform/gc.kubeconfig

kubectl create clusterrolebinding \
	default-tkg-admin-privileged-binding \
	--clusterrole=psp:vmware-system-privileged \
	--group=system:authenticated 2> /dev/null || true

cd ~/tanzu-cluster-essentials
./install.sh

kubectl create ns tap-install

tanzu secret registry add tap-registry \
  --username "${INSTALL_REGISTRY_USERNAME}" \
  --password "${INSTALL_REGISTRY_PASSWORD}" \
  --server "${INSTALL_REGISTRY_HOSTNAME}" \
  --export-to-all-namespaces --yes --namespace tap-install

tanzu package repository add tanzu-tap-repository \
  --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:$TAP_VERSION \
  --namespace tap-install

tanzu package repository get tanzu-tap-repository --namespace tap-install

tanzu package available list --namespace tap-install

cd ~/tap

envsubst < https-tap-values.yaml.template > tap-values.yaml

tanzu package install tap -p tap.tanzu.vmware.com -v $TAP_VERSION \
  --values-file tap-values.yaml -n tap-install

./create-tap-cert.sh

kubectl create secret tls ingress-cert -n tanzu-system-ingress \
  --key ~/tap/$DOMAIN.key --cert ~/tap/$DOMAIN.crt

kubectl apply -f - <<EOF
apiVersion: projectcontour.io/v1
kind: TLSCertificateDelegation
metadata:
  name: contour-delegation
  namespace: tanzu-system-ingress
spec:
  delegations:
    - secretName: ingress-cert
      targetNamespaces:
        - "*"
EOF

if [[ "${REGISTRY_SERVER}" == "index.docker.io" ]]
then
  tanzu secret registry add registry-credentials \
  --server "https://index.docker.io/v1/" \
  --username "${REGISTRY_USERNAME}" \
  --password "${REGISTRY_PASSWORD}" \
  --namespace default
else
  tanzu secret registry add registry-credentials \
    --server "${REGISTRY_SERVER}" \
    --username "${REGISTRY_USERNAME}" \
    --password "${REGISTRY_PASSWORD}" \
    --namespace default
fi

cat <<EOF | kubectl -n default apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: tap-registry
  annotations:
    secretgen.carvel.dev/image-pull-secret: ""
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: e30K
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
secrets:
  - name: registry-credentials
imagePullSecrets:
  - name: registry-credentials
  - name: tap-registry
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default-permit-deliverable
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: deliverable
subjects:
  - kind: ServiceAccount
    name: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default-permit-workload
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: workload
subjects:
  - kind: ServiceAccount
    name: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
name: dev-permit-app-viewer
roleRef:
apiGroup: rbac.authorization.k8s.io
kind: ClusterRole
name: app-viewer
subjects:
- kind: Group
  name: "namespace-developers"
  apiGroup: rbac.authorization.k8s.io
--
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
name: namespace-dev-permit-app-viewer
roleRef:
apiGroup: rbac.authorization.k8s.io
kind: ClusterRole
name: app-viewer-cluster-access
subjects:
- kind: Group
  name: "namespace-developers"
  apiGroup: rbac.authorization.k8s.io
EOF

# Create secret for Learning Center

kubectl create secret tls ingress-cert -n learningcenter \
  --key ~/tap/$DOMAIN.key --cert ~/tap/$DOMAIN.crt

tanzu package installed get tap -n tap-install

tanzu package installed list -A

cat <<EOF

=== Installation Complete ===

It may take a while for packages to finish reconciling, check with

  tanzu package installed list -A

Enjoy your TAP installation!
EOF