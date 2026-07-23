COMMANDS

```
gcloud container clusters get-credentials game-cluster-lab --zone europe-west1-b --project devops-cert-labs-v3

kubectl get statefulset web-server
kubectl get pods -l app=web-server -o wide

kubectl get statefulset web-server -o jsonpath='{.spec.updateStrategy.rollingUpdate.partition}'

kubectl set image statefulset/web-server web-server=nginx:1.26

kubectl rollout status statefulset/web-server
kubectl get pods -l app=web-server -o jsonpath='{range .items[*]}{.metadata.name}{"`t"}{.spec.containers[0].image}{"`n"}{end}'

kubectl get pods -l app=web-server -L controller-revision-hash

kubectl patch statefulset web-server -p '{\"spec\":{\"updateStrategy\":{\"rollingUpdate\":{\"partition\":0}}}}'

kubectl get pods -l app=web-server -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image
#ALL NGINX TRANSICITIONATED IN PARTS TO THE NEW VERSION
<!-- NAME           IMAGE
web-server-0   nginx:1.26
web-server-1   nginx:1.26
web-server-2   nginx:1.26
web-server-3   nginx:1.26 -->
```

# GKE Partitioned Rolling Update Lab (Q72)

## 1. The Exam Question

You are ready to deploy a new feature of a web-based application to production. You want to use Google Kubernetes Engine (GKE) to perform a phased rollout to half of the web server pods. What should you do?

- A. Use a partitioned rolling update.
- B. Use Node taints with NoExecute.
- C. Use a replica set in the deployment specification.
- D. Use a stateful set with parallel pod management policy.

**Correct answer: A - Use a partitioned rolling update.**

### Why A is correct

A partitioned rolling update is a feature of Kubernetes `StatefulSet` objects. In the `updateStrategy`, you can set `rollingUpdate.partition` to a number. Kubernetes will only update the pods whose ordinal index is greater than or equal to that number. Pods with a lower ordinal index stay on the old version.

This lets you release a new version to only part of your pods first, check that everything works, and then finish the rollout by lowering the partition value. This matches the scenario in the question: a phased rollout to half of the pods.

### Why the other options are wrong

- **B (Node taints with NoExecute)**: taints control which pods can be scheduled on a node, and `NoExecute` can evict running pods from a node. This has nothing to do with rolling out application versions in phases.
- **C (Replica set in the deployment)**: a plain `Deployment`/`ReplicaSet` rolling update replaces all pods over time, but you cannot pin exactly half of them to stay on the old version in a controlled, deliberate way the same way a partition does.
- **D (StatefulSet with parallel pod management policy)**: `podManagementPolicy: Parallel` only changes how pods are created or deleted (in parallel instead of one by one). It does not control which version of the pod template gets applied to which pods.

## 2. Architecture

```
                     +-------------------------------+
                     |   GCP Project                 |
                     |   devops-cert-labs-v3          |
                     +---------------+----------------+
                                     |
                     +---------------v----------------+
                     |   VPC Network                   |
                     |   gke-lab-network                |
                     +---------------+----------------+
                                     |
                     +---------------v----------------+
                     |   Subnet (europe-west1)         |
                     |   gke-lab-subnet                 |
                     |   10.10.0.0/24                   |
                     +---------------+----------------+
                                     |
                     +---------------v----------------+
                     |   GKE Cluster                    |
                     |   game-cluster-lab                |
                     |   zone: europe-west1-b            |
                     |                                   |
                     |   +---------------------------+   |
                     |   | Node Pool: primary-pool   |   |
                     |   | 1 node (e2-medium)        |   |
                     |   |                           |   |
                     |   |  +---------------------+  |   |
                     |   |  | StatefulSet          |  |   |
                     |   |  | web-server           |  |   |
                     |   |  | replicas: 4           |  |   |
                     |   |  | partition: 2          |  |   |
                     |   |  |                       |  |   |
                     |   |  | [web-server-0] old    |  |   |
                     |   |  | [web-server-1] old    |  |   |
                     |   |  | [web-server-2] NEW    |  |   |
                     |   |  | [web-server-3] NEW    |  |   |
                     |   |  +---------------------+  |   |
                     |   +---------------------------+   |
                     +-----------------------------------+
```

The dotted idea here: pods with ordinal 0 and 1 stay on the old image, pods with ordinal 2 and 3 (>= partition) move to the new image. That is the "half rollout" the exam question is about.

## 3. Explanation of main.tf

The Terraform file creates the smallest possible setup to demonstrate this behavior:

- **Providers**: `google` (to create GCP resources) and `kubernetes` (to create the StatefulSet directly inside the cluster once it exists).
- **APIs enabled**: only `container.googleapis.com`, `compute.googleapis.com`, and `serviceusage.googleapis.com`, the minimum needed for GKE.
- **Network and subnet**: one custom VPC (`gke-lab-network`) and one subnet (`gke-lab-subnet`) in `europe-west1`. A custom VPC is required because GKE needs an explicit subnet when `auto_create_subnetworks` is false.
- **GKE cluster (`google_container_cluster.lab`)**: a single cluster, `deletion_protection = false` so it can be destroyed easily, and `remove_default_node_pool = true` so we control the node pool ourselves instead of using the default one.
- **Node pool (`google_container_node_pool.lab_nodes`)**: exactly 1 node, `e2-medium` machine type. This is intentionally minimal to keep lab costs low.
- **Kubernetes provider block**: authenticates against the cluster using the access token from `google_client_config` and the cluster's CA certificate, so Terraform can talk to the Kubernetes API right after the cluster is created.
- **StatefulSet (`kubernetes_stateful_set.web_server`)**: this is the core of the lab.
  - `replicas = 4`
  - `update_strategy.type = "RollingUpdate"`
  - `update_strategy.rolling_update.partition = 2`
  - `image = "nginx:1.25"` (a public image from Docker Hub, not tied to any private repository)
  - `wait_for_rollout = false` so Terraform does not hang waiting for a rollout to finish (useful since we control rollouts manually with kubectl afterward)
- **Outputs**: cluster name, cluster endpoint, and the current partition value, so you can quickly confirm the state after `terraform apply`.

## 4. Verification Procedure (PowerShell)

After running `terraform apply`, follow these steps to reproduce and verify the partitioned rollout.

**Step 1: Connect kubectl to the cluster**
```powershell
gcloud container clusters get-credentials game-cluster-lab --zone europe-west1-b --project devops-cert-labs-v3
```

**Step 2: Check the StatefulSet and its pods**
```powershell
kubectl get statefulset web-server
kubectl get pods -l app=web-server -o wide
```

**Step 3: Confirm the current partition value**
```powershell
kubectl get statefulset web-server -o jsonpath='{.spec.updateStrategy.rollingUpdate.partition}'
```
Expected output: `2`

**Step 4: Trigger a new version (simulate a feature deployment)**
```powershell
kubectl set image statefulset/web-server web-server=nginx:1.26
```

**Step 5: Watch the rollout — only half the pods should update**
```powershell
kubectl rollout status statefulset/web-server
kubectl get pods -l app=web-server -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image
```
Expected: `web-server-2` and `web-server-3` move to `nginx:1.26`, while `web-server-0` and `web-server-1` stay on `nginx:1.25`.

**Step 6: Confirm with the revision hash**
```powershell
kubectl get pods -l app=web-server -L controller-revision-hash
```
Pods 0 and 1 will show a different `CONTROLLER-REVISION-HASH` value than pods 2 and 3.

**Step 7: Finish the rollout for the remaining pods**
```powershell
kubectl patch statefulset web-server -p '{\"spec\":{\"updateStrategy\":{\"rollingUpdate\":{\"partition\":0}}}}'
```

**Step 8: Confirm all pods are now on the new image**
```powershell
kubectl get pods -l app=web-server -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image
```
Expected: all 4 pods show `nginx:1.26`.

## 5. Cleanup

To remove only the StatefulSet, without touching the cluster or the rest of the infrastructure:

```powershell
gcloud container clusters get-credentials game-cluster-lab --zone europe-west1-b --project devops-cert-labs-v3

kubectl delete statefulset web-server
```

If some pods remain stuck, force delete them:

```powershell
kubectl get pods -l app=web-server
kubectl delete pods -l app=web-server --force --grace-period=0
```

To remove everything created by Terraform (network, subnet, cluster, node pool, StatefulSet):

```powershell
terraform destroy -auto-approve
```