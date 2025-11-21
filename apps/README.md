# Applications

Spring Boot applications for the Producer-Consumer batch processing workflow.

## Structure

```
apps/
├── producer/    # Generates and writes batch data to MySQL
└── consumer/    # Processes batch data from MySQL
```

## Tech Stack

- Java 17
- Spring Boot 3.2.0
- Spring JDBC
- MySQL Connector

## Building

### Build All Applications

```bash
# Producer
cd producer && ./gradlew bootJar

# Consumer
cd consumer && ./gradlew bootJar
```

### Build Docker Images

```bash
# Producer
docker build -t springboot-producer:latest ./producer

# Consumer
docker build -t springboot-consumer:latest ./consumer
```

### Load Images to Kind

```bash
kind load docker-image springboot-producer:latest
kind load docker-image springboot-consumer:latest
```

## Environment Variables

Both applications require the following environment variables:

| Variable | Description |
|----------|-------------|
| `SPRING_DATASOURCE_URL` | MySQL JDBC URL |
| `SPRING_DATASOURCE_USERNAME` | Database username |
| `SPRING_DATASOURCE_PASSWORD` | Database password |
| `SPRING_DATASOURCE_DRIVER_CLASS_NAME` | JDBC driver class |
