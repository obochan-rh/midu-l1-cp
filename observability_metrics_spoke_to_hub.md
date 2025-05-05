# Method of Procedure to deploy the Observability Stack

## Procedure
The method of procedure is publicly documented in [Red Hat Advanced Cluster Management Observability](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.11/html-single/observability/index#observability-arch).

### Prerequisites
Once the Hub cluster is available, the following CRs are required:

#### Deploying the Observability Prerequisites
```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"
    workload.openshift.io/allowed: management
  name: open-cluster-management-observability
  labels:
    openshift.io/cluster-monitoring: "true"
    argocd.argoproj.io/managed-by: openshift-gitops
---
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: thanos-s3
  namespace: open-cluster-management-observability
spec:
  generateBucketName: thanos-s3
  storageClassName: openshift-storage.noobaa.io 
```

#### Creating the Thanos Secret and MultiClusterObservability CR
```yaml
---
apiVersion: v1
kind: Secret
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "20"
  name: thanos-object-storage
  namespace: open-cluster-management-observability
type: Opaque
stringData:
  thanos.yaml: |
    type: s3
    config:
      bucket: '{{ fromConfigMap "open-cluster-management-observability" "thanos-s3" "BUCKET_NAME" | toLiteral }}'
      endpoint: s3.openshift-storage.svc
      insecure: false
      access_key: '{{ fromSecret "open-cluster-management-observability" "thanos-s3" "AWS_ACCESS_KEY_ID" | base64dec | toLiteral }}'
      secret_key: '{{ fromSecret "open-cluster-management-observability" "thanos-s3" "AWS_SECRET_ACCESS_KEY" | base64dec | toLiteral }}'
      http_config:
        tls_config:
          ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt"
---
apiVersion: observability.open-cluster-management.io/v1beta2
kind: MultiClusterObservability
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "20"
  name: observability
  namespace: open-cluster-management-observability
spec:
  enableDownsampling: true
  observabilityAddonSpec:
    enableMetrics: true
    interval: 300
  storageConfig:
    alertmanagerStorageSize: 1Gi
    compactStorageSize: 100Gi
    metricObjectStorage:
      key: thanos.yaml
      name: thanos-object-storage
    receiveStorageSize: 100Gi
    ruleStorageSize: 1Gi
    storageClass: ocs-storagecluster-ceph-rbd
    storeStorageSize: 10Gi 
```

### Cluster Labeling Requirement
Beginning with RHACM 2.10, a specific label is required on each managed cluster to enable deployment of the Observability Endpoint Operator. The labels `vendor` and `cloud` must be applied to the ManagedCluster CR to manage the metrics collector deployment effectively.

### SiteConfig CR Example
```yaml
---
apiVersion: ran.openshift.io/v1
kind: SiteConfig
metadata:
  name: "worker1"
  namespace: "worker1"
spec:
  baseDomain: "5g-deployment.lab"
  pullSecretRef:
    name: "disconnected-registry-pull-secret"
  clusterImageSetNameRef: "ocp-417-version"
  sshPublicKey: "ssh-rsa AAAAB3... root@INBACRNRDL0102.workload.bos2.lab"
  clusters:
  - clusterName: "worker1"
    networkType: "OVNKubernetes"
    clusterLabels:
      common: "ocp417"
      logicalGroup: "active"
      group-du-sno: ""
      du-site: "worker1"
      du-zone: "europe"
      cloud: Other
      vendor: OpenShift
```

### Validating Cluster Labels
```sh
$ oc get managedclusters --show-labels
```
Example output:
```sh
worker1  true  https://api.sno1.5g-deployment.lab:6443  True  True  28m  app.kubernetes.io/instance=cluster-deployment,cloud=Other,vendor=OpenShift
```

### Verifying Metrics Collector Deployment
```sh
$ oc get pod -n open-cluster-management-addon-observability
```
Example output:
```sh
NAME                                          READY   STATUS    RESTARTS   AGE
endpoint-observability-operator-xxxxx         1/1     Running   0          45h
metrics-collector-deployment-xxxxx            1/1     Running   0          45h
```

### Accessing Grafana
1. Open the OpenShift Container Platform Console of the hub cluster.
2. Navigate to **All Clusters → Infrastructure → Clusters**.
3. Click on the Grafana link and log in using the same credentials as the OCP Console.

## Dynamic Metrics Collection for SNO and SNOp1 Clusters
Dynamic metrics collection is enabled by default for SNO and SNOp1 clusters to conserve bandwidth and resources. These metrics are only collected when CPU/MEM usage exceeds 70%.

### Default Collection Rules
- **HighCPUUsage**: Activated when CPU usage exceeds 70%.
- **HighMemoryUsage**: Activated when memory utilization exceeds 70%.

### Disabling Collection Rules
To disable dynamic metrics collection:
```yaml
collect_rules:
  - group: -SNOResourceUsage
```

**Note:** Dynamic metrics collection is not applied to Multi Node OpenShift (MNO) clusters.
