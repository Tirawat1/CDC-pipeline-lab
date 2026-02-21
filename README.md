# 📦 CDC Pipeline with Debezium + Kafka + Logstash

## 🚀 Overview

This project demonstrates how to build a **Change Data Capture (CDC)
pipeline** using:

-   **MariaDB** -- Source database with binlog enabled
-   **Debezium** -- Captures database change events from binlog
-   **Apache Kafka** -- Streams and stores change events
-   **Logstash** -- Processes and transforms Kafka messages
-   **Elasticsearch** -- Stores transformed data for search and analytics
-   **Docker Compose** -- Orchestrates all services locally

The goal is to capture database changes (INSERT, UPDATE, DELETE) in **real-time** 
and stream them to downstream systems without impacting database performance.

------------------------------------------------------------------------

## 🧠 What is Change Data Capture (CDC)?

CDC is a pattern that captures changes from a database transaction log
and publishes them as events.

Instead of running expensive batch jobs, CDC allows:

-   Near real-time synchronization
-   Event-driven architecture
-   Data replication between systems
-   Analytics pipelines

------------------------------------------------------------------------

## 🏗️ Architecture

    +-------------+      +-----------+      +--------+      +-----------+      +---------------+
    |  MariaDB    | ---> | Debezium  | ---> | Kafka  | ---> | Logstash  | ---> | Elasticsearch |
    |  (binlog)   |      | Connector |      | Topic  |      | Pipeline  |      |    (Index)    |
    +-------------+      +-----------+      +--------+      +-----------+      +---------------+

### Data Flow

1.  **MariaDB** writes changes to binary log (binlog) with ROW format
2.  **Debezium MySQL Connector** reads binlog and captures change events
3.  **Debezium** publishes change events to Kafka topic `dbserver1.inventory.customers`
4.  **Kafka** stores events in topic with configurable retention
5.  **Logstash** consumes Kafka messages and transforms them
6.  **Elasticsearch** indexes the transformed data for search

###🧩 Components Explained

### 1. **Zookeeper** (debezium/zookeeper:1.4)
- Manages Kafka cluster metadata and coordination
- Required for Kafka to operate
- Port: 2181

### 2. **Kafka** (debezium/kafka:1.4)
- Distributed event streaming platform
- Stores change events in topics
- Provides durability and scalability
- Port: 9092

### 3. **MariaDB** (mariadb:10.5)
- Source database with CDC enabled
- **Binlog Configuration Required**:
  - `binlog_format = ROW` - Captures full row data
  - `log_bin = mysql-bin` - Enables binary logging
  - `server-id = 184054` - Unique server identifier
- Port: 3306

### 4. **Debezium Connect** (debezium/connect:1.4)
- Kafka Connect runtime with Debezium connectors
- Monitors MariaDB binlog for changes
- Publishes events to Kafka in structured format
- REST API for connector management
- Port: 8083

### 5. **Logstash** (docker.elastic.co/logstash/logstash:7.10.2)
- Consumes messages from Kafka topic
- Transforms Debezium event format to Elasticsearch format
- Extracts `after` field from change events
- Handles INSERT and UPDATE operations
- Port: 5000

### 6. **Elasticsearch** (docker.elastic.co/elasticsearch/elasticsearch:7.10.2)
- Search and analytics engine
- Stores processed customer data
- Creates index automatically from Logstash
- Ports: 9200 (HTTP), 9300 (Transport) image: debezium/connect:latest
    depends_on:
      - kafka
      - mysql
    ports:
      - "8083:8083"
    environment:
      BOOTSTRAP_SERVERS: kafka:9092
      GROUP_ID: 1
      CONFIG_STORAGE_TOPIC: connect_configs
      OFFSET_STORAGE_TOPIC: connect_offsets
      STATUS_STORAGE_TOPIC: connect_statuses
```

------------------------------------------------------------------------

## ▶️ How to Run

### 1️⃣ Start services

``` bash
docker-compose up -d
```

### 2️⃣ Create Debezium Connector

``` bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{all services

``` bash
docker-compose up -d
```

Wait for all services to be ready (~30 seconds)

### 2️⃣ Register Debezium MySQL Connector

``` bash
curl -i -X POST \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d @register-mysql.json \
  http://localhost:8083/connectors
```

**register-mysql.json:**
```json
{
  "name": "inventory-connector",
  "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "1",
    "database.hostname": "mariadb",
    "database.port": "3306",
    "database.user": "debezium",
    "database.password": "debezium"
    }
}
   🧪 Testing Results

### ✅ What Works

| Operation | Status | Details |
|-----------|--------|---------|
| INSERT | ✅ Working | New records appear in Elasticsearch within 1-2 seconds |
| UPDATE | ✅ Working | Changed fields are updated in Elasticsearch |
| DELETE | ⚠️ Partial | Debezium captures delete events but Logstash doesn't remove from ES |
| Initial Snapshot | ✅ Working | Existing data is captured on connector startup |

### 📊 Performance

- **Latency**: ~1-2 seconds from database change to Elasticsearch
- **Throughput**: Tested with individual operations (not load tested)
- **Data Consistency**: Eventually consistent

### 🐛 Known Limitations

1. **DELETE operations**: Currently not handled by Logstash pipeline
   - Events are sent to Kafka but not processed
   - Need to add logic to detect `"op": "d"` and call Elasticsearch delete API

2. 🔧 Key Configurations

### MariaDB Binlog Setup
Located in `docker/database/conf.d/mysql.cnf/cdc.cnf`:
```ini
[mysqld]
server-id = 184054
log_bin = mysql-bin
binlog_format = ROW          # Required for Debezium
binlog_row_image = FULL      # Captures complete row data
expire_logs_days = 10        # Binlog retention
```

### Debezium User Permissions
In `docker/database/docker-entrypoint-initdb.d/invertory.sql`:
```sql
CREATE USER 'debezium'@'%' IDENTIFIED BY 'debezium';
GRANT SELECT, RELOAD, SHOW DATABASES, 
    � Practical Use Cases

### Data Replication
- Sync data from production DB to analytics warehouse
- Maintain read replicas without replication lag
- Migrate data between different database systems

### Event-Driven Architecture
- Trigger business logic when data changes
- Publish domain events for microservices
- Build audit logs and compliance tracking

### Search & Analytics
- Keep Elasticsearch in sync with operational database
- Enable full-text search without database load
- Real-time dashboards and reporting

### Cache Invalidation
- Invalidate Redis/Memcached when data changes
- Keep materialized views up to date
- Update downstream aggregates

## 📚 What I Learned

### Technical Skills
-   ✅ How CDC works at the binlog level
-   ✅ Debezium event format and metadata
-   ✅ Kafka topic partitioning and consumer groups
-   ✅ Logstash pipeline configuration
-   ✅ Docker Compose networking and dependencies
-   ✅ Elasticsearch indexing and document updates

### Key Insights
1. **Not all Debezium tutorials are accurate** - many claim Debezium includes 
   Elasticsearch Sink Connector, but it doesn't. Logstash is the standard solution.

2. **Binlog format matters** - Must use `ROW` format, not `STATEMENT` or `MIXED`

3. **User permissions are critical** - Debezium needs `REPLICATION SLAVE` and 
   `REPLICATION CLIENT` privileges

4. **Document ID strategy** - Using primary key as Elasticsearch `_id` enables 
   proper updates instead of duplicates

5. **DELETE handling requires extra work** - Logstash doesn't automatically 
   delete documents; needs custom logic

## 🔗 Useful Commands

```bash
# Check connector status
curl http://localhost:8083/connectors/inventory-connector/status

# List all connectors
curl http://localhost:8083/connectors

# Delete a connector
curl -X DELETE http://localhost:8083/connectors/inventory-connector

# View Kafka topics
docker-compose exec kafka kafka-topics --list --bootstrap-server kafka:9092

# Watch Kafka messages
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server kafka:9092 \
  --topic dbserver1.inventory.customers \
  --from-beginning

# Check Elasticsearch indices
curl http://localhost:9200/_cat/indices

# View Logstash logs
docker-compose logs -f logstash
```

## 🙏 Credits

This project is inspired by the article:

**"ลองสร้าง Change Data Capture Pipeline ด้วย Debezium และ Apache Kafka"**  
Published on Medium by Decimo

📖 Original article:  
https://decimo.medium.com/ลองสร้าง-change-data-capture-pipeline-ด้วย-debezium-และ-apache-kafka-8bf17201a9d6

⚠️ **Important Note**: The original article mentions using "Elasticsearch Sink 
Connector included in Debezium Connect" - this information is **incorrect**. 
Debezium Connect 1.4 does not include the Confluent Elasticsearch Sink Connector. 
This implementation uses **Logstash** instead, which is the standard ELK stack 
approach.

---

This repository is created for **educational purposes** to demonstrate CDC 
concepts and real-world implementation challengese systems

### ❌ Cons

-   **Infrastructure complexity**: 6+ containers to manage
-   **Requires binlog/WAL**: Must configure database properly
-   **Operational overhead**: Monitoring, alerting, troubleshooting
-   **Schema evolution**: DDL changes need careful handling
-   **Storage costs**: Kafka and Elasticsearch both store data
-   **Learning curve**: Understanding Debezium event format
**OpenTelemetry is not a replacement for CDC**, but they complement each other:

You can use OpenTelemetry to monitor your CDC pipeline:
- Monitor Kafka consumer lag
- Track connector failures and retries
- Measure end-to-end pipeline latency
- Trace event flow across services
- Alert on data sync delays
``` bash
docker-compose exec mariadb mysql -uroot -pdebezium inventory \
  -e "INSERT INTO customers (first_name, last_name, email) VALUES ('Jane', 'Smith', 'jane@example.com');"
```

#### Check if data synced to Elasticsearch
``` bash
curl "http://localhost:9200/customers/_search?pretty"
```

#### Test UPDATE
``` bash
docker-compose exec mariadb mysql -uroot -pdebezium inventory \
  -e "UPDATE customers SET email = 'jane.updated@example.com' WHERE first_name = 'Jane';"
```

#### Test DELETE
``` bash
docker-compose exec mariadb mysql -uroot -pdebezium inventory \
  -e "DELETE FROM customers WHERE first_name = 'Jane';"
```

**Note**: Current Logstash configuration handles INSERT and UPDATE. 
DELETE operations are captured by Debezium but not processed by Logstash yetg & debugging
  Example: Debezium                Example: OpenTelemetry

OpenTelemetry is not a replacement for CDC.

You can use OpenTelemetry to:

-   Monitor Kafka lag
-   Track connector failures
-   Measure pipeline latency
-   Trace event flow

But it does not replicate database data.

------------------------------------------------------------------------

## ⚖️ Trade-offs

### Pros

-   Near real-time replication
-   Decoupled architecture
-   Scalable event streaming
-   No polling required

### Cons

-   Infrastructure complexity
-   Requires binlog/WAL configuration
-   Operational overhead
-   Schema evolution handling required

------------------------------------------------------------------------

## 📚 Learning Outcomes

-   Understand how CDC works internally
-   Learn how Debezium reads binlog
-   Understand Kafka topic architecture
-   Build event-driven data pipeline
-   Differentiate between data pipeline and observability pipeline

------------------------------------------------------------------------

## 🙏 Credits

This project is inspired by the article:

"ลองสร้าง Change Data Capture Pipeline ด้วย Debezium และ Apache Kafka"\
Published on Medium by Decimo

Original article:\
https://decimo.medium.com/ลองสร้าง-change-data-capture-pipeline-ด้วย-debezium-และ-apache-kafka-8bf17201a9d6

This repository is created for educational purposes only.
