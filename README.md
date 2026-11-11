# Spring Boot Kubernetes Performance Testing

## Overview

This project demonstrates how to deploy a Spring Boot application using Docker and Kubernetes and test its behavior under sudden traffic spikes.

The main objective is to understand Kubernetes Horizontal Pod Autoscaling (HPA), pod readiness, resource utilization, and how traffic spikes can affect application availability.

## Technologies Used

- Java 17
- Spring Boot
- Maven
- Docker
- Kubernetes
- Minikube
- kubectl
- Kubernetes HPA
- PowerShell

## Prerequisites

Install the following tools before running the project:

- [Java JDK 17](https://adoptium.net/)
- [Git](https://git-scm.com/)
- [Maven](https://maven.apache.org/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

Verify the installations:

```powershell
java -version
mvn -version
docker --version
kubectl version --client
minikube version
```

## 1. Download the Project

Clone the repository:

Navigate to the project directory:

```powershell
cd performance-testing-kubernetes
```

## 2. Run the Spring Boot Application Locally

Build the application:

```powershell
mvn clean package
```

Run the application:

```powershell
java -jar target/performanceTesting-*.jar
```

Test the application:

```text
http://localhost:8080/api/hello
http://localhost:8080/api/status
```

## 3. Build and Run Using Docker

Build the Docker image:

```powershell
docker build -t performance-testing:2.0 .
```

Run the container:

```powershell
docker run -d -p 8080:8080 --name performance-testing performance-testing:2.0
```

Check the running container:

```powershell
docker ps
```

Test:

```text
http://localhost:8080/api/status
```

Stop and remove the container:

```powershell
docker stop performance-testing
docker rm performance-testing
```

## 4. Start Minikube

Start the Kubernetes cluster:

```powershell
minikube start
```

Enable the metrics server:

```powershell
minikube addons enable metrics-server
```

Verify the cluster:

```powershell
kubectl get nodes
```

## 5. Deploy the Application to Kubernetes

For a locally built Minikube image, make sure the image is available to the Minikube cluster. One option is:

```powershell
minikube image load performance-testing:2.0
```

Apply the Deployment:

```powershell
kubectl apply -f k8s/deployment.yml
```

Apply the Service:

```powershell
kubectl apply -f k8s/service.yml
```

Apply the Ingress:

```powershell
kubectl apply -f k8s/ingress.yml
```

Apply the HPA:

```powershell
kubectl apply -f k8s/hpa.yml
```

Check Kubernetes resources:

```powershell
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get ingress
kubectl get hpa
```

## 6. Access the Application

Start the Ingress controller port forwarding:

```powershell
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8081:80
```

Keep the terminal running.

Access the application:

```text
http://localhost:8081
```

## 7. Monitor Autoscaling

Watch pods:

```powershell
kubectl get pods -w
```

Watch HPA:

```powershell
kubectl get hpa -w
```

Monitor CPU usage:

```powershell
kubectl top pods
kubectl top nodes
```

Describe HPA:

```powershell
kubectl describe hpa performance-testing-hpa
```

## 8. Performance Testing

Run the PowerShell load-testing script:

```powershell
.\load-test.ps1
```

The script sends up to 100 concurrent HTTP requests and displays successful and failed requests in the terminal.

Observe pod scaling while the test runs:

```powershell
kubectl get pods -w
```

In another terminal:

```powershell
kubectl get hpa -w
```

## 9. Important Kubernetes Concepts Demonstrated

- Deployment and ReplicaSet
- Pods and container lifecycle
- Kubernetes Service
- Ingress
- Readiness, startup and liveness probes
- CPU requests and limits
- Horizontal Pod Autoscaler
- Dynamic pod scaling
- Traffic spike testing
- Pod startup and readiness delays

## 10. Cleanup

Delete the Kubernetes resources:

```powershell
kubectl delete -f k8s/hpa.yml
kubectl delete -f k8s/ingress.yml
kubectl delete -f k8s/service.yml
kubectl delete -f k8s/deployment.yml
```

Stop Minikube:

```powershell
minikube stop
```

---

## Project Objective

Reproduce a real-world Kubernetes performance issue where incoming traffic increases suddenly, existing pods become overloaded, and newly created pods take time to become Ready.

The project helps investigate autoscaling behavior, application capacity, readiness delays, and techniques for improving availability while controlling infrastructure costs.
