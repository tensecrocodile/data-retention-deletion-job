# Data Retention & Deletion Job

[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A GDPR-compliant, production-ready data retention and deletion job system designed for PostgreSQL. Automates data lifecycle management with comprehensive audit logging, safety checks, and scheduled execution capabilities.

## Features

- **GDPR Compliant**: Full audit trail for all deletion operations (Article 17 - Right to be Forgotten)
- **Flexible Retention Policies**: YAML-based configuration for defining data retention rules
- **Dry-Run Mode**: Preview deletions before execution for safety
- **Automated Scheduling**: APScheduler integration for daily/weekly/custom schedules
- **Comprehensive Audit Logging**: Track all deletion operations with detailed metadata
- **Policy Validation**: Built-in validation to prevent dangerous deletions
- **Transaction Safe**: Atomic operations with automatic rollback on errors
- **Multiple Filter Support**: Additional WHERE conditions for granular control

## Quick Start

### Installation

```bash
git clone https://github.com/tensecrocodile/data-retention-deletion-job.git
cd data-retention-deletion-job

pip install -r requirements.txt
```

### Database Setup

```bash
psql -U postgres -d your_database < migrations/init.sql
```

### Configuration

Edit `config/retention_policies.yaml` to define your retention policies:

```yaml
retention_policies:
  - policy_name: "delete_old_logs"
    table_name: "user_logs"
    retention_days: 90
    date_column: "created_at"
    enabled: true
    filter_conditions: "log_level = 'DEBUG'"

  - policy_name: "delete_temp_data"
    table_name: "temp_uploads"
    retention_days: 7
    date_column: "uploaded_at"
    enabled: true
```

### Usage

#### Run with Dry-Run (Preview Only)

```python
from src.job import DataRetentionJob

job = DataRetentionJob(db_url='postgresql://user:pass@localhost/dbname')
job.execute_retention_job(dry_run=True)  # Shows what would be deleted
```

#### Execute Actual Deletion

```python
job.execute_retention_job(dry_run=False)  # Actually deletes records
```

#### Schedule Automated Execution

```python
from src.scheduler import RetentionScheduler
from src.job import DataRetentionJob

job = DataRetentionJob(db_url='postgresql://user:pass@localhost/dbname')
scheduler = RetentionScheduler()

# Schedule daily at 2:00 AM UTC
scheduler.schedule_daily_retention_job(
    job_func=lambda: job.execute_retention_job(dry_run=False),
    hour=2,
    minute=0
)

scheduler.start()
```

## Architecture

### Core Components

1. **DataRetentionJob** (`src/job.py`)
   - Main orchestrator
   - Loads policies from YAML
   - Coordinates retention engine and deletion handler

2. **RetentionEngine** (`src/retention_engine.py`)
   - Evaluates retention policies
   - Calculates cutoff dates
   - Validates policies before execution
   - Counts records matching deletion criteria

3. **DeletionHandler** (`src/deletion_handler.py`)
   - Executes actual DELETE operations
   - Maintains GDPR-compliant audit logs
   - Handles transaction management
   - Supports dry-run mode

4. **RetentionScheduler** (`src/scheduler.py`)
   - APScheduler wrapper
   - Supports daily/weekly/custom schedules
   - Job lifecycle management

### Database Models

**DeletionAuditLog** - Complete audit trail
- `policy_name`: Name of executed policy
- `table_name`: Target table
- `record_count`: Number of deleted records
- `executed_at`: Execution timestamp
- `status`: pending/in_progress/completed/failed
- `error_message`: Error details if failed
- `dry_run`: Whether this was a dry run
- `deleted_by`: User/system that triggered deletion

## Project Structure

```
data-retention-deletion-job/
├── src/
│   ├── job.py                 # Main job orchestrator
│   ├── retention_engine.py     # Policy evaluation
│   ├── deletion_handler.py     # DELETE execution
│   ├── models.py              # SQLAlchemy models
│   ├── audit_log.py           # Audit logging
│   └── scheduler.py           # APScheduler integration
├── config/
│   └── retention_policies.yaml # Policy definitions
├── migrations/
│   └── init.sql              # Database schema
├── tests/
│   ├── test_retention_engine.py
│   ├── test_deletion_handler.py
│   └── test_audit_log.py
├── requirements.txt
├── README.md
└── .gitignore
```

## Configuration Reference

### Retention Policy Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `policy_name` | string | Yes | Unique policy identifier |
| `table_name` | string | Yes | Target table |
| `retention_days` | int | Yes | Delete records older than N days |
| `date_column` | string | Yes | Timestamp column to evaluate |
| `filter_conditions` | string | No | Additional WHERE conditions (JSON) |
| `enabled` | bool | No | Enable/disable policy (default: true) |

## Safety Features

### Dry-Run Mode
Always run new policies with `dry_run=True` first:
```python
job.execute_retention_job(dry_run=True)
```

### Policy Validation
All policies are validated before execution:
- Required fields present
- retention_days is non-negative
- Table and column existence checks

### Audit Trail
Every deletion operation is logged with:
- Policy name and execution time
- Number of records deleted
- SQL filter criteria
- Execution status and errors
- Who/what triggered the deletion

## Running Tests

```bash
pytest tests/ -v
pytest tests/ --cov=src  # With coverage report
```

## Logging

Enable detailed logging:

```python
import logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

## GDPR Compliance

This tool implements the following GDPR requirements:

- **Article 17 (Right to be Forgotten)**: Automated data deletion based on retention policies
- **Article 32 (Security)**: Audit trail for all data deletion operations
- **Data Protection by Design**: Dry-run mode prevents accidental deletions
- **Accountability**: Complete audit log for compliance audits

## Performance Considerations

- Batch deletions during off-peak hours (default: 2 AM UTC)
- Monitor deletion logs for performance impact
- For very large tables, consider partitioning
- Use index on date_column for efficient filtering

## Troubleshooting

### "Policy not found" Error
Ensure the table and column exist in your database.

### "Dry run shows 0 records"
Check that your retention_days and date_column values are correct.

### High Memory Usage
For very large deletions, consider breaking into smaller batches.

## Contributing

Contributions welcome! Please ensure:
- Tests pass: `pytest tests/`
- Code follows PEP 8
- Add tests for new features

## License

MIT License - See LICENSE file for details

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing documentation
- Review audit logs for errors
