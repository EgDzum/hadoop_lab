#!/bin/bash

SPARK_WORKLOAD=$1

echo "SPARK_WORKLOAD: $SPARK_WORKLOAD"

# Shared HDFS name dir (use volume for persistence)
NAMEDIR="/hadoop/dfs/name"

if [ "$SPARK_WORKLOAD" == "master" ]; then
  # Format only if empty
  if [ ! -e "$NAMEDIR/current/VERSION" ]; then
    $HADOOP_HOME/bin/hdfs namenode -format
  fi

  $HADOOP_HOME/bin/hdfs --daemon start namenode
  $HADOOP_HOME/bin/hdfs --daemon start secondarynamenode
  $HADOOP_HOME/bin/yarn --daemon start resourcemanager  # Use yarn daemon

  $HADOOP_HOME/bin/hdfs dfs -mkdir -p /opt/spark/spark-events
  echo "Created /opt/spark/spark-events hdfs dir"

elif [ "$SPARK_WORKLOAD" == "worker" ]; then
  # NO namenode format here!
  $HADOOP_HOME/bin/hdfs --daemon start datanode
  $HADOOP_HOME/bin/yarn --daemon start nodemanager

elif [ "$SPARK_WORKLOAD" == "history" ]; then
  $SPARK_HOME/sbin/start-history-server.sh
fi