# hadoop_lab

## Описание задания
1. Датасет (100000+ строк), 6+ признаков. (минимум 3 типа, хотя бы один категориальный)
2. Развернуть Hadoop, 1 NameNode, 1 DataNode. Загрузить данные в HDFS. Выбрать размер блока. Ограничить используемую память. 
3. Spark Application. Создать app, замерить время и RAM, логировать результаты (ключевые моменты работы с данными, jobs, stages, убрать, WARN, FATAL)
4. Развернуть Hadoop, 1 NameNode, 3+ DataNode. Повторить 3 пункт.
5. Сравнить результаты. (желательно графики)
6. Оптимизировать Spark Application. (параллелизм, кэширование и т.д). (.cache() .persist(), .repartition()). Всего 4 эксперимента. (1 DataNode, Spark) (1 DataNode, Spark Opt) (3 DataNode, Spark) (3 DataNode, Spark Opt).

HELP: https://github.com/Kmohamedalie/Big-Data-Hadoop-Spark-lab/tree/master 

## Запуск hadoop системы