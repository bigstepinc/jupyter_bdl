FROM ubuntu:16.04

ADD entrypoint.sh /
ADD execute-notebook.sh /
ADD password.py /opt/
ADD env.sh /opt/
ADD handlers.py /opt/

RUN apt-get update -y

ENV SPARK_VERSION 2.4.1
ENV BDLCL_VERSION 0.12.1
ENV BLD_CLIENT_PYTHON_VERSION 1.0.0
ENV JUPYTER_NB_MODULE_VERSION 0.3

#Install yarn and NodeJS
RUN apt-get install -y unzip wget curl tar bzip2 software-properties-common git vim gcc openjdk-8-jre
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs
RUN npm install yarn -g

# Install Java 8
ENV JAVA_HOME /usr
ENV PATH $PATH:/usr/bin:/usr/lib:/etc/alternatives:/var/lib/dpkg/alternatives

RUN echo 'export JAVA_HOME="/usr"' >> ~/.bashrc && \
    echo 'export PATH="$PATH:/usr/bin:/usr/lib"' >> ~/.bashrc && \
    bash ~/.bashrc 
    
#Add Java Security Policies
RUN curl -L -C - -b "oraclelicense=accept-securebackup-cookie" -O http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip && \
   unzip jce_policy-8.zip
RUN cp UnlimitedJCEPolicyJDK8/US_export_policy.jar /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security && cp UnlimitedJCEPolicyJDK8/local_policy.jar /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security
RUN rm -rf UnlimitedJCEPolicyJDK8

# Install Spark 2.4.1
RUN cd /opt && wget https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz && \
   tar xzvf /opt/spark-$SPARK_VERSION-bin-hadoop2.7.tgz && \
   rm  /opt/spark-$SPARK_VERSION-bin-hadoop2.7.tgz 
   
# Spark pointers for Jupyter Notebook
ENV SPARK_HOME /opt/spark-$SPARK_VERSION-bin-hadoop2.7

ENV PATH $PATH:/$SPARK_HOME/bin/
ADD core-site.xml.apiKey $SPARK_HOME/conf/
ADD log4j2.xml.default $SPARK_HOME/conf/
ADD hive-site.xml $SPARK_HOME/conf/

# Create additional files in the DataLake
RUN mkdir -p /user && mkdir -p /user/notebooks && mkdir -p /user/datasets && chmod 777 /entrypoint.sh && chmod 777 /execute-notebook.sh

# Setup Miniconda
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH

RUN cd /opt && \
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \ 
    /bin/bash Miniconda3-latest-Linux-x86_64.sh  -b -p $CONDA_DIR && \
     rm -rf Miniconda3-latest-Linux-x86_64.sh

RUN export PATH=$PATH:$CONDA_DIR/bin

# Install Jupyter notebook 
RUN $CONDA_DIR/bin/conda install --yes \
    'notebook>=5.6.0' && \
    $CONDA_DIR/bin/conda clean -yt
    
RUN $CONDA_DIR/bin/jupyter notebook  --generate-config --allow-root
    
#Install Python3 packages
RUN cd /root && $CONDA_DIR/bin/conda install --yes \
    'ipywidgets' \
    'pandas' \
    'matplotlib' \
    'scipy' \
    'seaborn' \
    'scikit-learn' && \
    $CONDA_DIR/bin/conda clean -yt
    
RUN conda install 'python==3.6.7' 

#Install ray and modin
RUN pip install modin && \
   pip install xgboost && \
   pip install lightgbm && \
   pip install py4j && \
   pip install plotly && \
   pip install pyspark==$SPARK_VERSION && \
   pip install featuretools && \
   pip install setproctitle && \
   pip uninstall -y numpy && \
   pip install numpy==1.14 && \
   pip install mleap
   
RUN $CONDA_DIR/bin/conda config --set auto_update_conda False

#Add Getting Started Notebooks and change Jupyter logo and download additional libraries
RUN wget https://repo.lentiq.com/Getting%20Started%20Guide%20%2811%29.ipynb -O /user/notebooks/Getting\ Started\ Guide.ipynb && \
    wget https://repo.lentiq.com/recommender_systems_webinar%20%281%29.ipynb -O /user/notebooks/Recommender\ Systems\ Guide.ipynb && \
    mkdir /user/notebooks/recommender/ && \
    mkdir /user/notebooks/recommender/pictures && \
    wget https://repo.lentiq.com/Recommender-1.jpg -O /user/notebooks/recommender/pictures/Recommender-1.jpg && \
    wget https://repo.lentiq.com/Recommender-2.jpg -O /user/notebooks/recommender/pictures/Recommender-2.jpg && \
    wget https://repo.lentiq.com/Recommender-3.jpg -O /user/notebooks/recommender/pictures/Recommender-3.jpg && \
    wget https://repo.lentiq.com/mleap-0.8.1-py36.patch -O /opt/mleap-0.8.1-py36.patch && \
    patch -p0 -d /opt/conda/lib/python3.6/site-packages/ < /opt/mleap-0.8.1-py36.patch && \
    rm -rf /opt/mleap-0.8.1-py36.patch && \
    wget https://repo.lentiq.com/scikit-learn%20model%20serving%20example.ipynb -O /user/notebooks/Scikit-learn\ model\ training\ example.ipynb && \
    wget https://repo.lentiq.com/pySpark%20model%20serving%20example.ipynb -O /user/notebooks/Pyspark\ model\ training\ example.ipynb && \
    wget https://repo.lentiq.com/update%20serving%20model%20%281%29.ipynb -O /user/notebooks/Update\ serving\ model\ example.ipynb
   
RUN apt-get install -y make

RUN pip install nose pillow

RUN cd /opt && \
    wget https://repo.lentiq.com/bigstepdatalake-$BDLCL_VERSION-bin.tar.gz && \
    tar -xzvf bigstepdatalake-$BDLCL_VERSION-bin.tar.gz && \
    rm -rf /opt/bigstepdatalake-$BDLCL_VERSION-bin.tar.gz && \
    cd /opt/bigstepdatalake-$BDLCL_VERSION/lib/ && \
    wget http://repo.uk.bigstepcloud.com/bigstep/bdl/BDL_libs/libhadoop.so && \
    cp /opt/bigstepdatalake-$BDLCL_VERSION/lib/* $SPARK_HOME/jars/ && \
    export PATH=/opt/bigstepdatalake-$BDLCL_VERSION/bin:$PATH && \
    echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/bigstepdatalake-$BDLCL_VERSION/lib/:$SPARK_HOME/jars/' >> ~/.bashrc && \
    bash ~/.bashrc && \
    pip install http://repo.bigstepcloud.com/lentiq/python-mleap-0.13.tar.gz
    

# Install bdl_notebooks
RUN cd /opt && \
    wget https://repo.lentiq.com/bdl_client_python_$BLD_CLIENT_PYTHON_VERSION.tar.gz && \
    tar -xzvf bdl_client_python_$BLD_CLIENT_PYTHON_VERSION.tar.gz && \
    rm -rf /opt/bdl_client_python_$BLD_CLIENT_PYTHON_VERSION.tar.gz && \
    cd ./bdl_client_python && \
    pip install . && \
    cd .. && \
    rm -rf bdl_client_python && \
    wget https://repo.lentiq.com/jupyter_shared_notebook_module_$JUPYTER_NB_MODULE_VERSION.tar.gz && \
    tar -xzvf jupyter_shared_notebook_module_$JUPYTER_NB_MODULE_VERSION.tar.gz && \
    rm -rf /opt/jupyter_shared_notebook_module_$JUPYTER_NB_MODULE_VERSION.tar.gz && \
    cd ./jupyter_shared_notebook_module && \
    pip install . && \
    cd .. && \
    rm -rf jupyter_shared_notebook_module && \
    jupyter nbextension install --py bdl_notebooks --sys-prefix && \
    jupyter nbextension enable --py bdl_notebooks --sys-prefix && \
    jupyter serverextension enable --py bdl_notebooks --sys-prefix
   
   
#Add Thrift and Metadata support
RUN cd $SPARK_HOME/jars/ && \
   wget http://repo.bigstepcloud.com/bigstep/datalab/hive-schema-1.2.0.postgres.sql && \
   wget http://repo.bigstepcloud.com/bigstep/datalab/hive-txn-schema-0.13.0.postgres.sql && \
   wget http://repo.bigstepcloud.com/bigstep/datalab/hive-txn-schema-0.14.0.postgres.sql && \
   wget https://jdbc.postgresql.org/download/postgresql-9.4.1212.jar -P $SPARK_HOME/jars/ && \
   add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" && \
   wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
   apt-get install -y postgresql-client 
   
ENV PATH /opt/bigstepdatalake-$BDLCL_VERSION/bin:$PATH
   
#        Jupyter 
EXPOSE   8888     

ENTRYPOINT ["/entrypoint.sh"]
