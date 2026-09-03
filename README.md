# ABC Hub Modern Data Platform

A PostgreSQL and Apache NiFi ETL project that transforms ABC Hub operational data into analytics-ready dimensional models for reporting.

## Project Overview

ABC Hub is a combined digital streaming and physical media rental business. The operational database supports day-to-day transactions, but analytical reporting requires data from several business processes to be cleaned, integrated and aggregated.

This project builds an analytical data platform using PostgreSQL and Apache NiFi.

## Architecture

```text
ABC Hub Operational PostgreSQL
            |
            v
      Apache NiFi ETL
            |
            v
ABC Hub Analytical PostgreSQL
            |
            v
   Analytics / Reporting
```

## Analytical Model

### Dimensions

- `dim_date`
- `dim_customer`
- `dim_content`
- `dim_inventory`

### Fact Tables

- `fact_customer_daily_activity`
- `fact_content_monthly_performance`
- `fact_inventory_daily_utilisation`

## ETL Features

- Incremental extraction using `updated_at` where appropriate
- Customer data cleansing and duplicate management
- Content and inventory enrichment
- Daily and monthly analytical aggregations
- Surrogate-key lookups before fact loading
- UPSERT-based idempotent loading
- Centralised NiFi failure handling
- Scheduled dimension-before-fact execution
- PostgreSQL validation queries

## Final Analytical Results

| Table | Rows |
|---|---:|
| `dim_date` | 730 |
| `dim_customer` | 1,000 |
| `dim_content` | 600 |
| `dim_inventory` | 1,785 |
| `fact_customer_daily_activity` | 62,686 |
| `fact_content_monthly_performance` | 7,099 |
| `fact_inventory_daily_utilisation` | 862,061 |

Validation confirmed zero duplicate rows at the defined grains of all three fact tables.

## Technology Stack

- Apache NiFi 2.11.0
- PostgreSQL 18.x
- SQL
- Python
- OpenJDK 21
- PostgreSQL JDBC 42.7.13
- DataGrip

## Repository Structure

```text
.
├── nifi/
│   └── ABC_Hub_ETL_Pipeline.json
├── sql/
│   ├── operational_schema.sql
│   ├── 00_create_database.sql
│   ├── 01_analytical_schema.sql
│   ├── nifi_processor_queries.sql
│   └── validation_queries.sql
├── scripts/
│   └── prepare_source_data.py
├── screenshots/
│   ├── 01_completed_nifi_workflow.png
│   ├── 02_successful_etl_execution.png
│   ├── 03_analytical_table_counts.png
│   ├── 04_duplicate_grain_validation.png
│   └── 05_inventory_business_rule_validation.png
└── README.md
```

## Security

No passwords, API keys, tokens or `.env` credentials are included in this repository. Environment-specific database credentials and JDBC paths must be configured locally.

## Author

Ashini Samarasinha  
GitHub: Ashini-svg
