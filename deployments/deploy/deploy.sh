#!/bin/bash

# OpenIM Kubernetes Deployment Script
# This script applies all Kubernetes resources for OpenIM in the correct order

set -e  # Exit on any error

echo "Starting OpenIM deployment..."

# Apply Infrastructure components
echo "Applying OpenIM infrastructure components..."
./infrastructure/deploy-infrastructure.sh

# Apply OpenIM Application components
echo "Applying OpenIM application components..."
./application/deploy-application.sh

echo "OpenIM deployment completed successfully!"