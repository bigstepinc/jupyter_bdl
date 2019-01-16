#!/bin/bash

echo 'export SPARK_HOME="/opt/spark-2.4.0-bin-hadoop2.7"'>> ~/.bashrc
echo 'export BDL_HOME="/opt/bigstepdatalake-0.10.3"' >> ~/.bashrc
echo 'export JAVA_HOME="/opt/jdk1.8.0_202/"' >> ~/.bashrc                                                                                                                            
echo 'export PATH="$BDL_HOME/bin:$PATH:/opt/jdk1.8.0_202/bin:/opt/jdk1.8.0_202/jre/bin:/opt/hadoop/bin/:/opt/hadoop/sbin/"' >> ~/.bashrc
echo 'export JAVA_CLASSPATH="$JAVA_HOME/jre/lib/"' >> ~/.bashrc
echo 'export JAVA_OPTS="-Dsun.security.krb5.debug=true -XX:MetaspaceSize=128M -XX:MaxMetaspaceSize=256M"' >> ~/.bashrc
bash >> ~/.bashrc 

if [ "$SPARK_UI_PORT" == "" ]; then
  SPARK_UI_PORT=4040
fi

if [ "$NOTEBOOK_DIR" != "" ]; then
	export ESCAPED_PERSISTENT_NB_DIR="${NOTEBOOK_DIR//\//\\/}"
	
	mkdir $NOTEBOOK_DIR/notebooks
	cp /user/notebooks/* $NOTEBOOK_DIR/notebooks/

	sed "s/#c.NotebookApp.notebook_dir = ''/c.NotebookApp.notebook_dir = \'$ESCAPED_PERSISTENT_NB_DIR\/notebooks\'/" /root/.jupyter/jupyter_notebook_config.py >> /root/.jupyter/jupyter_notebook_config.py.tmp && \
	mv /root/.jupyter/jupyter_notebook_config.py.tmp /root/.jupyter/jupyter_notebook_config.py
	
fi

#Commented because of /api/v1/notebooks connection errors
if [ "$DATALAKE_ID" != "" ]; then
	echo "c = get_config()" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.Examples.datalake_id = '$DATALAKE_ID'" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.Examples.extract_images = False" >> /root/.jupyter/jupyter_notebook_config.py
	echo "c.Examples.authorization = '$AUTH_APIKEY'" >> /root/.jupyter/jupyter_notebook_config.py
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
	cp $SPARK_HOME/conf/core-site.xml $BDL_HOME/conf/core-site.xml
fi

#Configure log4j2 for bdlcl logs
mv $SPARK_HOME/conf/log4j2.xml.default $SPARK_HOME/conf/log4j2.xml

if [ "$MODE" == "" ]; then
MODE=$1
fi

if [ "$MODE" == "jupyter" ]; then 
	# Change the Home Icon 
	#sed "s/<i class=\"fa fa-home\"><\/i>/\/user/" /opt/conda/envs/python3/lib/python3.5/site-packages/notebook/templates/tree.html >> /opt/conda/envs/python3/lib/python3.5/site-packages/notebook/templates/tree.html.tmp
	#mv /opt/conda/envs/python3/lib/python3.5/site-packages/notebook/templates/tree.html.tmp /opt/conda/envs/python3/lib/python3.5/site-packages/notebook/templates/tree.html
	
	# export NOTEBOOK_PASSWORD=$(cat $NOTEBOOK_SECRETS_PATH/NOTEBOOK_PASSWORD)

	export pass=$(python /opt/password.py  $NOTEBOOK_PASSWORD)
	sed "s/#c.NotebookApp.password = ''/c.NotebookApp.password = \'$pass\'/" /root/.jupyter/jupyter_notebook_config.py >> /root/.jupyter/jupyter_notebook_config.py.tmp && \
	mv /root/.jupyter/jupyter_notebook_config.py.tmp /root/.jupyter/jupyter_notebook_config.py

	#Install sparkmonitor extension
	#export SPARKMONITOR_UI_HOST=$SPARK_PUBLIC_DNS
	#export SPARKMONITOR_UI_PORT=$SPARK_UI_PORT
fi

rm -rf /opt/spark-2.4.0-bin-hadoop2.7/jars/guava-14.0.1.jar

if [[ "$MODE" == "jupyter" && "$SPARK_PUBLIC_DNS" == "" ]]; then 
	jupyter notebook --ip=0.0.0.0 --log-level DEBUG --allow-root --NotebookApp.iopub_data_rate_limit=10000000000 
else
	jupyter notebook --ip=0.0.0.0 --log-level DEBUG --allow-root --NotebookApp.iopub_data_rate_limit=10000000000 --Spark.url="http://$SPARK_PUBLIC_DNS:$SPARK_UI_PORT"
fi
