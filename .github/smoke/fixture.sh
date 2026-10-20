#!/usr/bin/env bash
# The objects release-smoke reads, created in the current kubectl context: two replicas pinned to smoke-worker under
# a budget that allows no disruption, so draining smoke-worker has something that stops it. The Linux job runs this
# against its live kind cluster; record.sh runs it against the cluster whose answers macOS and Windows replay.
set -euo pipefail
kubectl create namespace payments
kubectl -n payments create deployment ledger-api --image=registry.k8s.io/pause:3.9 --replicas=2
kubectl -n payments patch deployment ledger-api --type merge -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/hostname":"smoke-worker"}}}}}'
kubectl -n payments create pdb ledger-api --selector=app=ledger-api --max-unavailable=0
kubectl -n payments rollout status deployment/ledger-api --timeout=180s
# The budget's status is written by a controller a moment later; the drain verdict reads it.
kubectl -n payments wait pdb/ledger-api --for=jsonpath='{.status.expectedPods}'=2 --timeout=120s
