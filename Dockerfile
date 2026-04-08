FROM python:3.11.7-bullseye

ARG SPARK_VERSION=3.3.1
ARG HADOOP_VERSION=3.3.5

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sudo \
    curl \
    vim \
    unzip \
    rsync \
    openjdk-11-jdk \
    build-essential \
    software-properties-common \
    ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
ENV HADOOP_HOME=${HADOOP_HOME:-"/opt/hadoop"}
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

RUN mkdir -p ${HADOOP_HOME} && mkdir -p ${SPARK_HOME} && mkdir -p ${SPARK_HOME}/spark-events
WORKDIR ${SPARK_HOME}

ENV PATH=$JAVA_HOME/bin:$PATH

RUN curl -L -o spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" \
    && tar xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
    && rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Download and install Hadoop
RUN wget https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt/ && \
    mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    rm hadoop-${HADOOP_VERSION}.tar.gz && 

COPY requirements.txt ./
RUN pip3 install -r requirements.txt

ENV PATH="$SPARK_HOME/sbin:$SPARK_HOME/bin:${PATH}"
ENV PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:${PATH}"
ENV SPARK_MASTER="spark://spark-master:7077"
ENV SPARK_MASTER_HOST spark-master
ENV SPARK_MASTER_PORT 7077
ENV PYSPARK_PYTHON python3
ENV HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"

ENV LD_LIBRARY_PATH="$HADOOP_HOME/lib/native:${LD_LIBRARY_PATH}"

ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"

COPY spark-defaults.conf $SPARK_HOME/conf/
COPY hadoop_settings/*.xml $HADOOP_CONF_DIR
COPY entrypoint.sh /opt/spark/entrypoint.sh
COPY apps/* ${SPARK_HOME}/apps/

RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa \
    && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys \
    && chmod 0600 ~/.ssh/authorized_keys

RUN chmod u+x /opt/spark/sbin/* && \
    chmod u+x /opt/spark/bin/*

ENV PYTHONPATH=$SPARK_HOME/python/:$PYTHONPATH

RUN chmod +x /opt/spark/entrypoint.sh

ENTRYPOINT ["/opt/spark/entrypoint.sh"]