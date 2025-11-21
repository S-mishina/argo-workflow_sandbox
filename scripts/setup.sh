#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
NAMESPACE="${NAMESPACE:-default}"
# kindクラスターを自動検出（環境変数で上書き可能）
if [ -z "$KIND_CLUSTER" ]; then
  KIND_CLUSTER=$(kind get clusters 2>/dev/null | head -n1)
  if [ -z "$KIND_CLUSTER" ]; then
    echo "Error: No kind cluster found. Please create one first."
    exit 1
  fi
fi
echo "Using kind cluster: $KIND_CLUSTER"

echo "=== Argo Workflow Batch Setup ==="

# 1. MySQLをデプロイ
echo "[1/5] Deploying MySQL..."
kubectl apply -f "$ROOT_DIR/db/mysql-deployment.yaml" -n "$NAMESPACE"

# 2. MySQLの起動を待つ
echo "[2/5] Waiting for MySQL to be ready..."
kubectl wait --for=condition=available deployment/mysql -n "$NAMESPACE" --timeout=120s

echo "Waiting for MySQL to initialize..."
sleep 10

# 3. スキーマを適用
echo "[3/5] Applying database schema..."
cat "$ROOT_DIR/db/schema/001_create_batch_tasks.sql" | kubectl exec -i -n "$NAMESPACE" deploy/mysql -- mysql -ubatch_user -pbatch_password batch_db

# 4. Dockerイメージをビルド
echo "[4/5] Building Docker images..."
docker build -t springboot-producer:latest "$ROOT_DIR/apps/producer/"
docker build -t springboot-consumer:latest "$ROOT_DIR/apps/consumer/"

# 5. kindクラスタにイメージをロード
echo "[5/5] Loading images to kind cluster..."
kind load docker-image springboot-producer:latest --name "$KIND_CLUSTER"
kind load docker-image springboot-consumer:latest --name "$KIND_CLUSTER"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "To run the workflow:"
echo "  argo submit $ROOT_DIR/workflows/producer-consumer-workflow.yaml -n $NAMESPACE"
echo ""
echo "To watch the workflow:"
echo "  argo watch @latest -n $NAMESPACE"
