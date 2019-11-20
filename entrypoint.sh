#!/bin/bash

echo 'export SPARK_VERSION=2.4.1' >> ~/.bashrc
echo 'export BDLCL_VERSION=0.13.3' >> ~/.bashrc
echo 'export BLD_CLIENT_PYTHON_VERSION=1.0.0' >> ~/.bashrc
echo 'export JUPYTER_NB_MODULE_VERSION=0.3' >> ~/.bashrc
echo 'export HADOOP_VERSION=2.9.2' >> ~/.bashrc
echo 'export SPARK_HOME="/opt/spark-$SPARK_VERSION-bin-custom-hadoop$HADOOP_VERSION"'>> ~/.bashrc
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
	echo "from jupyterbdlcm.manager import BDLContentsManager" >> /root/.jupyter/jupyter_notebook_config.py
	echo "from jupyterbdlcm.local_checkpoints import LocalBDLCheckpoints" >> /root/.jupyter/jupyter_notebook_config.py
	
	echo "c = get_config()" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.Examples.datalake_id = $DATALAKE_ID" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.Examples.extract_images = False" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.Examples.authorization = '$AUTH_APIKEY'" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.Examples.api_endpoint = '$API_ENDPOINT'" >> /root/.jupyter/jupyter_notebook_config.py
	
	echo "c.NotebookApp.allow_origin = '*' #Basic permission" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.NotebookApp.disable_check_xsrf = True #Otherwise Jupyter restricts you modifying the Iframed Notebook" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.NotebookApp.trust_xheaders = True #May or may not make a difference to you" >> /root/.jupyter/jupyter_notebook_config.py

	echo "c.NotebookApp.tornado_settings = {" >> /root/.jupyter/jupyter_notebook_config.py
	echo "    'headers': {" >> /root/.jupyter/jupyter_notebook_config.py
	echo "        'Content-Security-Policy': \"frame-ancestors 'self' http://127.0.0.1:5000/ http://127.0.0.1:5000/*\"," >> /root/.jupyter/jupyter_notebook_config.py
	echo "    }" >> /root/.jupyter/jupyter_notebook_config.py
	echo "}" >> /root/.jupyter/jupyter_notebook_config.py
	
	echo "c.NotebookApp.contents_manager_class = BDLContentsManager" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.ContentsManager.checkpoints_class = LocalBDLCheckpoints" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.BDLContentsManager.datapool_name = '$DATAPOOL_NAME'" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.BDLContentsManager.project_name = '$PROJECT'" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.BDLContentsManager.authorization = '$AUTH_APIKEY'" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.BDLContentsManager.api_endpoint = '$API_ENDPOINT'" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.BDLCheckpoints.datapool_name = '$DATAPOOL_NAME'" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.BDLCheckpoints.project_name = '$PROJECT'" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.BDLCheckpoints.authorization = '$AUTH_APIKEY'" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.BDLCheckpoints.api_endpoint = '$API_ENDPOINT'" >> /root/.jupyter/jupyter_notebook_config.py
fi 

if [ "$PROJECT" != "" ]; then
	sed "s/PROJECT-my-spark-bdl-spark-master.PROJECT.svc.cluster.local/${PROJECT}-my-spark-bdl-spark-master.${PROJECT}.svc.cluster.local/" /lentiq/notebooks/Getting\ Started\ Guide.ipynb >> /lentiq/notebooks/Getting\ Started\ Guide.ipynb.tmp && \
	mv /lentiq/notebooks/Getting\ Started\ Guide.ipynb.tmp /lentiq/notebooks/Getting\ Started\ Guide.ipynb
fi 

#update settings needed for code block
if [ "$BDL_AUTH_METHOD" != "" ]; then
	export AUTH_METHOD=$BDL_AUTH_METHOD
fi

if [ "$BDL_AUTH_APIKEY" != "" ]; then
	export AUTH_APIKEY=$BDL_AUTH_APIKEY
fi

if [ "$BDL_API_ENDPOINT" != "" ]; then
	export API_ENDPOINT=$BDL_API_ENDPOINT
fi

if [ "$BDL_SPARK_WAREHOUSE_DIR" != "" ]; then
	export SPARK_WAREHOUSE_DIR=$BDL_SPARK_WAREHOUSE_DIR
fi

if [ "$BDL_MODE" != "" ]; then
	export MODE=$BDL_MODE
fi

if [ "$BDL_NOTEBOOK_DIR" != "" ]; then
	export NOTEBOOK_DIR=$BDL_NOTEBOOK_DIR
fi

if [ "$BDL_DB_TYPE" != "" ]; then
	export DB_TYPE=$BDL_DB_TYPE
fi

if [ "$BDL_POSTGRES_HOSTNAME" != "" ]; then
	export POSTGRES_HOSTNAME=$BDL_POSTGRES_HOSTNAME
fi

if [ "$BDL_POSTGRES_PORT" != "" ]; then
	export POSTGRES_PORT=$BDL_POSTGRES_PORT
fi

if [ "$BDL_DB_NAME" != "" ]; then
	export DB_NAME=$BDL_DB_NAME
fi

if [ "$BDL_DB_USER" != "" ]; then
	export DB_USER=$BDL_DB_USER
fi

if [ "$BDL_DB_PASSWORD" != "" ]; then
	export DB_PASSWORD=$BDL_DB_PASSWORD
fi

if [ "$DYNAMIC_PARTITION_VALUE" == "" ]; then
  DYNAMIC_PARTITION_VALUE=`true`
fi

if [ "$DYNAMIC_PARTITION_MODE" == "" ]; then
  DYNAMIC_PARTITION_MODE=`nonstrict`
fi

if [ "$NR_MAX_DYNAMIC_PARTITIONS" == "" ]; then
  NR_MAX_DYNAMIC_PARTITIONS=1000
fi

if [ "$MAX_DYNAMIC_PARTITIONS_PER_NODE" == "" ]; then
  MAX_DYNAMIC_PARTITIONS_PER_NODE=100
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
fi

if [ "$SPARK_WAREHOUSE_DIR" != "" ]; then
	echo "spark.sql.warehouse.dir=${SPARK_WAREHOUSE_DIR}" >> $SPARK_HOME/conf/spark-defaults.conf
	echo "spark.sql.catalogImplementation=hive" >> $SPARK_HOME/conf/spark-defaults.conf
	echo "spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version=2" >> $SPARK_HOME/conf/spark-defaults.conf
	echo "spark.sql.hive.metastore.jars=maven" >> $SPARK_HOME/conf/spark-defaults.conf
	echo "spark.sql.hive.metastore.version=2.3.0" >> $SPARK_HOME/conf/spark-defaults.conf
	echo "spark.sql.legacy.allowCreatingManagedTableUsingNonemptyLocation=true" >> $SPARK_HOME/conf/spark-defaults.conf
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
fi


#Configure log4j2 for bdlcl logs
touch $SPARK_HOME/conf/log4j2.xml
mv $SPARK_HOME/conf/log4j2.xml.default $SPARK_HOME/conf/log4j2.xml

if [ "$MODE" == "" ]; then
MODE=$1
fi

if [ "$MODE" == "jupyter" ]; then 
	echo "c.NotebookApp.token='$NOTEBOOK_TOKEN'" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.NotebookApp.ip = '0.0.0.0'" >> /root/.jupyter/jupyter_notebook_config.py
fi

rm -rf /opt/spark-$SPARK_VERSION-bin-custom-hadoop$HADOOP_VERSION/jars/guava-14.0.1.jar

#Fix python not found file/directory issues
rm -rf /usr/bin/python
ln -s /usr/local/bin/python3.6 /usr/bin/python

rm -rf /opt/bigstepdatalake-$BDLCL_VERSION/conf/core-site.xml
cp /opt/spark-$SPARK_VERSION-bin-custom-hadoop$HADOOP_VERSION/conf/core-site.xml /opt/bigstepdatalake-$BDLCL_VERSION/conf/

mkdir /root/.ivy2
mkdir /root/.ivy2/jars
touch /root/.ivy2/jars/org.apache.zookeeper_zookeeper-3.4.6.jar
cp $SPARK_HOME/jars/zookeeper-3.4.6.jar /root/.ivy2/jars/org.apache.zookeeper_zookeeper-3.4.6.jar

mkdir /tmp/hive 
chmod -R 777 /tmp/hive

rm -rf /lentiq/notebooks/ml-latest-small.zip

#remove excessive logging from bdl script
cp $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh
echo 'export HADOOP_OPTS="$HADOOP_OPTS -Djava.library.path=/opt/bigstepdatalake-$BDLCL_VERSION/lib"' >> $SPARK_HOME/conf/spark-env.sh
touch /opt/bigstepdatalake-$BDLCL_VERSION/conf/logging.properties
echo ".level = SEVERE" >> /opt/bigstepdatalake-$BDLCL_VERSION/conf/logging.properties

cd /lentiq/notebooks

if [[ "$MODE" == "jupyter" && "$SPARK_PUBLIC_DNS" == "" ]]; then 
	/execute-notebook.sh &
	jupyter notebook --log-level DEBUG --allow-root --NotebookApp.iopub_data_rate_limit=10000000000 
elif [[ "$MODE" == "codeblock" ]]; then 
	echo "codeblock"
else
	echo "none"
fi
