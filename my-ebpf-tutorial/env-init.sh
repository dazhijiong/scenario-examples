#!/bin/bash
apt-get update
apt-get install -y bpftrace linux-tools-common linux-tools-$(uname -r) git curl
git clone https://github.com/brendangregg/Flamegraph.git
