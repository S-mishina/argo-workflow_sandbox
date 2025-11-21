#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Creating Kind Cluster with Argo Workflows ==="

# 1. Kindクラスタを作成（既存があれば再利用、なければランダム名で作成）
EXISTING_CLUSTER=$(kind get clusters 2>/dev/null | grep "^argo-workflow" | head -1)

if [ -n "$EXISTING_CLUSTER" ]; then
    KIND_CLUSTER="$EXISTING_CLUSTER"
    echo "[1/3] Using existing cluster: $KIND_CLUSTER"
    # Ensure kubeconfig exists for the cluster
    kind export kubeconfig --name "$KIND_CLUSTER"
else
    RANDOM_SUFFIX=$(head -c 4 /dev/urandom | xxd -p)
    KIND_CLUSTER="argo-workflow-${RANDOM_SUFFIX}"
    echo "[1/3] Creating kind cluster: $KIND_CLUSTER..."
    kind create cluster --name "$KIND_CLUSTER" --config "$ROOT_DIR/kind-config.yaml" 2>/dev/null || \
    kind create cluster --name "$KIND_CLUSTER"
fi

# Switch to the kind cluster context
echo "Switching to context: kind-${KIND_CLUSTER}"
kubectl config use-context "kind-${KIND_CLUSTER}"
kubectl cluster-info --context "kind-${KIND_CLUSTER}"

# Show kubie hint if available
if command -v kubie &> /dev/null; then
    echo ""
    echo "Tip: Use 'kubie ctx kind-${KIND_CLUSTER}' to switch context with kubie"
fi

# 2. Argo Workflowsをインストール
echo "[2/3] Installing Argo Workflows..."
kubectl apply -k "$ROOT_DIR/argo-workflow/base"

# 3. クラスタ全体のRBACを設定
echo "[3/3] Setting up cluster-wide RBAC..."
kubectl apply -f "$ROOT_DIR/argo-workflow/base/default-namespace-rbac.yaml"

# Argoの起動を待つ
echo "Waiting for Argo to be ready..."
kubectl wait --for=condition=available deployment/argo-server -n argo --timeout=120s

echo ""
echo "=== Kind Cluster Created ==="
echo ""
echo "Cluster: $KIND_CLUSTER"
echo "Argo UI: kubectl -n argo port-forward svc/argo-server 2746:2746"
echo ""
echo "Next step: ./scripts/setup.sh"
