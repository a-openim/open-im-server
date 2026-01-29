#!/bin/bash

# OpenIM Application Deployment Script
# This script applies Kubernetes resources for OpenIM application components

set -e  # Exit on any error

echo "Starting OpenIM application deployment..."

# Apply OpenIM Services
echo "Applying OpenIM services..."
kubectl apply -f openim-api-service.yml
kubectl apply -f openim-msggateway-service.yml
kubectl apply -f openim-msgtransfer-service.yml
kubectl apply -f openim-push-service.yml
kubectl apply -f openim-rpc-auth-service.yml
kubectl apply -f openim-rpc-conversation-service.yml
kubectl apply -f openim-rpc-friend-service.yml
kubectl apply -f openim-rpc-group-service.yml
kubectl apply -f openim-rpc-msg-service.yml
kubectl apply -f openim-rpc-third-service.yml
kubectl apply -f openim-rpc-user-service.yml

# Apply OpenIM Deployments
echo "Applying OpenIM deployments..."
kubectl apply -f openim-api-deployment.yml
kubectl apply -f openim-crontask-deployment.yml
kubectl apply -f openim-msggateway-deployment.yml
kubectl apply -f openim-msgtransfer-deployment.yml
kubectl apply -f openim-push-deployment.yml
kubectl apply -f openim-rpc-auth-deployment.yml
kubectl apply -f openim-rpc-conversation-deployment.yml
kubectl apply -f openim-rpc-friend-deployment.yml
kubectl apply -f openim-rpc-group-deployment.yml
kubectl apply -f openim-rpc-msg-deployment.yml
kubectl apply -f openim-rpc-third-deployment.yml
kubectl apply -f openim-rpc-user-deployment.yml

echo "OpenIM application deployment completed successfully!"