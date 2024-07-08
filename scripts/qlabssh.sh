#!/bin/bash

QUICK_LAB_HOST=upi-0.claudiolstonesoup.lab.upshift.rdu2.redhat.com

ssh -i ~/.ssh/config/quicklab.key -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -o "IdentitiesOnly yes" quicklab@$QUICK_LAB_HOST
