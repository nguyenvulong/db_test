-- Create database if not exists
CREATE DATABASE IF NOT EXISTS testdb;
USE testdb;

-- Create tasks table if not exists
CREATE TABLE IF NOT EXISTS tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_name VARCHAR(255) NOT NULL,
    task_description TEXT,
    priority INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    selected BOOLEAN DEFAULT FALSE
);

-- Clear existing data if needed
TRUNCATE TABLE tasks;

-- Generate 100,000 sample records
DELIMITER //
CREATE PROCEDURE generate_sample_data()
BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 500 DO
        INSERT INTO tasks (task_name, task_description, priority)
        VALUES (
            CONCAT('Task_', i),
            CONCAT('Description for task ', i, '. This is a synthetic task for testing concurrency.'),
            FLOOR(1 + RAND() * 5)
        );
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

-- Execute the procedure
CALL generate_sample_data();

-- Drop the procedure
DROP PROCEDURE generate_sample_data;

-- Verify
SELECT COUNT(*) FROM tasks;
