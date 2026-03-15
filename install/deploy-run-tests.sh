#!/bin/bash
# Usage: ./install/deploy-run-tests.sh <target-org>
# Example: ./install/deploy-run-tests.sh personal

echo "🚀 Starting deployment to org: $1"

sf project deploy start \
  --source-dir "/Users/seiloosh/Documents/GitHub/eventManagementSystem/force-app" \
  --test-level RunSpecifiedTests \
  --tests Contact_SetNomadOnSystemFirstName_Tests \
  --target-org "$1" \
  --verbose

if [ $? -eq 0 ]; then
  echo "✅ Deployment completed successfully!"
else
  echo "❌ Deployment failed. Check the logs above."
fi
