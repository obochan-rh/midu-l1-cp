# ETCD Backup

The automated backup functionality for etcd offers support for both recurring and one-time backups. Recurring backups initiate a cron job that triggers a single backup each time the job is executed.

Please note that the automation of etcd backups is currently available as a *Technology Preview* feature in OpenShift Cluster version 4.17. For further details, refer to the [official documentation](https://docs.openshift.com/container-platform/4.17/backup_and_restore/control_plane_backup_and_restore/backing-up-etcd.html#creating-automated-etcd-backups_backup-etcd).

To avoid utilizing the `TechPreviewNoUpgrade` option, the following [etcd-backup](./etcd_backup.yaml) method has been implemented.

Please note that the automation of etcd backup is currently available as a *General Available* feature in OpenShift Cluster version 4.18. For further details, refer to the [official documentation](https://docs.openshift.com/container-platform/4.18/backup_and_restore/control_plane_backup_and_restore/backing-up-etcd.html)

## Table of Content

- [ETCD Backup](#etcd-backup)
  - [Table of Content](#table-of-content)
  - [Method of procedure](#method-of-procedure)



## Method of procedure


Step 1. Create the [etcd-backup.yaml](./etcd_backup.yaml) cronjob:
```bash
[root@INBACRNRDL0102 ~]# oc create -f etcd-backup.yaml 
namespace/ocp-etcd-backup created
serviceaccount/openshift-backup created
clusterrole.rbac.authorization.k8s.io/cluster-etcd-backup created
clusterrolebinding.rbac.authorization.k8s.io/openshift-backup created
securitycontextconstraints.security.openshift.io/openshift-backup-scc created
rolebinding.rbac.authorization.k8s.io/allow-privileged-scc created
cronjob.batch/openshift-backup created
job.batch/backup created
```

Step 2. Validating that the process its running as expected:
```bash
[root@INBACRNRDL0102 ~]# oc get pods -n ocp-etcd-backup 
NAME                                         READY   STATUS              RESTARTS   AGE
backup-dw5cf                                 1/1     Running             0          9s
hub-ctlplane-15g-deploymentlab-debug-cfq5c   0/1     ContainerCreating   0          1s
[root@INBACRNRDL0102 ~]# oc get pods -n ocp-etcd-backup
NAME                                         READY   STATUS    RESTARTS   AGE
backup-dw5cf                                 1/1     Running   0          11s
hub-ctlplane-15g-deploymentlab-debug-cfq5c   1/1     Running   0          3s
[root@INBACRNRDL0102 ~]# oc get pods -n ocp-etcd-backup
NAME                                         READY   STATUS    RESTARTS   AGE
backup-dw5cf                                 1/1     Running   0          12s
hub-ctlplane-15g-deploymentlab-debug-cfq5c   1/1     Running   0          4s
[root@INBACRNRDL0102 ~]# oc get pods -n ocp-etcd-backup
NAME           READY   STATUS      RESTARTS   AGE
backup-dw5cf   0/1     Completed   0          22s
```

Step 3. Checking the `backup` pod logs:
```bash
[root@INBACRNRDL0102 ~]# oc logs -n ocp-etcd-backup backup-dw5cf
Starting pod/hub-ctlplane-05g-deploymentlab-debug-vj76v ...
To use host binaries, run `chroot /host`
Certificate /etc/kubernetes/static-pod-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt is missing. Checking in different directory
Certificate /etc/kubernetes/static-pod-resources/etcd-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt found!
found latest kube-apiserver: /etc/kubernetes/static-pod-resources/kube-apiserver-pod-11
found latest kube-controller-manager: /etc/kubernetes/static-pod-resources/kube-controller-manager-pod-6
found latest kube-scheduler: /etc/kubernetes/static-pod-resources/kube-scheduler-pod-6
found latest etcd: /etc/kubernetes/static-pod-resources/etcd-pod-8
1c90ee165e5df82776a505ca718b9b5180a2d91cccefaa78ecb79bb0e794b2d7
etcdctl version: 3.5.16
API version: 3.5
{"level":"info","ts":"2025-02-20T14:31:53.109019Z","caller":"snapshot/v3_snapshot.go:65","msg":"created temporary db file","path":"/home/core/backup//snapshot_2025-02-20_143152.db.part"}
{"level":"info","ts":"2025-02-20T14:31:53.115308Z","logger":"client","caller":"v3@v3.5.16/maintenance.go:212","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":"2025-02-20T14:31:53.115365Z","caller":"snapshot/v3_snapshot.go:73","msg":"fetching snapshot","endpoint":"https://172.16.30.20:2379"}
{"level":"info","ts":"2025-02-20T14:31:53.956925Z","logger":"client","caller":"v3@v3.5.16/maintenance.go:220","msg":"completed snapshot read; closing"}
Snapshot saved at /home/core/backup//snapshot_2025-02-20_143152.db
{"level":"info","ts":"2025-02-20T14:31:55.067791Z","caller":"snapshot/v3_snapshot.go:88","msg":"fetched snapshot","endpoint":"https://172.16.30.20:2379","size":"195 MB","took":"1 second ago"}
{"level":"info","ts":"2025-02-20T14:31:55.067925Z","caller":"snapshot/v3_snapshot.go:97","msg":"saved","path":"/home/core/backup//snapshot_2025-02-20_143152.db"}
{"hash":1503842097,"revision":1305490,"totalKey":15884,"totalSize":195346432}
snapshot db and kube resources are successfully saved to /home/core/backup/

Removing debug pod ...
Starting pod/hub-ctlplane-15g-deploymentlab-debug-cfq5c ...
To use host binaries, run `chroot /host`
Certificate /etc/kubernetes/static-pod-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt is missing. Checking in different directory
Certificate /etc/kubernetes/static-pod-resources/etcd-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt found!
found latest kube-apiserver: /etc/kubernetes/static-pod-resources/kube-apiserver-pod-11
found latest kube-controller-manager: /etc/kubernetes/static-pod-resources/kube-controller-manager-pod-6
found latest kube-scheduler: /etc/kubernetes/static-pod-resources/kube-scheduler-pod-6
found latest etcd: /etc/kubernetes/static-pod-resources/etcd-pod-8
2c04fcbc6f0c2ddc0d6499891b56c1c050f3499947ffa92cb90bbb360ffcc62e
etcdctl version: 3.5.16
API version: 3.5
{"level":"info","ts":"2025-02-20T14:31:59.077602Z","caller":"snapshot/v3_snapshot.go:65","msg":"created temporary db file","path":"/home/core/backup//snapshot_2025-02-20_143158.db.part"}
{"level":"info","ts":"2025-02-20T14:31:59.083749Z","logger":"client","caller":"v3@v3.5.16/maintenance.go:212","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":"2025-02-20T14:31:59.083796Z","caller":"snapshot/v3_snapshot.go:73","msg":"fetching snapshot","endpoint":"https://172.16.30.21:2379"}
{"level":"info","ts":"2025-02-20T14:31:59.808557Z","logger":"client","caller":"v3@v3.5.16/maintenance.go:220","msg":"completed snapshot read; closing"}
{"level":"info","ts":"2025-02-20T14:32:00.792896Z","caller":"snapshot/v3_snapshot.go:88","msg":"fetched snapshot","endpoint":"https://172.16.30.21:2379","size":"195 MB","took":"1 second ago"}
{"level":"info","ts":"2025-02-20T14:32:00.793146Z","caller":"snapshot/v3_snapshot.go:97","msg":"saved","path":"/home/core/backup//snapshot_2025-02-20_143158.db"}
Snapshot saved at /home/core/backup//snapshot_2025-02-20_143158.db
{"hash":2705481841,"revision":1305578,"totalKey":15974,"totalSize":195399680}
snapshot db and kube resources are successfully saved to /home/core/backup/

Removing debug pod ...
Starting pod/hub-ctlplane-25g-deploymentlab-debug-sj27w ...
To use host binaries, run `chroot /host`
Certificate /etc/kubernetes/static-pod-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt is missing. Checking in different directory
Certificate /etc/kubernetes/static-pod-resources/etcd-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt found!
found latest kube-apiserver: /etc/kubernetes/static-pod-resources/kube-apiserver-pod-11
found latest kube-controller-manager: /etc/kubernetes/static-pod-resources/kube-controller-manager-pod-6
found latest kube-scheduler: /etc/kubernetes/static-pod-resources/kube-scheduler-pod-6
found latest etcd: /etc/kubernetes/static-pod-resources/etcd-pod-8
f529141b0dfd625f1e041eb7dc474324889b5f1c2490e0c83aafaf013f4f780a
etcdctl version: 3.5.16
API version: 3.5
{"level":"info","ts":"2025-02-20T14:32:04.622431Z","caller":"snapshot/v3_snapshot.go:65","msg":"created temporary db file","path":"/home/core/backup//snapshot_2025-02-20_143203.db.part"}
{"level":"info","ts":"2025-02-20T14:32:04.628600Z","logger":"client","caller":"v3@v3.5.16/maintenance.go:212","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":"2025-02-20T14:32:04.628628Z","caller":"snapshot/v3_snapshot.go:73","msg":"fetching snapshot","endpoint":"https://172.16.30.22:2379"}
{"level":"info","ts":"2025-02-20T14:32:05.399751Z","logger":"client","caller":"v3@v3.5.16/maintenance.go:220","msg":"completed snapshot read; closing"}
{"level":"info","ts":"2025-02-20T14:32:06.339990Z","caller":"snapshot/v3_snapshot.go:88","msg":"fetched snapshot","endpoint":"https://172.16.30.22:2379","size":"196 MB","took":"1 second ago"}
{"level":"info","ts":"2025-02-20T14:32:06.340162Z","caller":"snapshot/v3_snapshot.go:97","msg":"saved","path":"/home/core/backup//snapshot_2025-02-20_143203.db"}
Snapshot saved at /home/core/backup//snapshot_2025-02-20_143203.db
{"hash":3805761912,"revision":1305694,"totalKey":16087,"totalSize":195756032}
snapshot db and kube resources are successfully saved to /home/core/backup/

Removing debug pod ...
```

Step 4. Validating that the backup data its available on the master nodes:
```bash
[root@INBACRNRDL0102 ~]# oc get nodes
NAME                               STATUS   ROLES                         AGE   VERSION
hub-ctlplane-0.5g-deployment.lab   Ready    control-plane,master,worker   23h   v1.30.7
hub-ctlplane-1.5g-deployment.lab   Ready    control-plane,master,worker   23h   v1.30.7
hub-ctlplane-2.5g-deployment.lab   Ready    control-plane,master,worker   23h   v1.30.7
[root@INBACRNRDL0102 ~]# oc debug nodes/hub-ctlplane-0.5g-deployment.lab -- chroot /host ls -l /home/core/backup/
Starting pod/hub-ctlplane-05g-deploymentlab-debug-mghf6 ...
To use host binaries, run `chroot /host`
total 190856
-rw-------. 1 root root 195346464 Feb 20 14:31 snapshot_2025-02-20_143152.db
-rw-------. 1 root root     82381 Feb 20 14:31 static_kuberesources_2025-02-20_143152.tar.gz

Removing debug pod ...
```

Step 5. Checking the size of the backup for the example cluster:
```bash
[root@INBACRNRDL0102 ~]# oc debug nodes/hub-ctlplane-0.5g-deployment.lab -- chroot /host ls -lh /home/core/backup/
Starting pod/hub-ctlplane-05g-deploymentlab-debug-2rwcw ...
To use host binaries, run `chroot /host`
total 187M
-rw-------. 1 root root 187M Feb 20 14:31 snapshot_2025-02-20_143152.db
-rw-------. 1 root root  81K Feb 20 14:31 static_kuberesources_2025-02-20_143152.tar.gz

Removing debug pod ...
```