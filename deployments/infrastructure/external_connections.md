# External Service Connections

IP: 10.88.88.13

## Services with External Access

- **MongoDB**:
  - URL: `mongodb://10.88.88.13:27017`
  - Username: `root`
  - Password: `root123456`
  - Database: `openim_v3`
  - Protocol: MongoDB

- **Redis**:
  - URL: `redis://10.88.88.13:6379`
  - Password: `root123456`
  - Protocol: Redis TCP

- **Etcd**:
  - URL: `http://10.88.88.13:12379`
  - Username: `root`
  - Password: `root123456`
  - Protocol: HTTP

- **Zookeeper**:
  - URL: `10.88.88.13:2181`
  - Protocol: Zookeeper

- **Redpanda (Kafka)**:
  - URL: `10.88.88.13:9092`
  - Protocol: Kafka

- **MinIO API**:
  - URL: `http://10.88.88.13:9000`
  - Username: `root`
  - Password: `root123456`
  - Protocol: HTTP (S3 API)

- **MinIO Console**:
  - URL: `http://10.88.88.13:9090`
  - Username: `root`
  - Password: `root123456`
  - Protocol: HTTP (Web Console)

## Notes

- All services are configured with authentication as specified in the docker-compose.yaml file.
- MongoDB has a dedicated user "openIM" with readWrite access to the "openim_v3" database.