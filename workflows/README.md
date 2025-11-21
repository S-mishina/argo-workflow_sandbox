# Argo Workflows Guide

## Basic Structure

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: workflow-name
spec:
  serviceAccountName: argo
  entrypoint: main-template    # First template to execute
  arguments:                   # Global parameters
    parameters:
    - name: param-name
      value: "default-value"
  templates:
    # Template definitions
```

## DAG (Directed Acyclic Graph)

DAG (Directed Acyclic Graph) allows you to define task dependencies and control parallel/sequential execution.

### Key Features

| Feature | Description |
|---------|-------------|
| **Maximize Parallelism** | Tasks without dependencies run in parallel automatically |
| **Explicit Dependencies** | Define dependencies declaratively with `dependencies` |
| **Failure Control** | Dependent tasks are skipped when upstream tasks fail |

### Basic DAG Structure

```yaml
templates:
- name: dag-template
  dag:
    tasks:
    - name: task-a
      template: template-a

    - name: task-b
      template: template-b
      dependencies: [task-a]    # Runs after task-a completes

    - name: task-c
      template: template-c
      dependencies: [task-a]    # Runs after task-a (parallel with task-b)

    - name: task-d
      template: template-d
      dependencies: [task-b, task-c]  # Multiple dependencies
```

### Dependency Patterns

**Sequential**

```mermaid
graph LR
    A --> B --> C
```

**Parallel**

```mermaid
graph LR
    A --> B
    A --> C
```

**Diamond**

```mermaid
graph LR
    A --> B --> D
    A --> C --> D
```

### Failure Behavior Control

#### failFast (Default: true)

```yaml
dag:
  failFast: false  # Continue other tasks even if one fails
  tasks:
    # ...
```

#### depends (Advanced Dependency Conditions)

Use `depends` instead of `dependencies` to specify conditions like success/failure/skipped:

```yaml
dag:
  tasks:
  - name: task-a
    template: template-a

  - name: task-b
    depends: "task-a.Succeeded"  # Only on success
    template: template-b

  - name: task-c
    depends: "task-a.Failed"     # Only on failure
    template: error-handler

  - name: task-d
    depends: "task-a.Succeeded || task-a.Failed"  # On completion
    template: cleanup

  - name: task-e
    depends: "(task-b.Succeeded && task-c.Skipped) || task-d.Succeeded"
    template: complex-condition
```

#### Available Conditions

| Condition | Description |
|-----------|-------------|
| `.Succeeded` | Task succeeded |
| `.Failed` | Task failed |
| `.Skipped` | Task was skipped |
| `.Daemoned` | Daemon task is running |
| `.Errored` | Task errored |

### Dynamic Task Generation (withItems / withParam)

```yaml
dag:
  tasks:
  - name: fan-out
    template: process-item
    withItems:
      - item1
      - item2
      - item3
    # 3 tasks run in parallel

  - name: fan-out-param
    template: process-item
    withParam: "{{tasks.previous.outputs.parameters.items}}"
    # Dynamically generate tasks from JSON list
```

### Steps vs DAG

| Aspect | Steps | DAG |
|--------|-------|-----|
| Dependencies | Implicit (order-based) | Explicit (`dependencies`) |
| Best for | Simple sequential flows | Complex dependency graphs |
| Parallelism | Only within same step | Auto-parallel if no deps |
| Readability | Good for simple flows | Good for complex flows |

### Best Practices

1. **Avoid circular dependencies** - DAG does not allow cycles
2. **Use unique task names** - No duplicates within same DAG
3. **Consider failFast** - Set to `false` if error handling needed
4. **depends vs dependencies** - Use `depends` for conditional execution

## Parameter Passing

### Referencing Global Parameters

```yaml
# Reference parameters defined in workflow.parameters
value: "{{workflow.parameters.param-name}}"
```

### Passing Parameters Between Tasks

```yaml
dag:
  tasks:
  - name: task-a
    template: template-a
    arguments:
      parameters:
      - name: input-param
        value: "{{workflow.parameters.global-param}}"

  - name: task-b
    template: template-b
    dependencies: [task-a]
    arguments:
      parameters:
      - name: input-param
        value: "{{tasks.task-a.outputs.parameters.output-param}}"
```

### Defining Parameters in Templates

```yaml
- name: my-template
  inputs:
    parameters:
    - name: param-name
  container:
    image: my-image
    args:
      - "--param={{inputs.parameters.param-name}}"
```

## Common Variables

| Variable | Description |
|----------|-------------|
| `{{workflow.name}}` | Workflow name |
| `{{workflow.uid}}` | Workflow UID |
| `{{workflow.parameters.NAME}}` | Global parameter |
| `{{inputs.parameters.NAME}}` | Template input parameter |
| `{{tasks.TASK.outputs.parameters.NAME}}` | Output from another task |
| `{{steps.STEP.outputs.parameters.NAME}}` | Output from another step |

## Container Template

```yaml
- name: container-template
  inputs:
    parameters:
    - name: message
  container:
    image: alpine:latest
    command: [sh, -c]
    args: ["echo {{inputs.parameters.message}}"]
    env:
    - name: ENV_VAR
      value: "value"
    - name: SECRET_VAR
      valueFrom:
        secretKeyRef:
          name: secret-name
          key: key-name
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"
        cpu: "200m"
```

## Steps Template

```yaml
templates:
- name: steps-template
  steps:
  - - name: step1          # First step
      template: template-a
  - - name: step2a         # Parallel execution
      template: template-b
    - name: step2b
      template: template-c
  - - name: step3          # After step2a and step2b complete
      template: template-d
```

## Conditional Execution

```yaml
dag:
  tasks:
  - name: conditional-task
    template: my-template
    when: "{{tasks.previous.outputs.result}} == success"
```

## Output Parameters

```yaml
- name: output-template
  container:
    image: alpine
    command: [sh, -c]
    args: ["echo -n 'result' > /tmp/output.txt"]
  outputs:
    parameters:
    - name: result
      valueFrom:
        path: /tmp/output.txt
```

## Retry Strategy

```yaml
- name: retry-template
  retryStrategy:
    limit: 3
    retryPolicy: "OnError"
  container:
    image: my-image
```

## Example in This Repository

`producer-consumer-workflow.yaml` uses the following DAG pattern:

```
Producer -> Consumer
```

- **Producer**: Writes data to RDS
- **Consumer**: Processes data after Producer completes (`dependencies: [producer]`)

## Execution Commands

```bash
# Submit workflow
argo submit workflows/producer-consumer-workflow.yaml

# Submit with parameters
argo submit workflows/producer-consumer-workflow.yaml \
  -p batch-size=200 \
  -p batch-id=custom-id

# Check status
argo list
argo get <workflow-name>
argo logs <workflow-name>
```

## References

- [Argo Workflows Documentation](https://argoproj.github.io/argo-workflows/)
- [DAG Template](https://argoproj.github.io/argo-workflows/walk-through/dag/)
- [Variables](https://argoproj.github.io/argo-workflows/variables/)
