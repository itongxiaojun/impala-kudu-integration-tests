# Impala + Kudu 集成测试方案

## 项目概述
本项目实现了Impala与Kudu的集成，提供了数据存储、查询和性能测试的一体化解决方案。

## 主要功能

### 1. Kudu表管理
- 自动创建Kudu表
- 支持表结构定义
- 表存在性检查

### 2. 数据操作
- 批量数据插入
- 支持自定义批量大小
- 插入进度显示
- 数据插入结果验证

### 3. 性能测试
- 多表连接查询
- 可配置查询超时时间
- 查询执行时间测量
- 扫描行数统计
- 测试结果记录

### 4. 结果分析
- 生成CSV格式测试报告
- 包含查询超时、执行时间等关键指标
- 支持结果可视化分析

## 配置参数

| 参数名 | 默认值 | 描述 |
|--------|--------|------|
| IMPALA_HOST | cdp1 | Impala服务器地址 |
| IMPALA_PORT | 21000 | Impala服务端口 |
| KUDU_SCAN_TIMEOUT_MS | 600000 | Kudu扫描超时时间（毫秒） |
| BATCH_SIZE | 1000 | 批量插入大小 |
| TOTAL_ROWS | 1000000 | 总插入行数 |
| RESULTS_FILE | kudu_performance_results.csv | 测试结果文件 |

## 使用说明

1. 确保Impala和Kudu服务正常运行
2. 配置连接参数（IMPALA_HOST, IMPALA_PORT）
3. 设置测试参数（BATCH_SIZE, TOTAL_ROWS等）
4. 执行脚本：
   ```bash
   chmod +x impala_kudu_integration.sh
   ./impala_kudu_integration.sh
   ```
5. 查看测试结果：kudu_performance_results.csv

## 测试结果
测试结果包含以下指标：

- query_timeout_s: 查询超时时间（秒）
- success: 查询是否成功（1/0）
- execution_time_ms: 查询执行时间（毫秒）
- rows_scanned: 扫描行数
