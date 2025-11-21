package com.example.consumer;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@SpringBootApplication
public class ConsumerApplication {
    public static void main(String[] args) {
        SpringApplication.run(ConsumerApplication.class, args);
    }
}

@Component
class ConsumerRunner implements CommandLineRunner {

    private final JdbcTemplate jdbcTemplate;

    @Value("${batch.id:default}")
    private String batchId;

    public ConsumerRunner(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) throws Exception {
        System.out.println("Consumer started - Processing batch: " + batchId);

        // PENDINGのタスクを取得して処理
        List<Map<String, Object>> tasks = jdbcTemplate.queryForList(
            "SELECT id, task_data FROM batch_tasks WHERE batch_id = ? AND status = 'PENDING'",
            batchId
        );

        System.out.println("Found " + tasks.size() + " tasks to process");

        int processed = 0;
        for (Map<String, Object> task : tasks) {
            Long taskId = (Long) task.get("id");
            String taskData = (String) task.get("task_data");

            // タスク処理（ここにビジネスロジックを実装）
            processTask(taskId, taskData);

            // ステータスを更新
            jdbcTemplate.update(
                "UPDATE batch_tasks SET status = 'COMPLETED' WHERE id = ?",
                taskId
            );
            processed++;
        }

        System.out.println("Consumer completed - Processed " + processed + " tasks for batch: " + batchId);
    }

    private void processTask(Long taskId, String taskData) {
        // ビジネスロジックの実装
        System.out.println("Processing task " + taskId + ": " + taskData);
    }
}
