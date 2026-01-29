#!/bin/bash

# OpenIM Application Deployment Script
# This script applies Kubernetes resources for OpenIM application components

NAMESPACE="openim"

set -e  # Exit on any error

echo "Starting OpenIM application deployment..."

# Applying Infrastructure components
echo "Applying configmap..."
kubectl apply -f openim-config.yml -n $NAMESPACE

# Apply OpenIM Services
echo "Applying OpenIM services..."
kubectl apply -f openim-api-service.yml -n $NAMESPACE
kubectl apply -f openim-msggateway-service.yml -n $NAMESPACE
kubectl apply -f openim-msgtransfer-service.yml -n $NAMESPACE
kubectl apply -f openim-push-service.yml -n $NAMESPACE
kubectl apply -f openim-rpc-auth-service.yml -n $NAMESPACE
kubectl apply -f openim-rpc-conversation-service.yml -n $NAMESPACE
kubectl apply -f openim-rpc-friend-service.yml -n $NAMESPACE
kubectl apply -f openim-rpc-group-service.yml -n $NAMESPACE
kubectl apply -f openim-rpc-msg-service.yml -n $NAMESPACE
kubectl apply -f openim-rpc-third-service.yml -n $NAMESPACE
kubectl apply -f openim-rpc-user-service.yml -n $NAMESPACE

# Apply OpenIM Deployments
echo "Applying OpenIM deployments..."
kubectl apply -f openim-api-deployment.yml -n $NAMESPACE
kubectl apply -f openim-crontask-deployment.yml -n $NAMESPACE
kubectl apply -f openim-msggateway-deployment.yml -n $NAMESPACE
kubectl apply -f openim-msgtransfer-deployment.yml -n $NAMESPACE
kubectl apply -f openim-push-deployment.yml -n $NAMESPACE
kubectl apply -f openim-rpc-auth-deployment.yml -n $NAMESPACE
kubectl apply -f openim-rpc-conversation-deployment.yml -n $NAMESPACE
kubectl apply -f openim-rpc-friend-deployment.yml -n $NAMESPACE
kubectl apply -f openim-rpc-group-deployment.yml -n $NAMESPACE
kubectl apply -f openim-rpc-msg-deployment.yml -n $NAMESPACE
kubectl apply -f openim-rpc-third-deployment.yml -n $NAMESPACE
kubectl apply -f openim-rpc-user-deployment.yml -n $NAMESPACE

# Apply Ingress
echo "Applying ingress..."
kubectl apply -f ingress.yml -n $NAMESPACE

echo "OpenIM application deployment completed successfully!"