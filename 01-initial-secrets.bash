#!/bin/bash

kubectl delete job secret-init

SRC_FILE=00-configs/initial-secret.yaml
kubectl apply -f ${SRC_FILE}

# รอให้ Job สร้าง Secret เสร็จ
sleep 10

### GIT ###
GIT_NS=gitea

# สร้าง secret ใน namespace gitea โดยนำค่ามาจาก initial-secret จาก default namespace
kubectl create namespace ${GIT_NS} --dry-run=client -o yaml | kubectl apply -f -


# รอให้ secret initial-secret มี key GIT_USER ก่อนที่จะสร้าง secret gitea-admin-secret
# ที่ต้องรอเพราะว่าบางที job initial-secret ใช้เวลานานในการไปดึง image แล้วสร้าง secret เสร็จ
echo "Waiting for secret initial-secret with key GIT_USER..."
until kubectl get secret initial-secret -n default \
  -o jsonpath='{.data.GIT_USER}' 2>/dev/null | grep -q .; do
  sleep 2
done
echo "Secret and key found"


GIT_USER=$(kubectl get secret initial-secret -n default -o jsonpath='{.data.GIT_USER}' | base64 -d)
GIT_PASSWORD=$(kubectl get secret initial-secret -n default -o jsonpath='{.data.GIT_PASSWORD}' | base64 -d)

kubectl create secret generic gitea-admin-secret \
  -n ${GIT_NS} \
  --from-literal=username=${GIT_USER} \
  --from-literal=password=${GIT_PASSWORD} \
  --from-literal=email=admin@example.com \
  --dry-run=client -o yaml | kubectl apply -f -
