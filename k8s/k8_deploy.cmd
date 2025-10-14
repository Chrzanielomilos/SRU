#!/usr/bin/env bash
set -e

# Usage:
#   ./k8s/deploy.sh           # full clean, build backend+frontend, and kubectl apply
#   ./k8s/deploy.sh -b|b      # backend only
#   ./k8s/deploy.sh -f|f      # frontend only
#   ./k8s/deploy.sh -h|--help # help

print_usage() {
  echo "Usage:"
  echo "  $0            - full deploy (backend + frontend)"
  echo "  $0 -b | b     - backend only"
  echo "  $0 -f | f     - frontend only"
  echo "  $0 -h | --help"
}

TARGET="all"

if [ $# -gt 1 ]; then
  echo "Error: only one argument allowed."
  echo
  print_usage
  exit 1
fi

if [ $# -eq 1 ]; then
  case "$1" in
    -b|b|--backend)  TARGET="backend" ;;
    -f|f|--frontend) TARGET="frontend" ;;
    -h|--help)       print_usage; exit 0 ;;
    *) echo "Unknown argument: $1"; echo; print_usage; exit 1 ;;
  esac
fi

cleanup_backend() {
  echo "========================================"
  echo " Removing old containers/images (backend)..."
  echo "========================================"
  docker rm -f sru-backend 2>/dev/null || true
  docker rmi sru-backend:latest 2>/dev/null || true
}

cleanup_frontend() {
  echo "========================================"
  echo " Removing old containers/images (frontend)..."
  echo "========================================"
  docker rm -f sru-frontend 2>/dev/null || true
  docker rmi sru-frontend:latest 2>/dev/null || true
}

build_backend() {
  echo "========================================"
  echo " Building backend..."
  echo "========================================"
  docker build -t sru-backend:latest ./backend
}

build_frontend() {
  echo "========================================"
  echo " Building frontend..."
  echo "========================================"
  docker build --no-cache -t sru-frontend:latest ./frontend
}

deploy_all() {
  echo "========================================"
  echo " Deploying to Kubernetes..."
  echo "========================================"
  kubectl apply -f k8s/
  kubectl rollout restart deployment sru-frontend || true
}

# Main logic
case "$TARGET" in
  all)
    cleanup_backend
    cleanup_frontend
    build_backend
    build_frontend
    deploy_all
    ;;
  backend)
    cleanup_backend
    build_backend
    deploy_all
    ;;
  frontend)
    cleanup_frontend
    build_frontend
    deploy_all
    ;;
esac

echo "========================================"
echo " ✅ Deployment complete!"
echo "========================================"

