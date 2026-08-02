# Kubernetes: nginx on the lab node

A one-replica nginx Deployment plus a NodePort Service, aimed at the `hedronite-devops-lab` k3s node. Small enough to read in one sitting, real enough to exercise the full apply-verify-teardown loop.

On the host, make the lab context the current one:

```bash
kubectl config use-context hedronite-devops-lab
```

The container mounts `~/.kube` read-only, so context switching happens host-side. Inside the lab, apply:

```bash
cd /workspace/hedronite-devops-lab/labs-examples/k8s
kubectl apply -f .
```

Verify:

```bash
kubectl get pods -l app=lab-nginx
kubectl get svc lab-nginx
curl http://<node-ip>:30080
```

The curl runs from any machine that can reach the node; port 30080 is the NodePort pinned in `service.yaml`.

Teardown:

```bash
kubectl delete -f .
```

If the pod sits in `Pending`, describe it. `kubectl describe pod` names the reason in the Events block, and reading that block is the habit this lab exists to build.
