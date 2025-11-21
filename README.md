# Argo Workflow Sandbox

A sandbox environment for learning and experimenting with Argo Workflows on Kubernetes using Kind.

## Overview

This project demonstrates a Producer-Consumer batch processing pattern using:

- **Argo Workflows** - Workflow orchestration on Kubernetes
- **Kind** - Local Kubernetes cluster
- **MySQL** - Database for batch data storage
- **Spring Boot** - Producer and Consumer applications

## Project Structure

```
.
├── apps/
│   ├── producer/          # Spring Boot producer application
│   └── consumer/          # Spring Boot consumer application
├── argo-workflow/
│   └── base/              # Argo Workflow Kustomize manifests
├── db/
│   └── mysql-deployment.yaml
├── scripts/
│   ├── create-cluster.sh  # Kind cluster creation script
│   └── setup.sh           # Environment setup script
├── workflows/
│   └── producer-consumer-workflow.yaml
└── kind-config.yaml       # Kind cluster configuration
```

## Prerequisites

- Docker
- Kind
- kubectl
- Argo CLI (optional)

## Quick Start

### 1. Create Kind Cluster

```bash
./scripts/create-cluster.sh
```

### 2. Setup Environment

```bash
./scripts/setup.sh
```

### 3. Submit Workflow

```bash
kubectl create -f workflows/producer-consumer-workflow.yaml
```

## Workflow Description

The `producer-consumer-rds` workflow implements a DAG-based batch pipeline:

1. **Producer Job** - Generates batch data and writes to MySQL
2. **Consumer Job** - Processes the batch data from MySQL (runs after producer completes)

### Parameters

- `batch-size`: Number of items to process (default: 100)
- `batch-id`: Unique identifier for the batch (default: workflow UID)

## Exposed Ports

- `30080` - For external access
- `2746` - Argo Workflow UI

## License

MIT
