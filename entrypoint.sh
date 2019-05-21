#!/bin/bash

echo 'export SPARK_VERSION=2.4.1' >> ~/.bashrc
echo 'export BDLCL_VERSION=0.12.2' >> ~/.bashrc
echo 'export BLD_CLIENT_PYTHON_VERSION=1.0.0' >> ~/.bashrc
echo 'export JUPYTER_NB_MODULE_VERSION=0.3' >> ~/.bashrc
echo 'export SPARK_HOME="/opt/spark-$SPARK_VERSION-bin-hadoop2.7"'>> ~/.bashrc
echo 'export BDL_HOME="/opt/bigstepdatalake-$BDLCL_VERSION"' >> ~/.bashrc
echo 'export JAVA_HOME="/usr"' >> ~/.bashrc                                                                                                                            
echo 'export PATH="$BDL_HOME/bin:$PATH:/usr/bin:/usr/lib:/opt/hadoop/bin/:/opt/hadoop/sbin/"' >> ~/.bashrc
echo 'export JAVA_CLASSPATH="/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/"' >> ~/.bashrc
echo 'export JAVA_OPTS="-Dsun.security.krb5.debug=true -XX:MetaspaceSize=128M -XX:MaxMetaspaceSize=256M"' >> ~/.bashrc
source  ~/.bashrc 

if [ "$SPARK_UI_PORT" == "" ]; then
  SPARK_UI_PORT=4040
fi

if [ "$NOTEBOOK_DIR" != "" ]; then
	export ESCAPED_PERSISTENT_NB_DIR="${NOTEBOOK_DIR//\//\\/}"
	
	mkdir $NOTEBOOK_DIR/notebooks
	cp -R /user/notebooks/* $NOTEBOOK_DIR/notebooks/

	sed "s/#c.NotebookApp.notebook_dir = ''/c.NotebookApp.notebook_dir = \'$ESCAPED_PERSISTENT_NB_DIR\/notebooks\'/" /root/.jupyter/jupyter_notebook_config.py >> /root/.jupyter/jupyter_notebook_config.py.tmp && \
	mv /root/.jupyter/jupyter_notebook_config.py.tmp /root/.jupyter/jupyter_notebook_config.py
fi

#Commented because of /api/v1/notebooks connection errors
if [ "$DATALAKE_ID" != "" ]; then
	echo "c = get_config()" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.Examples.datalake_id = $DATALAKE_ID" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.Examples.extract_images = False" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.Examples.authorization = '$AUTH_APIKEY'" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.Examples.api_endpoint = '$API_ENDPOINT'" >> /root/.jupyter/jupyter_notebook_config.py
fi

if [ "$PROJECT" != "" ]; then
	sed "s/PROJECT-my-spark-bdl-spark-master.PROJECT.svc.cluster.local/${PROJECT}-my-spark-bdl-spark-master.${PROJECT}.svc.cluster.local/" /lentiq/notebooks/Getting\ Started\ Guide.ipynb >> /lentiq/notebooks/Getting\ Started\ Guide.ipynb.tmp && \
	mv /lentiq/notebooks/Getting\ Started\ Guide.ipynb.tmp /lentiq/notebooks/Getting\ Started\ Guide.ipynb
fi 

#Configure core-site.xml based on the configured authentication method
if [ "$AUTH_METHOD" == "apikey" ]; then
	mv $SPARK_HOME/conf/core-site.xml.apiKey $SPARK_HOME/conf/core-site.xml
	if [ "$AUTH_APIKEY" != "" ]; then
		sed "s/AUTH_APIKEY/$AUTH_APIKEY/" $SPARK_HOME/conf/core-site.xml >> $SPARK_HOME/conf/core-site.xml.tmp && \
		mv $SPARK_HOME/conf/core-site.xml.tmp $SPARK_HOME/conf/core-site.xml
	fi
	if [ "$API_ENDPOINT" != "" ]; then
		sed "s/API_ENDPOINT/${API_ENDPOINT//\//\\/}/" $SPARK_HOME/conf/core-site.xml >> $SPARK_HOME/conf/core-site.xml.tmp && \
		mv $SPARK_HOME/conf/core-site.xml.tmp $SPARK_HOME/conf/core-site.xml
	fi
	if [ "$BDL_DEFAULT_PATH" != "" ]; then
		sed "s/BDL_DEFAULT_PATH/${BDL_DEFAULT_PATH//\//\\/}/" $SPARK_HOME/conf/core-site.xml >> $SPARK_HOME/conf/core-site.xml.tmp && \
		mv $SPARK_HOME/conf/core-site.xml.tmp $SPARK_HOME/conf/core-site.xml
	fi
	#cp $SPARK_HOME/conf/core-site.xml $BDL_HOME/conf/core-site.xml
fi

if [ "$SPARK_WAREHOUSE_DIR" != "" ]; then
	echo "spark.sql.warehouse.dir=${SPARK_WAREHOUSE_DIR}" >> $SPARK_HOME/conf/spark-defaults.conf
	echo "spark.sql.catalogImplementation=hive" >> $SPARK_HOME/conf/spark-defaults.conf
	echo "spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version=2" >> $SPARK_HOME/conf/spark-defaults.conf
fi

if [ "$DB_TYPE" == "postgresql" ]; then
	# Add metadata support
	if [ "$POSTGRES_HOSTNAME" != "" ]; then
		sed "s/POSTGRES_HOSTNAME/$POSTGRES_HOSTNAME/" $SPARK_HOME/conf/hive-site.xml >> $SPARK_HOME/conf/hive-site.xml.tmp && \
		mv $SPARK_HOME/conf/hive-site.xml.tmp $SPARK_HOME/conf/hive-site.xml
	fi

	if [ "$POSTGRES_PORT" != "" ]; then
		sed "s/POSTGRES_PORT/$POSTGRES_PORT/" $SPARK_HOME/conf/hive-site.xml >> $SPARK_HOME/conf/hive-site.xml.tmp && \
		mv $SPARK_HOME/conf/hive-site.xml.tmp $SPARK_HOME/conf/hive-site.xml
	fi
	
	if [ "$DB_NAME" != "" ]; then
		sed "s/SPARK_POSTGRES_DB/$DB_NAME/" $SPARK_HOME/conf/hive-site.xml >> $SPARK_HOME/conf/hive-site.xml.tmp && \
		mv $SPARK_HOME/conf/hive-site.xml.tmp $SPARK_HOME/conf/hive-site.xml
	fi

	if [ "$DB_USER" != "" ]; then
		sed "s/SPARK_POSTGRES_USER/$DB_USER/" $SPARK_HOME/conf/hive-site.xml >> $SPARK_HOME/conf/hive-site.xml.tmp && \
		mv $SPARK_HOME/conf/hive-site.xml.tmp $SPARK_HOME/conf/hive-site.xml
	fi


	if [ "$DYNAMIC_PARTITION_VALUE" != "" ]; then
		sed "s/DYNAMIC_PARTITION_VALUE/$DYNAMIC_PARTITION_VALUE/" $SPARK_HOME/conf/hive-site.xml >> $SPARK_HOME/conf/hive-site.xml.tmp && \
		mv $SPARK_HOME/conf/hive-site.xml.tmp $SPARK_HOME/conf/hive-site.xml
	fi

	if [ "$DYNAMIC_PARTITION_MODE" != "" ]; then
		sed "s/DYNAMIC_PARTITION_MODE/$DYNAMIC_PARTITION_MODE/" $SPARK_HOME/conf/hive-site.xml >> $SPARK_HOME/conf/hive-site.xml.tmp && \
		mv $SPARK_HOME/conf/hive-site.xml.tmp $SPARK_HOME/conf/hive-site.xml
	fi

	if [ "$NR_MAX_DYNAMIC_PARTITIONS" != "" ]; then
		sed "s/NR_MAX_DYNAMIC_PARTITIONS/$NR_MAX_DYNAMIC_PARTITIONS/" $SPARK_HOME/conf/hive-site.xml >> $SPARK_HOME/conf/hive-site.xml.tmp && \
		mv $SPARK_HOME/conf/hive-site.xml.tmp $SPARK_HOME/conf/hive-site.xml
	fi

	if [ "$MAX_DYNAMIC_PARTITIONS_PER_NODE" != "" ]; then
		sed "s/MAX_DYNAMIC_PARTITIONS_PER_NODE/$MAX_DYNAMIC_PARTITIONS_PER_NODE/" $SPARK_HOME/conf/hive-site.xml >> $SPARK_HOME/conf/hive-site.xml.tmp && \
		mv $SPARK_HOME/conf/hive-site.xml.tmp $SPARK_HOME/conf/hive-site.xml
	fi

	sed "s/SPARK_POSTGRES_PASSWORD/$DB_PASSWORD/" $SPARK_HOME/conf/hive-site.xml >> $SPARK_HOME/conf/hive-site.xml.tmp && \
	mv $SPARK_HOME/conf/hive-site.xml.tmp $SPARK_HOME/conf/hive-site.xml

	cd $SPARK_HOME/jars

	export PGPASSWORD=$DB_PASSWORD

	psql -h $POSTGRES_HOSTNAME -p $POSTGRES_PORT  -U  $DB_USER -d $DB_NAME -f $SPARK_HOME/jars/hive-schema-1.2.0.postgres.sql
fi


#Configure log4j2 for bdlcl logs
touch $SPARK_HOME/conf/log4j2.xml
mv $SPARK_HOME/conf/log4j2.xml.default $SPARK_HOME/conf/log4j2.xml

if [ "$MODE" == "" ]; then
MODE=$1
fi

if [ "$MODE" == "jupyter" ]; then 

	export pass=$(python /opt/password.py  $NOTEBOOK_PASSWORD)
	sed "s/#c.NotebookApp.password = ''/c.NotebookApp.password = \'$pass\'/" /root/.jupyter/jupyter_notebook_config.py >> /root/.jupyter/jupyter_notebook_config.py.tmp && \
	mv /root/.jupyter/jupyter_notebook_config.py.tmp /root/.jupyter/jupyter_notebook_config.py

fi

rm -rf /opt/spark-$SPARK_VERSION-bin-hadoop2.7/jars/guava-14.0.1.jar

#Fix python file/directory not found issues
rm -rf /usr/bin/python
ln -s /opt/conda/bin/python3.6 /usr/bin/python

mkdir /tmp/hive
chmod -R 777 /tmp/hive 

rm -rf /opt/bigstepdatalake-$BDLCL_VERSION/conf/core-site.xml
cp /opt/spark-$SPARK_VERSION-bin-hadoop2.7/conf/core-site.xml /opt/bigstepdatalake-$BDLCL_VERSION/conf/

rm -rf /lentiq/notebooks/ml-latest-small.zip

#remove excessive logging from bdl script
cp $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh
echo 'export HADOOP_OPTS="$HADOOP_OPTS -Djava.library.path=/opt/bigstepdatalake-$BDLCL_VERSION/lib"' >> $SPARK_HOME/conf/spark-env.sh
touch $BDL_HOME/conf/logging.properties
echo ".level = SEVERE" >> $BDL_HOME/conf/logging.properties


if [[ "$MODE" == "jupyter" && "$SPARK_PUBLIC_DNS" == "" ]]; then 
	/execute-notebook.sh &
	jupyter notebook --ip=0.0.0.0 --log-level DEBUG --allow-root --NotebookApp.iopub_data_rate_limit=10000000000 
elif [[ "$MODE" == "codeblock" ]]; then 
	echo "codeblock"
else
	echo "none"
fi
