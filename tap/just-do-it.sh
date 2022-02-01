#!/bin/bash
#
# Execute all of the commands in the lab to set up a 'light'
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
  --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:1.0.0 \
  --namespace tap-install

tanzu package repository get tanzu-tap-repository --namespace tap-install

tanzu package available list --namespace tap-install

cd ~/tap

envsubst < https-tap-values.yaml.template > tap-values.yaml

tanzu package install tap -p tap.tanzu.vmware.com -v 1.0.0 \
  --values-file tap-values.yaml -n tap-install
  
./create-tap-cert.sh

kubectl create secret tls ingress-cert -n tanzu-system-ingress \
  --key ~/tap/$DOMAIN.key --cert ~/tap/$DOMAIN.crt

kubectl create secret tls ingress-cert -n learningcenter \
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
fi

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
kind: Role
metadata:
  name: default
rules:
- apiGroups: [source.toolkit.fluxcd.io]
  resources: [gitrepositories]
  verbs: ['*']
- apiGroups: [source.apps.tanzu.vmware.com]
  resources: [imagerepositories]
  verbs: ['*']
- apiGroups: [carto.run]
  resources: [deliverables, runnables]
  verbs: ['*']
- apiGroups: [kpack.io]
  resources: [images]
  verbs: ['*']
- apiGroups: [conventions.apps.tanzu.vmware.com]
  resources: [podintents]
  verbs: ['*']
- apiGroups: [""]
  resources: ['configmaps']
  verbs: ['*']
- apiGroups: [""]
  resources: ['pods']
  verbs: ['list']
- apiGroups: [tekton.dev]
  resources: [taskruns, pipelineruns]
  verbs: ['*']
- apiGroups: [tekton.dev]
  resources: [pipelines]
  verbs: ['list']
- apiGroups: [kappctrl.k14s.io]
  resources: [apps]
  verbs: ['*']
- apiGroups: [serving.knative.dev]
  resources: ['services']
  verbs: ['*']
- apiGroups: [servicebinding.io]
  resources: ['servicebindings']
  verbs: ['*']
- apiGroups: [services.apps.tanzu.vmware.com]
  resources: ['resourceclaims']
  verbs: ['*']
- apiGroups: [scanning.apps.tanzu.vmware.com]
  resources: ['imagescans', 'sourcescans']
  verbs: ['*']

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: default
subjects:
  - kind: ServiceAccount
    name: default
EOF

tanzu package installed get tap -n tap-install

tanzu package installed list -A
