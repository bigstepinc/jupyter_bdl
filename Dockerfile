FROM ubuntu:16.04

ADD entrypoint.sh /
ADD password.py /opt/
ADD env.sh /opt/
ADD handlers.py /opt/

RUN apt-get update -y

#Install yarn and NodeJS
RUN apt-get install -y unzip wget curl tar bzip2 software-properties-common git vim
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs
RUN npm install yarn -g

# Install Java 8
ENV JAVA_HOME /opt/jdk1.8.0_202
ENV PATH $PATH:/opt/jdk1.8.0_202/bin:/opt/jdk1.8.0_202/jre/bin:/etc/alternatives:/var/lib/dpkg/alternatives

RUN cd /opt && wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "https://download.oracle.com/otn-pub/java/jdk/8u202-b08/1961070e4c9b4e26a04e7f5a083f551e/jdk-8u202-linux-x64.tar.gz" &&\
   tar xzf jdk-8u202-linux-x64.tar.gz && rm -rf jdk-8u202-linux-x64.tar.gz

RUN echo 'export JAVA_HOME="/opt/jdk1.8.0_202"' >> ~/.bashrc && \
    echo 'export PATH="$PATH:/opt/jdk1.8.0_202/bin:/opt/jdk1.8.0_202/jre/bin"' >> ~/.bashrc && \
    bash ~/.bashrc && cd /opt/jdk1.8.0_202/ && update-alternatives --install /usr/bin/java java /opt/jdk1.8.0_202/bin/java 1
    
#Add Java Security Policies
RUN curl -L -C - -b "oraclelicense=accept-securebackup-cookie" -O http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip && \
   unzip jce_policy-8.zip
RUN cp UnlimitedJCEPolicyJDK8/US_export_policy.jar /opt/jdk1.8.0_202/jre/lib/security/ && cp UnlimitedJCEPolicyJDK8/local_policy.jar /opt/jdk1.8.0_202/jre/lib/security/
RUN rm -rf UnlimitedJCEPolicyJDK8

# Install Spark 2.4.0
RUN cd /opt && wget https://www-eu.apache.org/dist/spark/spark-2.4.0/spark-2.4.0-bin-hadoop2.7.tgz && \
   tar xzvf /opt/spark-2.4.0-bin-hadoop2.7.tgz && \
   rm  /opt/spark-2.4.0-bin-hadoop2.7.tgz 
   
# Spark pointers for Jupyter Notebook
ENV SPARK_HOME /opt/spark-2.4.0-bin-hadoop2.7

ENV PATH $PATH:/$SPARK_HOME/bin/
ADD core-site.xml.apiKey $SPARK_HOME/conf/
ADD log4j2.xml.default $SPARK_HOME/conf/
ADD hive-site.xml $SPARK_HOME/conf/

# Create additional files in the DataLake
RUN mkdir -p /user && mkdir -p /user/notebooks && mkdir -p /user/datasets && chmod 777 /entrypoint.sh

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
   pip install pyspark
    
RUN $CONDA_DIR/bin/conda config --set auto_update_conda False

#Add Getting Started Notebooks and change Jupyter logo and download additional libraries
RUN wget http://repo.uk.bigstepcloud.com/bigstep/bdl/Getting%20Started%20in%20Python3.ipynb -O /user/notebooks/Getting\ Started\ in\ Python3.ipynb 
   
RUN apt-get install -y make

RUN pip install nose pillow

RUN cd /opt && \
    wget http://repo.uk.bigstepcloud.com/bigstep/bdl/bigstepdatalake-0.10.4-bin.tar.gz  && \
    tar -xzvf bigstepdatalake-0.10.4-bin.tar.gz && \
    rm -rf /opt/bigstepdatalake-0.10.4-bin.tar.gz && \
    cp /opt/bigstepdatalake-0.10.4/lib/* $SPARK_HOME/jars/ && \
    export PATH=/opt/bigstepdatalake-0.10.4/bin:$PATH

# Install bdl_notebooks
RUN cd /opt && \
    wget http://repo.uk.bigstepcloud.com/bigstep/bdl/bdl_client_python_1.0.0.tar.gz && \
    tar -xzvf bdl_client_python_1.0.0.tar.gz && \
    rm -rf /opt/bdl_client_python_1.0.0.tar.gz && \
    cd ./bdl_client_python && \
    pip install . && \
    cd .. && \
    rm -rf bdl_client_python && \
    wget http://repo.uk.bigstepcloud.com/bigstep/bdl/jupyter_shared_notebook_module_0.2.tar.gz && \
    tar -xzvf jupyter_shared_notebook_module_0.2.tar.gz && \
    rm -rf /opt/jupyter_shared_notebook_module_0.2.tar.gz && \
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
   
ENV PATH /opt/bigstepdatalake-0.10.4/bin:$PATH
   
#        Jupyter 
EXPOSE   8888     

ENTRYPOINT ["/entrypoint.sh"]
