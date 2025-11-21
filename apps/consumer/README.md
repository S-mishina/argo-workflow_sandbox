# Consumer

Spring Boot application that processes batch data from MySQL.

## Build

```bash
./gradlew bootJar
```

## Docker

```bash
docker build -t springboot-consumer:latest .
```

## Arguments

- `--batch.id` - Batch identifier to process

## Usage

```bash
java -jar build/libs/consumer.jar --batch.id=test-001
```
