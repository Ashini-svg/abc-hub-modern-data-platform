# ABC Hub Modern Data Platform

A PostgreSQL and Apache NiFi ETL project that transforms ABC Hub operational data into analytics-ready dimensional models for reporting.

## Project Overview

ABC Hub is a combined digital streaming and physical media rental business. Its operational database supports day-to-day transactions, but analytical reporting requires data from several business processes to be cleaned, integrated, enriched, and aggregated.

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

## Source Data

The ABC Hub operational dataset and operational database DDL were provided as part of the Zuu Crew course materials.

Because those materials come from a private course package, they are **not redistributed in this public repository**.

The public repository contains my implementation work, including:

- the Apache NiFi flow definition
- the analytical PostgreSQL schema
- SQL used inside NiFi processors
- validation queries
- supporting Python script
- execution and validation screenshots

To reproduce the complete pipeline, the original ABC Hub operational source package must be available locally.

## Running the Project

1. Prepare and load the supplied ABC Hub operational PostgreSQL source database.
2. Create the analytical database using:
   - `sql/00_create_database.sql`
3. Create the analytical schema using:
   - `sql/01_analytical_schema.sql`
4. Import:
   - `nifi/ABC_Hub_ETL_Pipeline.json`
5. Configure local PostgreSQL credentials and the PostgreSQL JDBC driver path in NiFi.
6. Run the ETL pipeline.
7. Execute:
   - `sql/validation_queries.sql`
   to verify the analytical results.

## Security

No passwords, API keys, tokens, `.env` files, or private credentials are included in this repository.

Environment-specific database credentials and JDBC paths must be configured locally.

## Author

**Ashini Samarasinha**

GitHub: [Ashini-svg](https://github.com/Ashini-svg)  
LinkedIn: [Ashini Samarasingha](https://www.linkedin.com/in/ashini-samarasingha-a65432316/)
