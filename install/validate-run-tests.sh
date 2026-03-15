#!/bin/bash
sf project deploy validate \
  --source-dir "/Users/seiloosh/Documents/GitHub/eventManagementSystem/force-app" \
  --test-level RunSpecifiedTests \
  --tests Contact_SetNomadOnSystemFirstName_Tests \
  --target-org "$1" \
  --verbose