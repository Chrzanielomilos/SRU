#!/bin/bash
set -e

# Użycie:
#   ./k8s/k8_deploy.sh           # pełne czyszczenie, build backend+frontend i kubectl apply
#   ./k8s/k8_deploy.sh -b|b      # tylko backend
#   ./k8s/k8_deploy.sh -f|f      # tylko frontend
#   ./k8s/k8_deploy.sh -h|--help # pomoc

print_usage() {
  echo "Użycie:"
  echo "  $0            - pełne wdrożenie (backend + frontend)"
  echo "  $0 -b | b     - tylko backend"
  echo "  $0 -f | f     - tylko frontend"
  echo "  $0 -h | --help"
}

TARGET="all"
if [[ $# -gt 1 ]]; then
  echo "Błąd: podaj maksymalnie jeden argument."
  echo
  print_usage
  exit 1
fi

if [[ $# -eq 1 ]]; then
  case "$1" in
    -b|b|--backend)  TARGET="backend" ;;
    -f|f|--frontend) TARGET="frontend" ;;
    -h|--help)       print_usage; exit 0 ;;
    *) echo "Nieznany argument: $1"; echo; print_usage; exit 1 ;;
  esac
fi

cleanup_backend() {
  echo "========================================"
  echo " Usuwanie starych kontenerów/obrazów (backend)..."
  echo "========================================"
  docker rm -f sru-backend || true
  docker rmi sru-backend:latest || true
}

cleanup_frontend() {
  echo "========================================"
  echo " Usuwanie starych kontenerów/obrazów (frontend)..."
  echo "========================================"
  docker rm -f sru-frontend || true
  docker rmi sru-frontend:latest || true
}

build_backend() {
  echo "========================================"
  echo " Budowanie backendu..."
  echo "========================================"
  docker build -t sru-backend:latest ./backend
}

build_frontend() {
  echo "========================================"
  echo " Budowanie frontendu..."
  echo "========================================"
  docker build -t sru-frontend:latest ./frontend
}

deploy_all() {
  echo "========================================"
  echo " Wdrażanie do Kubernetes..."
  echo "========================================"
  kubectl apply -f k8s/
}

# Główna logika
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
echo " ✅ Nowa wersja wdrożona!"
echo "========================================"
