# Quick Fix Guide: msg-rpc-service gRPC Connection Error

## Error Summary
```
grpc service msg-rpc-service down, grpc message connection error: 
desc = "error reading server preface: http2: failed reading the frame payload: %!w(<nil>), 
note that the frame header looked like an HTTP/1.1 header"
```

## Root Cause
This is an **HTTP/2 vs HTTP/1.1 protocol mismatch**. The client is trying to connect using gRPC (HTTP/2) but receiving an HTTP/1.1 response.

## Immediate Actions

### 1. Run the Diagnostic Script
```bash
cd open-im-server/deployments/deploy
./diagnose-grpc-error.sh
```

This will check:
- Pod status
- Service configuration
- Endpoints
- Internal connectivity
- ConfigMap settings
- Network policies

### 2. Quick Manual Checks

#### Check if msg-rpc-server pod is running:
```bash
kubectl get pods -n openim -l app=msg-rpc-server
```

**Expected output:** Pod should be in `Running` state

#### Check service endpoints:
```bash
kubectl get endpoints -n openim msg-rpc-service
```

**Expected output:** Should show pod IP addresses

#### Check pod logs:
```bash
kubectl logs -n openim -l app=msg-rpc-server --tail=50
```

#### Test connectivity from within cluster:
```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n openim -- \
  nc -zv msg-rpc-service 10280
```

## Common Issues and Fixes

### Issue 1: Pod Not Running
**Symptoms:** Pod status is `CrashLoopBackOff`, `Error`, or `Pending`

**Fix:**
```bash
# Check pod events
kubectl describe pod -n openim -l app=msg-rpc-server

# Check logs
kubectl logs -n openim -l app=msg-rpc-server

# Common fixes:
# - Image pull error: Check image registry access
# - ConfigMap missing: Verify openim-config exists
# - Resource limits: Check pod resource requests/limits
```

### Issue 2: Service Has No Endpoints
**Symptoms:** `kubectl get endpoints` shows no addresses

**Fix:**
```bash
# Check pod labels
kubectl get pods -n openim -l app=msg-rpc-server --show-labels

# Check service selector
kubectl get svc -n openim msg-rpc-service -o yaml | grep selector

# Ensure labels match:
# Pod should have: app=msg-rpc-server
# Service selector should be: app: msg-rpc-server
```

### Issue 3: Network Policy Blocking Traffic
**Symptoms:** Connectivity test fails, pod is running

**Fix:**
```bash
# Check network policies
kubectl get networkpolicies -n openim

# If policies exist, ensure they allow traffic between services
# Or temporarily delete them for testing:
kubectl delete networkpolicies -n openim --all
```

### Issue 4: Wrong Service Discovery Configuration
**Symptoms:** Services can't find each other

**Fix:**
```bash
# Check ConfigMap
kubectl get configmap -n openim openim-config -o yaml | grep -A 10 "discovery.yml"

# Ensure it shows:
# enable: "kubernetes"
# kubernetes:
#   namespace: openim
```

### Issue 5: Client Connecting Through Ingress
**Symptoms:** HTTP/1.1 error, client is external

**Fix:**
- **RPC services should NOT be exposed via ingress**
- Use internal service discovery only
- External clients should connect through API service, not directly to RPC services

## Service Port Reference

| Service Name | gRPC Port | Prometheus Port |
|--------------|-----------|-----------------|
| msg-rpc-service | 10280 | 12280 |
| user-rpc-service | 10320 | 12320 |
| friend-rpc-service | 10240 | 12240 |
| group-rpc-service | 10260 | 12260 |
| auth-rpc-service | 10200 | 12200 |
| conversation-rpc-service | 10220 | 12220 |
| push-rpc-service | 10170 | 12170 |
| third-rpc-service | 10300 | 12300 |
| messagegateway-rpc-service | 10140 | 12140 |

## Restart Services

If you need to restart the msg-rpc-service:

```bash
# Restart the deployment
kubectl rollout restart deployment msg-rpc-server -n openim

# Watch the rollout
kubectl rollout status deployment msg-rpc-server -n openim

# Check pod status
kubectl get pods -n openim -l app=msg-rpc-server -w
```

## Verify Fix

After applying fixes, verify:

```bash
# 1. Pod is running
kubectl get pods -n openim -l app=msg-rpc-server

# 2. Service has endpoints
kubectl get endpoints -n openim msg-rpc-service

# 3. Connectivity works
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n openim -- \
  nc -zv msg-rpc-service 10280

# 4. Check logs for errors
kubectl logs -n openim -l app=msg-rpc-server --tail=20
```

## Still Having Issues?

1. Collect all diagnostic information:
```bash
# Save diagnostic output
./diagnose-grpc-error.sh > diagnostic-output.txt 2>&1

# Collect logs
kubectl logs -n openim -l app=msg-rpc-server > msg-rpc-logs.txt
kubectl logs -n openim -l app=openim-api-server > api-logs.txt

# Collect pod descriptions
kubectl describe pod -n openim -l app=msg-rpc-server > msg-rpc-pod-describe.txt
```

2. Review the comprehensive troubleshooting guide:
```
open-im-server/deployments/deploy/TROUBLESHOOTING_GRPC_ERROR.md
```

3. Check the Kubernetes discovery implementation:
```
open-im-server/pkg/common/discovery/kubernetes/kubernetes.go
```

## Architecture Notes

- **RPC services** (msg-rpc, user-rpc, etc.) are internal services
- They use **Kubernetes service discovery** to find each other
- They should **NOT** be exposed via ingress
- Only **API** and **msggateway** services need external ingress
- All inter-service communication uses gRPC over HTTP/2
- Service discovery resolves service names to cluster-internal IPs

## Configuration Files

- Service definition: `open-im-server/deployments/deploy/openim-rpc-msg-service.yml`
- Deployment: `open-im-server/deployments/deploy/openim-rpc-msg-deployment.yml`
- ConfigMap: `open-im-server/deployments/deploy/openim-config.yml`
- Ingress: `open-im-server/deployments/deploy/ingress.yml`
