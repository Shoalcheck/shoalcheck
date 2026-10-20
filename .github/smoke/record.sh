#!/usr/bin/env bash
# Re-record the answers release-smoke replays on macOS and Windows, with the binary of the release being smoked:
#   .github/smoke/record.sh ./shoalcheck
# Needs docker, kind, kubectl and python3. Builds the "smoke" cluster the Linux job builds, in a kubeconfig of its
# own (never yours), records every answer the binary reads for the commands the job runs, then deletes the cluster.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
bin="$(cd "$(dirname "${1:?usage: record.sh <path to shoalcheck>}")" && pwd)/$(basename "$1")"
work="$(mktemp -d)"
export KUBECONFIG="$work/kind.kubeconfig"
printf '%s\n' 'kind: Cluster' 'apiVersion: kind.x-k8s.io/v1alpha4' 'nodes:' \
  '  - role: control-plane' '  - role: worker' '  - role: worker' > "$work/kind.yaml"
kind create cluster --name smoke --config "$work/kind.yaml"
trap 'kill $(jobs -p) 2>/dev/null; kind delete cluster --name smoke; rm -rf "$work"' EXIT
"$here/fixture.sh"
kubectl proxy --port=8001 > "$work/proxy.log" 2>&1 &
rm -f "$here/recording.json"
python3 "$here/apiserver.py" record http://127.0.0.1:8001 "$here/recording.json" > "$work/record.log" 2>&1 &
for i in $(seq 1 40); do curl -fs http://127.0.0.1:18080/version > /dev/null && break; sleep 0.25; done
# The commands the jobs run, as the jobs run them: no licence, a state directory of their own.
export SHOALCHECK_HOME="$work/home"
KUBECONFIG="$here/kubeconfig.yaml" "$bin" preflight drain smoke-worker --context kind-smoke || true
KUBECONFIG="$here/kubeconfig.yaml" "$bin" audit --context kind-smoke > /dev/null
KUBECONFIG="$here/kubeconfig.yaml" "$bin" audit --context kind-smoke --output "$work/r.html" > /dev/null 2>&1 || true
echo "recorded $(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))))' "$here/recording.json") answers"
