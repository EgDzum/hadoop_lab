from pyspark.sql import SparkSession
import pyspark.sql.functions as F
from pyspark.sql import Window
import os
import time
from datetime import datetime
import json

# Исправленная функция для логирования времени
def log_metrics(stage_name, start_time=None):
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    if start_time is None:
        return time.time()  # Возвращаем время начала для следующего вызова

    duration = time.time() - start_time
    print(f"[{current_time}] {stage_name} - Duration: {duration:.2f}s")
    return duration 


def pipeline(spark, number):
    results = {}

    # Чтение данных
    df = spark.read.csv('apps/bank_transactions (1).csv', header=True)
    print(f"Partitions after read: {df.rdd.getNumPartitions()}") 

    # Парсинг дат (раньше для оптимизации)
    df = df.withColumn("TransactionDate", F.to_date(F.col("TransactionDate"), "d/M/yy"))

    # Фильтрация положительных транзакций (раньше, чтобы уменьшить данные)
    start = log_metrics("Filtered df")
    df_filtered = df.filter(F.col("TransactionAmount (INR)").cast("float") > 0)
    results['Filtration'] = log_metrics("Filtration df", start)
    df_filtered = df_filtered.repartition(5).cache()  # Кэшируем отфильтрованные данные
    print(f"Rows after filter: {df_filtered.count()}")

    # Сумма по локациям (используем отфильтрованные)
    start_agg = log_metrics("Start location aggregation")
    df_amount_per_loc = (
        df_filtered.groupBy('CustLocation')
        .agg(F.sum('TransactionAmount (INR)').alias('Gen_TransactionAmount'))
        .sort(F.desc('Gen_TransactionAmount'))
    )
    results["Total sum Aggregation"] = log_metrics("Location agg done", start_time=start_agg)

    # Window для максимальной транзакции по дню
    window = Window.partitionBy('TransactionDate').orderBy(F.desc('TransactionAmount (INR)'))
    start_window = log_metrics("Start daily max trans")
    df_largest_trans_per_day = (
        df_filtered
        .withColumn('BiggestTrans', F.first_value('TransactionAmount (INR)').over(window))
        .filter(F.col('TransactionAmount (INR)') == F.col('BiggestTrans'))
        .drop(F.col('BiggestTrans'))
        .sort('TransactionDate')
    )
    results["Daily max transaction"] = log_metrics("Daily max trans done", start_time=start_window)

    print(f"Total positive transactions: {df_largest_trans_per_day.count()}")

    # Очистка
    df_filtered.unpersist()

    # Проверим, существует ли папка с экспериментами
    os.makedirs("experiments", exist_ok=True)

    with open(f'experiments/experiment_metrics_opt_{number}.json', 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)


if __name__ == '__main__':
    # Создание Spark сессии
    spark = (
        SparkSession.builder
        .appName("Optimized PySpark Bank Analysis")
        .master("local[4]")
        .config("spark.executor.memory", "1g")
        .config("spark.executor.cores", "2")
        .config("spark.sql.adaptive.enabled", "true")
        .config("spark.sql.adaptive.coalescePartitions.enabled", "true")
        .getOrCreate()
        )
    
    # Подавление WARN и FATAL логов
    spark.sparkContext.setLogLevel("ERROR")

    # Проверка подключения
    print(f"Spark Version: {spark.version}")
    print(f"Spark Master: {spark.sparkContext.master}")
    print(f"Available cores: {spark.sparkContext.defaultParallelism}")
    print("Spark UI: http://localhost:9090 (мониторинг jobs/stages)")

    for number in range(5):
        pipeline(spark, number)

    # Завершение
    spark.stop()