#!/bin/bash

# OpenIM Application Deletion Script
# This script deletes all Kubernetes resources for OpenIM application components

set -e  # Exit on any error

echo "Starting OpenIM application deletion..."

# Delete OpenIM Deployments first
echo "Deleting OpenIM deployments..."
kubectl delete -f openim-api-deployment.yml
kubectl delete -f openim-crontask-deployment.yml
kubectl delete -f openim-msggateway-deployment.yml
kubectl delete -f openim-msgtransfer-deployment.yml
kubectl delete -f openim-push-deployment.yml
kubectl delete -f openim-rpc-auth-deployment.yml
kubectl delete -f openim-rpc-conversation-deployment.yml
kubectl delete -f openim-rpc-friend-deployment.yml
kubectl delete -f openim-rpc-group-deployment.yml
kubectl delete -f openim-rpc-msg-deployment.yml
kubectl delete -f openim-rpc-third-deployment.yml
kubectl delete -f openim-rpc-user-deployment.yml

# Delete OpenIM Services
echo "Deleting OpenIM services..."
kubectl delete -f openim-api-service.yml
kubectl delete -f openim-msggateway-service.yml
kubectl delete -f openim-msgtransfer-service.yml
kubectl delete -f openim-push-service.yml
kubectl delete -f openim-rpc-auth-service.yml
kubectl delete -f openim-rpc-conversation-service.yml
kubectl delete -f openim-rpc-friend-service.yml
kubectl delete -f openim-rpc-group-service.yml
kubectl delete -f openim-rpc-msg-service.yml
kubectl delete -f openim-rpc-third-service.yml
kubectl delete -f openim-rpc-user-service.yml

echo "OpenIM application deletion completed successfully!"