## CFK Test Scenarios

### Setup
1. Start minikube using: `minikube start --cpus=6 --memory=20019 --kubernetes-version=v1.21.0`
2. Build Chaos Kafka Docker image inside the cluster using: `./build-inside.sh`
3. Deploy the test-harness using: `kubectl apply -k ./kustomize`

### useful commands
```shell
docker run -e TEST_CASE_RUNNER=scenario-1.yml chaos-kafka
```