#!/bin/bash

echo "Starting server..."

cd /home/ec2-user/app

fuser -k 80/tcp || true

nohup python3 -m http.server 80 > server.log 2>&1 &
