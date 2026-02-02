# Error Analysis: msg-rpc-service gRPC Connection Error

## Error Details

**Timestamp:** 2026-02-02 10:43:29.305
**Error Code:** 500
**Service:** msg-rpc-service
**Error Message:**
```
grpc service msg-rpc-service down, grpc message connection error: 
desc = "error reading server preface: http2: failed reading the frame payload: %!w(<nil>), 
note that the frame header looked like an HTTP/1.1 header"
```

## What This Error Means

This error indicates a **protocol mismatch** between the client and server:

1. **Client Expectation:** The client is trying to connect using gRPC, which requires HTTP/2 protocol
2. **Server Response:** The server is responding with HTTP/1.1 instead of HTTP/2
3. **Result:** The gRPC client cannot parse the HTTP/1.1 response, causing the connection to fail

## Most Likely Causes (In Order of Probability)

### 1. msg-rpc-server Pod is Not Running or Unhealthy ⭐⭐⭐⭐⭐
**Probability:** Very High

**Why:** If the pod is not running, the service has no endpoints, and connection attempts fail.

**Check:**
```bash
kubectl get pods -n openim -l app=msg-rpc-server
```

**Expected:** Pod should be in `Running` state with `1/1` containers ready

**If Not Running:**
```bash
kubectl describe pod -n openim -l app=msg-rpc-server
kubectl logs -n openim -l app=msg-rpc-server
```

### 2. Service Has No Endpoints ⭐⭐⭐⭐⭐
**Probability:** Very High

**Why:** If the service selector doesn't match pod labels, the service has no endpoints to route traffic to.

**Check:**
```bash
kubectl get endpoints -n openim msg-rpc-service
```

**Expected:** Should show pod IP addresses and port 10280

**If Empty:**
```bash
# Check pod labels
kubectl get pods -n openim -l app=msg-rpc-server --show-labels

# Check service selector
kubectl get svc -n openim msg-rpc-service -o yaml | grep selector
```

**Common Issue:** Pod label is `app=msg-rpc-server` but service selector is different

### 3. Network Policy Blocking Traffic ⭐⭐⭐⭐
**Probability:** High

**Why:** Network policies can block inter-service communication.

**Check:**
```bash
kubectl get networkpolicies -n openim
```

**If Policies Exist:** Review them to ensure they allow traffic between services

### 4. Service Discovery Misconfiguration ⭐⭐⭐
**Probability:** Medium

**Why:** If service discovery is not configured correctly, services can't find each other.

**Check:**
```bash
kubectl get configmap -n openim openim-config -o yaml | grep -A 10 "discovery.yml"
```

**Expected:**
```yaml
discovery.yml: |
  enable: "kubernetes"
  kubernetes:
    namespace: openim
```

### 5. Client Connecting Through Wrong Endpoint ⭐⭐⭐
**Probability:** Medium

**Why:** If the client is connecting through an HTTP ingress instead of directly to the service, it will receive HTTP/1.1 responses.

**Check:** Review client configuration to ensure it's using:
- Service name: `msg-rpc-service`
- Port: `10280` (not `12280`)
- Direct connection (not through ingress)

### 6. Port Mismatch ⭐⭐
**Probability:** Low

**Why:** The client might be connecting to the wrong port.

**Check:** Ensure client is connecting to port `10280` (gRPC port), not `12280` (prometheus port)

## Configuration Analysis

Based on the configuration files reviewed:

### ✅ Correctly Configured:
1. **Service Discovery:** Set to Kubernetes mode in [`openim-config.yml`](openim-config.yml:8)
2. **Service Definition:** [`msg-rpc-service`](openim-rpc-msg-service.yml:4) is correctly defined as ClusterIP
3. **Port Configuration:** gRPC port `10280` is correctly configured
4. **Namespace:** All resources are in the `openim` namespace
5. **Ingress:** Only API and msggateway have ingress (correct for RPC services)

### ⚠️ Potential Issues:
1. **Pod Labels:** Need to verify pod labels match service selector
2. **Pod Status:** Need to verify pod is actually running
3. **Endpoints:** Need to verify service has endpoints
4. **Network Policies:** Need to check if any are blocking traffic

## Diagnostic Steps

### Step 1: Run the Diagnostic Script
```bash
cd open-im-server/deployments/deploy
./diagnose-grpc-error.sh
```

This will perform all the checks automatically and provide a comprehensive report.

### Step 2: Manual Verification

#### Check Pod Status
```bash
kubectl get pods -n openim -l app=msg-rpc-server
```

#### Check Service Endpoints
```bash
kubectl get endpoints -n openim msg-rpc-service
```

#### Check Pod Logs
```bash
kubectl logs -n openim -l app=msg-rpc-server --tail=50
```

#### Test Connectivity
```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n openim -- \
  nc -zv msg-rpc-service 10280
```

## Resolution Path

### If Pod is Not Running:
1. Check pod events: `kubectl describe pod -n openim -l app=msg-rpc-server`
2. Check pod logs: `kubectl logs -n openim -l app=msg-rpc-server`
3. Common fixes:
   - Image pull error: Check image registry access
   - ConfigMap missing: Verify openim-config exists
   - Resource limits: Check pod resource requests/limits
4. Restart deployment: `kubectl rollout restart deployment msg-rpc-server -n openim`

### If Service Has No Endpoints:
1. Verify pod labels: `kubectl get pods -n openim -l app=msg-rpc-server --show-labels`
2. Verify service selector: `kubectl get svc -n openim msg-rpc-service -o yaml | grep selector`
3. Ensure labels match (both should have `app=msg-rpc-server`)
4. If mismatched, update service selector or pod labels

### If Network Policies Block Traffic:
1. Review policies: `kubectl get networkpolicies -n openim -o yaml`
2. Ensure policies allow traffic between services
3. For testing, temporarily delete: `kubectl delete networkpolicies -n openim --all`

### If Service Discovery Misconfigured:
1. Check ConfigMap: `kubectl get configmap -n openim openim-config -o yaml`
2. Verify discovery.yml has correct settings
3. Update ConfigMap if needed: `kubectl edit configmap openim-config -n openim`
4. Restart affected services to pick up new config

## Prevention

To prevent this error in the future:

1. **Monitor Pod Health:** Set up pod health checks and alerts
2. **Monitor Service Endpoints:** Alert when services lose endpoints
3. **Use Readiness Probes:** Ensure pods are ready before receiving traffic
4. **Network Policies:** Document and test network policies thoroughly
5. **Service Discovery:** Verify service discovery configuration during deployment
6. **Regular Health Checks:** Run diagnostic scripts regularly

## Related Files

- **Diagnostic Script:** [`diagnose-grpc-error.sh`](diagnose-grpc-error.sh)
- **Quick Fix Guide:** [`QUICK_FIX_GRPC_ERROR.md`](QUICK_FIX_GRPC_ERROR.md)
- **Comprehensive Troubleshooting:** [`TROUBLESHOOTING_GRPC_ERROR.md`](TROUBLESHOOTING_GRPC_ERROR.md)
- **Service Definition:** [`openim-rpc-msg-service.yml`](openim-rpc-msg-service.yml)
- **Deployment:** [`openim-rpc-msg-deployment.yml`](openim-rpc-msg-deployment.yml)
- **ConfigMap:** [`openim-config.yml`](openim-config.yml)
- **Kubernetes Discovery:** [`../../pkg/common/discovery/kubernetes/kubernetes.go`](../../pkg/common/discovery/kubernetes/kubernetes.go)

## Next Steps

1. **Run the diagnostic script** to identify the specific issue
2. **Apply the appropriate fix** based on the diagnostic results
3. **Verify the fix** by checking pod status, endpoints, and connectivity
4. **Monitor the logs** to ensure the error is resolved
5. **Document the root cause** for future reference

## Support

If the issue persists after trying all solutions:

1. Collect diagnostic output:
   ```bash
   ./diagnose-grpc-error.sh > diagnostic-output.txt 2>&1
   ```

2. Collect logs:
   ```bash
   kubectl logs -n openim -l app=msg-rpc-server > msg-rpc-logs.txt
   kubectl logs -n openim -l app=openim-api-server > api-logs.txt
   ```

3. Review the comprehensive troubleshooting guide in [`TROUBLESHOOTING_GRPC_ERROR.md`](TROUBLESHOOTING_GRPC_ERROR.md)

4. Check the Kubernetes discovery implementation in [`../../pkg/common/discovery/kubernetes/kubernetes.go`](../../pkg/common/discovery/kubernetes/kubernetes.go)
