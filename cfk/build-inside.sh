#!/bin/bash
eval $(minikube docker-env)
docker build -t chaos-kafka .