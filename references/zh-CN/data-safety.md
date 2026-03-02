# 数据安全

本地环境危险数据库或 Redis 操作：

- 允许执行
- 但必须先备份

正式环境危险操作：

- 必须先说明要做什么
- 必须获得用户确认

默认受保护：

- DROP / TRUNCATE / DELETE / ALTER / 多行 UPDATE
- DEL / UNLINK / FLUSHDB / FLUSHALL / 大范围改写
