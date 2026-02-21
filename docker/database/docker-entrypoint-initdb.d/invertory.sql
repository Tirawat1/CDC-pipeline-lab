-- Create debezium user with proper permissions
CREATE USER IF NOT EXISTS 'debezium'@'%' IDENTIFIED BY 'debezium';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS inventory;
USE inventory;

CREATE TABLE customers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    email VARCHAR(255)
);

INSERT INTO customers (first_name, last_name, email) VALUES
('Sally', 'Thomas', 'sally.thomas@acme.com'),
('George', 'Bailey', 'gbailey@foobar.com');
