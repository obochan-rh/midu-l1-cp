# Creating a custom file-based catalog image

| Version | Date       | Author    | Description                           |
|---------|------------|-----------|---------------------------------------|
| 1.0     | 2025-03-20 | Mihai IDU | Initial draft                         |

## Table of Content
- [Creating a custom file-based catalog image](#creating-a-custom-file-based-catalog-image)
  - [Table of Content](#table-of-content)
  - [Prerequisites](#prerequisites)
  - [Scope](#scope)
  - [Generating the Dockerfile](#generating-the-dockerfile)
  - [Ensure to Download the opm binary to the host:](#ensure-to-download-the-opm-binary-to-the-host)
  - [Render the index.yaml file content from redhat-operator-index and certified-operator-index :](#render-the-indexyaml-file-content-from-redhat-operator-index-and-certified-operator-index-)
  - [Creating the working-directory:](#creating-the-working-directory)
  - [Chery pick the subset of operators you want to be included in the custom-operator-index:](#chery-pick-the-subset-of-operators-you-want-to-be-included-in-the-custom-operator-index)
  - [Run the `custom_script.sh` to customize the bundle:](#run-the-custom_scriptsh-to-customize-the-bundle)
  - [Validate what operators have been included in the `custom-operator-index/index.json`](#validate-what-operators-have-been-included-in-the-custom-operator-indexindexjson)
  - [Validate the render:](#validate-the-render)
  - [Once the render its validated we are proceeding the building of the file-based catalog:](#once-the-render-its-validated-we-are-proceeding-the-building-of-the-file-based-catalog)
  - [Push the custom-index to a Registry:](#push-the-custom-index-to-a-registry)
  - [Validate the custom-operator-index content using *oc-mirror cli*:](#validate-the-custom-operator-index-content-using-oc-mirror-cli)
  - [Validating the AirGapped Registry content before](#validating-the-airgapped-registry-content-before)
  - [Imageset-config.yaml file content:](#imageset-configyaml-file-content)
  - [Mirroring result:](#mirroring-result)
  - [Resources:](#resources)

## Prerequisites

- You have installed the [opm CLI](https://mirror.openshift.com/pub/openshift-v4/amd64/clients/ocp/4.17.21/opm-linux-4.17.21.tar.gz).
- You have podman version 1.9.3+.
- A bundle image is built and pushed to a registry that supports Docker v2-2.

## Scope

The scope of this document its to outline the method of procedure of simplifying the maintenance and operability of the `catalogsource` which is merging content from different sources.

## Generating the Dockerfile

```yaml
# The base image is expected to contain /bin/opm
# (with a serve subcommand) and /bin/grpc_health_probe
FROM registry.redhat.io/openshift4/ose-operator-registry-rhel9:v4.17

# Configure the entrypoint and command
ENTRYPOINT ["/bin/opm"]
CMD ["serve", "/configs"]

# Copy declarative config root into image at /configs
ADD custom-operator-index /configs

# Set DC-specific label for the location of the DC root directory
# in the image
LABEL operators.operatorframework.io.index.configs.v1=/configs
```

## Ensure to Download the opm binary to the host: 

```bash
curl -O https://mirror.openshift.com/pub/openshift-v4/amd64/clients/ocp/4.17.21/opm-linux-4.17.21.tar.gz && tar xvf opm-linux-4.17.21.tar.gz
```

 

## Render the index.yaml file content from redhat-operator-index and certified-operator-index :

```bash
$./opm-rhel8 render registry.redhat.io/redhat/redhat-operator-index:v4.17 --output=yaml >> ./index.yaml

$./opm-rhel8 render registry.redhat.io/redhat/certified-operator-index:v4.17 --output=yaml >> ./index.yaml
```

 

## Creating the working-directory:

```bash
mkdir -p catalog/custom-operator-index; cd catalog
```

##  Chery pick the subset of operators you want to be included in the custom-operator-index:

`custom_script.sh`

```bash
#!/bin/bash

# List of package names
packages=(
  'advanced-cluster-management'
  'multicluster-engine'
  'topology-aware-lifecycle-manager'
  'openshift-gitops-operator'
  'odf-operator'
  'ocs-operator'
  'odf-csi-addons-operator'
  'local-storage-operator'
  'mcg-operator'
  'cluster-logging'
  'odf-prometheus-operator'
  'recipe'
  'rook-ceph-operator'
  'sriov-fec'
)

# Ensure the output directory exists
mkdir -p custom-operator-index

# Loop through each package and extract relevant details
for package in "${packages[@]}"; do
    echo "Processing package: $package"

    jq --arg pkg "$package" '. | select((.package==$pkg) or (.name==$pkg))' ../index.json >> custom-operator-index/index.json

    if [[ $? -ne 0 ]]; then
        echo "Error processing package: $package"
    fi
done

echo "Processing complete. Extracted data is saved in custom-operator-index/index.json"
```

## Run the `custom_script.sh` to customize the bundle:

```bash
$ ./custom_script.sh 
Processing package: advanced-cluster-management
Processing package: multicluster-engine
Processing package: topology-aware-lifecycle-manager
Processing package: openshift-gitops-operator
Processing package: odf-operator
Processing package: ocs-operator
Processing package: odf-csi-addons-operator
Processing package: local-storage-operator
Processing package: mcg-operator
Processing package: cluster-logging
Processing package: odf-prometheus-operator
Processing package: recipe
Processing package: rook-ceph-operator
Processing package: sriov-fec
Processing complete. Extracted data is saved in custom-operator-index/index.json
```


## Validate what operators have been included in the `custom-operator-index/index.json`

```bash
$ jq .package custom-operator-index/index.json | jq -s 'unique_by(.)'
[
  null,
  "advanced-cluster-management",
  "cluster-logging",
  "local-storage-operator",
  "mcg-operator",
  "multicluster-engine",
  "ocs-operator",
  "odf-csi-addons-operator",
  "odf-operator",
  "odf-prometheus-operator",
  "openshift-gitops-operator",
  "recipe",
  "rook-ceph-operator",
  "sriov-fec",
  "topology-aware-lifecycle-manager"
]

```

## Validate the render:

```bash
$./opm-rhel8 validate custom-operator-index/; echo $?
0
```

## Once the render its validated we are proceeding the building of the file-based catalog:

```bash
$ podman build . -f redhat-operator-index.Containerfile -t quay.io/midu/custom-operator-index:v4.17
STEP 1/5: FROM registry.redhat.io/openshift4/ose-operator-registry-rhel9:v4.17
Trying to pull registry.redhat.io/openshift4/ose-operator-registry-rhel9:v4.17...
Getting image source signatures
Checking if image destination supports signatures
Copying blob 69153c39b092 done   | 
Copying blob 09e4f579b849 done   | 
Copying blob 25c75c34b2e2 done   | 
Copying blob 3981490bc3c2 done   | 
Copying config 0917ae6bb7 done   | 
Writing manifest to image destination
Storing signatures
STEP 2/5: ENTRYPOINT ["/bin/opm"]
--> 5297ea76f872
STEP 3/5: CMD ["serve", "/configs"]
--> b1041124686f
STEP 4/5: ADD custom-operator-index /configs
--> a947e79112f0
STEP 5/5: LABEL operators.operatorframework.io.index.configs.v1=/configs
COMMIT quay.io/midu/custom-operator-index:v4.17
--> f9b05fc060a7
Successfully tagged quay.io/midu/custom-operator-index:v4.17
f9b05fc060a7bc6ed01d966afde73ebb9c8befe1d34b3d43df5140df35c3a975
```

## Push the custom-index to a Registry:

```bash
podman push quay.io/midu/custom-operator-index:v4.17
Getting image source signatures
Copying blob 3201c3f28948 done   | 
Copying blob 1864636d4ecb done   | 
Copying blob f7f8cfce155a done   | 
Copying blob 1a8c6bfa0a12 done   | 
Copying blob 153e076c7912 done   | 
Copying config f9b05fc060 done   | 
Writing manifest to image destination
```

 

## Validate the custom-operator-index content using *oc-mirror cli*:

```bash
$ oc-mirror list operators --catalog quay.io/midu/custom-operator-index:v4.17
W0320 14:29:51.871405   56418 mirror.go:102] 

⚠️  oc-mirror v1 is deprecated (starting in 4.18 release) and will be removed in a future release - please migrate to oc-mirror --v2

NAME                              DISPLAY NAME  DEFAULT CHANNEL
advanced-cluster-management                     release-2.13
cluster-logging                                 stable-6.2
local-storage-operator                          stable
mcg-operator                                    stable-4.17
multicluster-engine                             stable-2.8
ocs-operator                                    stable-4.17
odf-csi-addons-operator                         stable-4.17
odf-operator                                    stable-4.17
odf-prometheus-operator                         stable-4.17
openshift-gitops-operator                       latest
recipe                                          stable-4.17
rook-ceph-operator                              stable-4.17
sriov-fec                                       stable
topology-aware-lifecycle-manager                stable
```

> [!NOTE] 
> Note, that the MoP has been validated under the OCPv4.17 BUT its version agnostic, same steps can be followed for the OCPv4.{14,16,17,18}

Using the following *imageset-config.yaml* file we are going to proceed mirroring the content of the *custom-operator-index to an AirGapped Registry:*

## Validating the AirGapped Registry content before

```bash
$ curl -X GET -u admin:raspberry https://infra.5g-deployment.lab:8443/v2/_catalog --insecure | jq .
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    20  100    20    0     0    571      0 --:--:-- --:--:-- --:--:--   588
{
  "repositories": []
}
```

## Imageset-config.yaml file content:

imageset-config.yaml
```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 4
mirror:
  operators:
  - catalog: quay.io/midu/custom-operator-index:v4.17
    full: false
    packages:
    - name: 'advanced-cluster-management'
      channels:
      - name: 'release-2.13'
    - name: 'multicluster-engine'
      channels:
      - name: 'stable-2.8'
    - name: 'topology-aware-lifecycle-manager'
      channels:
      - name: 'stable'
    - name: 'openshift-gitops-operator'
      channels:
      - name: 'latest'
    - name: 'odf-operator'
      channels:
      - name: 'stable-4.17'
    - name: 'ocs-operator'
      channels:
      - name: 'stable-4.17'
    - name: 'odf-csi-addons-operator'
      channels:
      - name: 'stable-4.17'
    - name: 'local-storage-operator'
      channels:
      - name: 'stable'
    - name: 'mcg-operator'
      channels:
      - name: 'stable-4.17'
    - name: 'cluster-logging'
      channels:
      - name: 'stable-6.2'
    - name: 'odf-prometheus-operator'
      channels:
      - name: 'stable-4.17'
    - name: 'recipe'
      channels:
      - name: 'stable-4.17'
    - name: 'rook-ceph-operator'
      channels:
      - name: 'stable-4.17'
    - name: 'sriov-fec'
      channels:
      - name: 'stable'
  additionalImages:
  - name: registry.redhat.io/ubi9/ubi:latest
  - name: registry.redhat.io/openshift4/ztp-site-generate-rhel8:v4.16.0
  - name: registry.redhat.io/multicluster-engine/must-gather-rhel9:v2.6
  - name: registry.redhat.io/rhacm2/acm-must-gather-rhel9:v2.11
  - name: registry.redhat.io/openshift-gitops-1/must-gather-rhel8:v1.12.0
  - name: registry.redhat.io/openshift-logging/cluster-logging-rhel9-operator:v5.8.5
  helm: {}
```

> [!NOTE]
> As you can observe at this tage, the mirroring process its using a single operator index to mirror content from two distinct sources `redhat-operator-index` and `certified-operator-index`.

In the next section we are going to outline the AirGapped mirroring result with regards to the CatalogSource, ICSP/IDMS/ITMS CRs.

## Mirroring result:


```bash
$ DOCKER_CONFIG=/root/.docker/; ./oc-mirror --config=./imageset-config.yaml docker://infra.5g-deployment.lab:8443/custom-operator-index

...deprecated..

Rendering catalog image "infra.5g-deployment.lab:8443/custom-operator-index/midu/custom-operator-index:v4.17" with file-based catalog 
Writing image mapping to oc-mirror-workspace/results-1742483435/mapping.txt
Writing CatalogSource manifests to oc-mirror-workspace/results-1742483435
Writing ICSP manifests to oc-mirror-workspace/results-1742483435
deleting directory /tmp/render-unpack-2292595207
```

As a result of the mirroring procedure:

```bash
$ tree oc-mirror-workspace/results-1742483435
oc-mirror-workspace/results-1742483435
├── catalogSource-cs-custom-operator-index.yaml
├── charts
├── imageContentSourcePolicy.yaml
├── mapping.txt
└── release-signatures

2 directories, 3 files
```

The `catalogsource` content:

```bash
[root@inbacrnrdl0100 ~]# cat oc-mirror-workspace/results-1742483435/catalogSource-cs-custom-operator-index.yaml 
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: cs-custom-operator-index
  namespace: openshift-marketplace
spec:
  image: infra.5g-deployment.lab:8443/custom-operator-index/midu/custom-operator-index:v4.17
  sourceType: grpc
  updateStrategy:           # The scope of this section is to allign with the RDS
    registryPoll:           #
        interval: 1h        #
```

The `ImageContentSourcePolicy` content:

```bash
[root@inbacrnrdl0100 ~]# cat oc-mirror-workspace/results-1742483435/imageContentSourcePolicy.yaml 
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: generic-0
spec:
  repositoryDigestMirrors:
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/openshift-gitops-1
    source: registry.redhat.io/openshift-gitops-1
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/openshift4
    source: registry.redhat.io/openshift4
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/openshift-logging
    source: registry.redhat.io/openshift-logging
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/multicluster-engine
    source: registry.redhat.io/multicluster-engine
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/ubi9
    source: registry.redhat.io/ubi9
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/rhacm2
    source: registry.redhat.io/rhacm2
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  labels:
    operators.openshift.org/catalog: "true"
  name: operator-0
spec:
  repositoryDigestMirrors:
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/intel
    source: registry.connect.redhat.com/intel
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/openshift-logging
    source: registry.redhat.io/openshift-logging
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/rhel9
    source: registry.redhat.io/rhel9
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/rhceph
    source: registry.redhat.io/rhceph
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/openshift4
    source: registry.redhat.io/openshift4
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/rhacm2
    source: registry.redhat.io/rhacm2
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/odf4
    source: registry.redhat.io/odf4
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/rh-sso-7
    source: registry.redhat.io/rh-sso-7
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/openshift-gitops-1
    source: registry.redhat.io/openshift-gitops-1
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/rhel8
    source: registry.redhat.io/rhel8
  - mirrors:
    - infra.5g-deployment.lab:8443/custom-operator-index/multicluster-engine
    source: registry.redhat.io/multicluster-engine
```

## Resources: 

- [OlmCreatingFileBaseCatalogImage](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/extensions/catalogs#olm-creating-fb-catalog-image_creating-catalogs) 

