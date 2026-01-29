#!/bin/bash

# OpenIM Deletion Script
# This script deletes all Kubernetes resources for OpenIM in the reverse order of deployment

set -e  # Exit on any error

echo "Starting OpenIM deletion..."

# Delete OpenIM Application components
echo "Deleting OpenIM application components..."
./application/delete-application.sh

# Delete Infrastructure components
echo "Deleting OpenIM infrastructure components..."
./infrastructure/delete-infrastructure.sh

echo "OpenIM deletion completed successfully!"