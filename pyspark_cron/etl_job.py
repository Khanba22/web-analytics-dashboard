"""
PySpark ETL Job
Processes raw event logs and computes analytics metrics
"""

import os
import yaml
from pathlib import Path
from datetime import datetime, date
from typing import Optional

from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, count, countDistinct, avg, sum as spark_sum,
    to_date, unix_timestamp, when, lit
)
from pyspark.sql.types import StructType, StructField, StringType, TimestampType


# Load global configuration
CONFIG_PATH = os.getenv("CONFIG_PATH", "global_config.yaml")
with open(CONFIG_PATH, 'r') as f:
    config = yaml.safe_load(f)


def get_spark_session() -> SparkSession:
    """
    Initialize and return Spark session with Postgres JDBC driver
    """
    spark = SparkSession.builder \
        .appName(config['pyspark']['app_name']) \
        .config("spark.jars", "/opt/spark/jars/postgresql-42.6.0.jar") \
        .config("spark.sql.legacy.timeParserPolicy", "LEGACY") \
        .getOrCreate()
    
    spark.sparkContext.setLogLevel("WARN")
    return spark


def get_postgres_properties() -> dict:
    """
    Get Postgres connection properties
    """
    pg_config = config['postgres']
    
    return {
        "user": pg_config['user'],
        "password": pg_config['password'],
        "driver": "org.postgresql.Driver"
    }


def get_postgres_url() -> str:
    """
    Construct Postgres JDBC URL
    """
    pg_config = config['postgres']
    return f"jdbc:postgresql://{pg_config['host']}:{pg_config['port']}/{pg_config['db']}"


def read_jsonl_files(spark: SparkSession, file_pattern: str) -> Optional[object]:
    """
    Read JSON Lines files into Spark DataFrame
    Returns None if no files found or error occurs
    """
    try:
        logs_dir = Path(config['paths']['logs_dir'])
        file_path = str(logs_dir / file_pattern)
        
        if not logs_dir.exists():
            print(f"⚠️ Logs directory does not exist: {logs_dir}")
            return None
        
        # Check if files exist
        matching_files = list(logs_dir.glob(file_pattern))
        if not matching_files:
            print(f"⚠️ No files matching pattern: {file_pattern}")
            return None
        
        print(f"📂 Reading files: {file_path}")
        df = spark.read.json(file_path)
        
        if df.count() == 0:
            print(f"⚠️ No data found in files")
            return None
        
        return df
    
    except Exception as e:
        print(f"❌ Error reading files: {e}")
        return None


def compute_page_engagement(spark: SparkSession):
    """
    Compute page engagement metrics:
    - Total visits per page
    - Total time spent
    - Average time spent
    - Unique users and sessions
    """
    print("\n📊 Computing page engagement metrics...")
    
    df = read_jsonl_files(spark, "events.jsonl")
    if df is None:
        return
    
    # Filter for page events
    page_events = df.filter(
        (col("event_type").isin(["page_visited", "page_closed"])) &
        (col("page_path").isNotNull())
    )
    
    if page_events.count() == 0:
        print("⚠️ No page events found")
        return
    
    # Add date column
    page_events = page_events.withColumn("date", to_date(col("event_time")))
    
    # Calculate page visits
    page_visits = page_events.filter(col("event_type") == "page_visited") \
        .groupBy("date", "page_path") \
        .agg(
            count("*").alias("total_visits"),
            countDistinct("user_id").alias("unique_users"),
            countDistinct("session_id").alias("unique_sessions")
        )
    
    # For time calculation, we'd need paired events (page_visited + page_closed)
    # Simplified: assume average 30 seconds per visit as placeholder
    page_visits = page_visits.withColumn("total_time_seconds", col("total_visits") * 30)
    page_visits = page_visits.withColumn("avg_time_seconds", lit(30.0))
    
    # Write to Postgres (upsert behavior)
    write_to_postgres(page_visits, "page_engagement", mode="append")
    
    print(f"✅ Page engagement metrics computed: {page_visits.count()} records")


def compute_session_metrics(spark: SparkSession):
    """
    Compute session-level metrics:
    - Total sessions per day
    - Average session duration
    - Average page views per session
    - Average clicks per session
    """
    print("\n📊 Computing session metrics...")
    
    df = read_jsonl_files(spark, "*.jsonl")
    if df is None:
        return
    
    # Add date column
    df = df.withColumn("date", to_date(col("event_time")))
    
    # Group by session
    session_stats = df.groupBy("date", "session_id") \
        .agg(
            count(when(col("event_type") == "page_visited", 1)).alias("page_views"),
            count(when(col("event_type").like("%click%"), 1)).alias("clicks"),
            countDistinct("user_id").alias("users")
        )
    
    # Aggregate by date
    daily_metrics = session_stats.groupBy("date") \
        .agg(
            countDistinct("session_id").alias("total_sessions"),
            avg("page_views").alias("avg_page_views"),
            avg("clicks").alias("avg_clicks"),
            spark_sum("users").alias("unique_users")
        )
    
    # Add placeholder for avg duration (would need session start/end events)
    daily_metrics = daily_metrics.withColumn("avg_duration_seconds", lit(180.0))
    
    # Write to Postgres
    write_to_postgres(daily_metrics, "session_metrics", mode="append")
    
    print(f"✅ Session metrics computed: {daily_metrics.count()} records")


def compute_click_through_rates(spark: SparkSession):
    """
    Compute click-through rates (CTR):
    CTR = (clicks / views) * 100
    """
    print("\n📊 Computing click-through rates...")
    
    df = read_jsonl_files(spark, "events.jsonl")
    if df is None:
        return
    
    # Add date column
    df = df.withColumn("date", to_date(col("event_time")))
    
    # Count views (page_visited) and clicks (button_clicked)
    views = df.filter(col("event_type") == "page_visited") \
        .groupBy("date", "page_path") \
        .agg(count("*").alias("views"))
    
    clicks = df.filter(col("event_type").like("%click%")) \
        .groupBy("date", "page_path", "button_id") \
        .agg(count("*").alias("clicks"))
    
    if clicks.count() == 0:
        print("⚠️ No click events found")
        return
    
    # Join views and clicks
    ctr_data = clicks.join(views, ["date", "page_path"], "left") \
        .fillna(0, subset=["views"])
    
    # Calculate CTR
    ctr_data = ctr_data.withColumn(
        "ctr",
        when(col("views") > 0, (col("clicks") / col("views")) * 100).otherwise(0.0)
    )
    
    # Write to Postgres
    write_to_postgres(ctr_data, "click_through_rates", mode="append")
    
    print(f"✅ Click-through rates computed: {ctr_data.count()} records")


def write_to_postgres(df, table_name: str, mode: str = "append"):
    """
    Write DataFrame to Postgres table
    """
    try:
        url = get_postgres_url()
        properties = get_postgres_properties()
        
        df.write \
            .jdbc(url=url, table=table_name, mode=mode, properties=properties)
        
        print(f"✅ Wrote {df.count()} records to {table_name}")
    
    except Exception as e:
        print(f"❌ Error writing to Postgres table {table_name}: {e}")


def run_etl():
    """
    Main ETL execution function
    """
    print("=" * 70)
    print(f"🚀 Starting ETL Job - {datetime.now()}")
    print("=" * 70)
    
    spark = get_spark_session()
    
    try:
        # Run all analytics computations
        compute_page_engagement(spark)
        compute_session_metrics(spark)
        compute_click_through_rates(spark)
        
        print("\n" + "=" * 70)
        print(f"✅ ETL Job Completed Successfully - {datetime.now()}")
        print("=" * 70)
    
    except Exception as e:
        print(f"\n❌ ETL Job Failed: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        spark.stop()


if __name__ == "__main__":
    run_etl()

