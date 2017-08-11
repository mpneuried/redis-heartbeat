#!/bin/sh
echo "START TEST..."
redis-server &
npm run test-docker