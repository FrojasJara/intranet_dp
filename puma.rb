#!/usr/bin/env puma
environment 'production'

base = '/home/dportales/mnt/sites/dp/current'


directory "#{base}"
pidfile   "#{base}/tmp/pids/puma.pid"
state_path "#{base}/tmp/pids/puma.state"
threads 2, 24

bind "unix://#{base}/tmp/sockets/puma.sock"

workers 4