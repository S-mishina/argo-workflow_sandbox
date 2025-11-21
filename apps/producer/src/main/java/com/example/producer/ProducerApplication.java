package com.example.producer;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@SpringBootApplication
public class ProducerApplication {
    public static void main(String[] args) {
        SpringApplication.run(ProducerApplication.class, args);
    }
}

@Component
class ProducerRunner implements CommandLineRunner {

    private final JdbcTemplate jdbcTemplate;

    @Value("${batch.size:100}")
    private int batchSize;

    @Value("${batch.id:default}")
    private String batchId;

    public ProducerRunner(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) throws Exception {
        System.out.println("Producer started - Batch ID: " + batchId + ", Size: " + batchSize);

        // バッチデータを生成してDBに挿入
        for (int i = 0; i < batchSize; i++) {
            String taskData = String.format("{\"taskNumber\": %d, \"payload\": \"Task data %d\"}", i, i);
            jdbcTemplate.update(
                "INSERT INTO batch_tasks (batch_id, task_data, status) VALUES (?, ?, 'PENDING')",
                batchId, taskData
            );
        }

        System.out.println("Producer completed - Inserted " + batchSize + " tasks for batch: " + batchId);
    }
}
