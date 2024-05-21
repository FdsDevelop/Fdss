#!/bin/bash

/etc/init.d/redis-server start
while true
do
  bundle exec sidekiq
  result=$?
  if [ $result -ne 0 ]; then
    echo "Sidekiq process exited with ${result} status. Restarting..."
    continue
  fi
done
