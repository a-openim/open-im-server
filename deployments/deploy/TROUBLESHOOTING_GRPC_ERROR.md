# gRPC Connection Error Troubleshooting Guide

## Error Description

```
ERROR: grpc service group-rpc-service down, grpc message connection error: 
desc = "error reading server preface: http2: failed reading the frame payload: %!w(<nil>), 
note that the frame header looked like an HTTP/1.1 header"
```

## Root Cause Analysis

This error indicates an **HTTP/1.1 vs HTTP/2 protocol mismatch**. The key phrase "the frame header looked like an HTTP/1.1 header" means:

- **Client**: Trying to connect using gRPC (which requires HTTP/2)
- **Server**: Responding with HTTP/1.1 instead of HTTP/2

This typically occurs when:
1. gRPC traffic is being proxied through an HTTP/1.1 endpoint (like a web server or improperly configured ingress)
2. The client is connecting to the wrong port or service
3. Service discovery is returning an incorrect address
4. Network infrastructure is downgrading the protocol

## Common Scenarios and Solutions

### Scenario 1: Client Connecting Through Ingress (Most Common)

**Problem**: The client is trying to connect to `group-rpc-service` through an HTTP ingress that doesn't support gRPC.

**Current Setup**:
- RPC services are exposed as `ClusterIP` services (internal only)
- Only API and msggateway have ingress configurations
- Ingress is configured for HTTP/1.1, not gRPC

**Solution 1: Use Internal Service Discovery (Recommended for Kubernetes)**

Ensure your client is running within the Kubernetes cluster and uses service discovery:

```yaml
# In openim-config.yml, discovery.yml should be:
discovery.yml: |
  enable: "kubernetes"
  kubernetes:
    namespace: openim
```

The client should connect using the service name directly:
```
group-rpc-service.openim.svc.cluster.local:10260
```

**Solution 2: Expose RPC Services via gRPC Ingress (If External Access Required)**

Create a gRPC-enabled ingress for RPC services:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: openim-rpc-ingress
  namespace: openim
  annotations:
    kubernetes.io/ingress.class: "nginx"
    # Enable gRPC support
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
    nginx.ingress.kubernetes.io/grpc-backend: "true"
spec:
  ingressClassName: nginx
  rules:
    - host: rpc-openim.36x9.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: group-rpc-service
                port:
                  number: 10260
```

**Important**: For gRPC over ingress, you must:
1. Use TLS (HTTPS) - gRPC requires HTTP/2, which requires TLS in most browsers
2. Configure the ingress controller to support gRPC
3. Ensure the client uses the correct host header

### Scenario 2: Service Discovery Issues

**Problem**: Service discovery is returning an incorrect address or the service is not registered.

**Diagnostic Steps**:

1. Check if the service is running:
```bash
kubectl get pods -n openim -l app=group-rpc-server
kubectl get svc -n openim group-rpc-service
```

2. Check service endpoints:
```bash
kubectl get endpoints -n openim group-rpc-service
```

3. Check service logs:
```bash
kubectl logs -n openim -l app=group-rpc-server --tail=100
```

4. Test connectivity from within the cluster:
```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n openim -- \
  curl -v http://group-rpc-service:10260
```

**Solution**: Ensure the service is properly registered and healthy.

### Scenario 3: Port Mismatch

**Problem**: Client is connecting to the wrong port.

**Check**: Verify the client is connecting to port `10260` (not the prometheus port `12260`).

**RPC Service Ports Reference**:
| Service Name | gRPC Port | Prometheus Port |
|--------------|-----------|-----------------|
| user-rpc-service | 10320 | 12320 |
| friend-rpc-service | 10240 | 12240 |
| msg-rpc-service | 10280 | 12280 |
| push-rpc-service | 10170 | 12170 |
| group-rpc-service | 10260 | 12260 |
| auth-rpc-service | 10200 | 12200 |
| conversation-rpc-service | 10220 | 12220 |
| third-rpc-service | 10300 | 12300 |
| messagegateway-rpc-service | 10140 | 12140 |

### Scenario 4: Network Policy or Firewall Issues

**Problem**: Network policies or firewalls are blocking gRPC traffic.

**Diagnostic Steps**:

1. Check network policies:
```bash
kubectl get networkpolicies -n openim
```

2. Test connectivity:
```bash
# From a pod in the same namespace
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n openim -- \
  nc -zv group-rpc-service 10260
```

**Solution**: Ensure network policies allow traffic between services.

## Step-by-Step Troubleshooting

### Step 1: Verify Service Status

```bash
# Check if the group-rpc pod is running
kubectl get pods -n openim -l app=group-rpc-server

# Expected output: group-rpc-server-xxxxx  1/1  Running  ...
```

If not running:
```bash
kubectl describe pod -n openim -l app=group-rpc-server
kubectl logs -n openim -l app=group-rpc-server
```

### Step 2: Verify Service Configuration

```bash
# Check service definition
kubectl get svc -n openim group-rpc-service -o yaml

# Verify endpoints
kubectl get endpoints -n openim group-rpc-service

# Expected: Should show the pod IP and port 10260
```

### Step 3: Test Internal Connectivity

```bash
# Test from within the cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n openim -- \
  curl -v http://group-rpc-service:10260

# Or use netcat
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n openim -- \
  nc -zv group-rpc-service 10260
```

Expected result: Connection successful (even if HTTP/1.1 response, the connection should work)

### Step 4: Check Client Configuration

Verify the client is configured correctly:

1. **Discovery Method**: Should be using Kubernetes service discovery
2. **Service Name**: Should be `group-rpc-service` (not a URL)
3. **Namespace**: Should be `openim`
4. **Port**: Should be `10260` (not `12260`)

### Step 5: Check Ingress Configuration (If Using External Access)

If you need external access to RPC services:

1. Verify ingress controller supports gRPC:
```bash
kubectl get pods -n ingress-nginx
```

2. Check ingress annotations include gRPC support:
```yaml
annotations:
  nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
  nginx.ingress.kubernetes.io/grpc-backend: "true"
```

3. Ensure TLS is configured (required for gRPC over HTTP/2 in most cases)

### Step 6: Review Logs

```bash
# Check group-rpc service logs
kubectl logs -n openim -l app=group-rpc-server --tail=100 -f

# Check API service logs (if the error is from API trying to connect to RPC)
kubectl logs -n openim -l app=openim-api-server --tail=100 -f

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=100
```

## Configuration Recommendations

### For Kubernetes Deployment (Recommended)

1. **Use Kubernetes Service Discovery**:
```yaml
# openim-config.yml
discovery.yml: |
  enable: "kubernetes"
  kubernetes:
    namespace: openim
```

2. **Keep RPC Services Internal**:
   - RPC services should remain `ClusterIP` type
   - Only API and msggateway need external ingress
   - Services communicate internally using service names

3. **Ensure Proper Service Registration**:
```yaml
# Each RPC service should have:
spec:
  selector:
    app: <service-name>-server  # Must match pod labels
  ports:
    - name: http-<port>
      protocol: TCP
      port: <port>
      targetPort: <port>
```

### For External Client Access

If you need external clients to access RPC services:

**Option A: API Gateway Pattern (Recommended)**
- Route all external traffic through the API service
- API service handles internal RPC communication
- No direct external access to RPC services

**Option B: gRPC Ingress with TLS**
- Create separate gRPC ingress for each RPC service
- Configure TLS certificates
- Use proper gRPC client configuration

Example gRPC ingress:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: openim-grpc-ingress
  namespace: openim
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
    nginx.ingress.kubernetes.io/grpc-backend: "true"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - rpc-openim.36x9.com
      secretName: openim-grpc-tls
  rules:
    - host: rpc-openim.36x9.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: group-rpc-service
                port:
                  number: 10260
```

## Common Mistakes to Avoid

1. ❌ **Connecting RPC services through HTTP ingress**
   - HTTP ingress uses HTTP/1.1, gRPC requires HTTP/2
   - Use service discovery instead

2. ❌ **Using wrong port**
   - Connecting to prometheus port instead of gRPC port
   - Verify port numbers in configuration

3. ❌ **Missing service labels**
   - Service selector doesn't match pod labels
   - Results in no endpoints

4. ❌ **Incorrect namespace**
   - Client looking for service in wrong namespace
   - Ensure namespace matches in discovery config

5. ❌ **Firewall blocking gRPC**
   - Network policies blocking inter-service communication
   - Allow traffic between services

## Verification Checklist

- [ ] All RPC pods are running and healthy
- [ ] Services have correct endpoints
- [ ] Service discovery is configured for Kubernetes
- [ ] Client is using correct service name and port
- [ ] Network policies allow inter-service traffic
- [ ] No port conflicts between services
- [ ] Logs show successful service registration
- [ ] Internal connectivity test passes

## Additional Resources

- [gRPC over HTTP/2](https://grpc.github.io/grpc/core/md_doc_grpc_http2_protocol.html)
- [NGINX Ingress Controller gRPC](https://kubernetes.github.io/ingress-nginx/examples/grpc/)
- [Kubernetes Service Discovery](https://kubernetes.io/docs/concepts/services-networking/service/)

## Quick Reference: RPC Service Ports

| Service Name | Port | Prometheus Port |
|--------------|------|-----------------|
| user-rpc-service | 10320 | 12320 |
| friend-rpc-service | 10240 | 12240 |
| msg-rpc-service | 10280 | 12280 |
| push-rpc-service | 10170 | 12170 |
| group-rpc-service | 10260 | 12260 |
| auth-rpc-service | 10200 | 12200 |
| conversation-rpc-service | 10220 | 12220 |
| third-rpc-service | 10300 | 12300 |
| messagegateway-rpc-service | 10140 | 12140 |

## Contact Support

If the issue persists after trying these solutions:
1. Collect logs from all affected services
2. Document your network topology
3. Include your ingress and service configurations
4. Provide client connection details
