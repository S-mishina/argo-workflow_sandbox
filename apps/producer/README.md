# Producer

Spring Boot application that generates batch data and writes to MySQL.

## Build

```bash
./gradlew bootJar
```

## Docker

```bash
docker build -t springboot-producer:latest .
```

## Arguments

- `--batch.size` - Number of items to generate
- `--batch.id` - Unique batch identifier

## Usage

```bash
java -jar build/libs/producer.jar --batch.size=100 --batch.id=test-001
```
