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
ENV JAVA_HOME /opt/jdk1.8.0_191
ENV PATH $PATH:/opt/jdk1.8.0_191/bin:/opt/jdk1.8.0_191/jre/bin:/etc/alternatives:/var/lib/dpkg/alternatives

RUN cd /opt && wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "https://download.oracle.com/otn-pub/java/jdk/8u191-b12/2787e4a523244c269598db4e85c51e0c/jdk-8u191-linux-x64.tar.gz" &&\
   tar xzf jdk-8u191-linux-x64.tar.gz && rm -rf jdk-8u191-linux-x64.tar.gz

RUN echo 'export JAVA_HOME="/opt/jdk1.8.0_191"' >> ~/.bashrc && \
    echo 'export PATH="$PATH:/opt/jdk1.8.0_191/bin:/opt/jdk1.8.0_191/jre/bin"' >> ~/.bashrc && \
    bash ~/.bashrc && cd /opt/jdk1.8.0_191/ && update-alternatives --install /usr/bin/java java /opt/jdk1.8.0_191/bin/java 1
    
#Add Java Security Policies
RUN curl -L -C - -b "oraclelicense=accept-securebackup-cookie" -O http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip && \
   unzip jce_policy-8.zip
RUN cp UnlimitedJCEPolicyJDK8/US_export_policy.jar /opt/jdk1.8.0_191/jre/lib/security/ && cp UnlimitedJCEPolicyJDK8/local_policy.jar /opt/jdk1.8.0_191/jre/lib/security/
RUN rm -rf UnlimitedJCEPolicyJDK8

# Install Spark 2.4.0
RUN cd /opt && wget https://www-eu.apache.org/dist/spark/spark-2.4.0/spark-2.4.0-bin-hadoop2.7.tgz && \
   tar xzvf /opt/spark-2.4.0-bin-hadoop2.7.tgz && \
   rm  /opt/spark-2.4.0-bin-hadoop2.7.tgz 
   
# Spark pointers for Jupyter Notebook
ENV SPARK_HOME /opt/spark-2.4.0-bin-hadoop2.7
ENV R_LIBS_USER $SPARK_HOME/R/lib:/opt/conda/envs/ir/lib/R/library:/opt/conda/lib/R/library
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.8.2.1-src.zip

ENV PATH $PATH:/$SPARK_HOME/bin/
ADD core-site.xml.apiKey $SPARK_HOME/conf/

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

#Install Scala Spark kernel
ENV SBT_VERSION 0.13.11
ENV SBT_HOME /usr/local/sbt
ENV PATH ${PATH}:${SBT_HOME}/bin
    
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
   pip install py4j
    
RUN $CONDA_DIR/bin/conda config --set auto_update_conda False

#RUN CONDA_VERBOSE=3 $CONDA_DIR/bin/conda create --yes -p $CONDA_DIR/envs/python3 python=3.5 ipython ipywidgets pandas matplotlib scipy seaborn scikit-learn
#RUN bash -c '. activate $CONDA_DIR/envs/python3 && \
 #   python -m ipykernel.kernelspec --prefix=/opt/conda && \
 #   . deactivate'
    
#RUN wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O /root/jq-linux64

#RUN chmod +x /root/jq-linux64
#RUN /root/jq-linux64 --arg v "$CONDA_DIR/envs/python3/bin/python"         '.["env"]["PYSPARK_PYTHON"]=$v' /opt/conda/share/jupyter/kernels/python3/kernel.json > /tmp/kernel.json &&   \
#    mv /tmp/kernel.json /opt/conda/share/jupyter/kernels/python3/kernel.json

#Install R kernel and set up environment
#RUN $CONDA_DIR/bin/conda config --add channels r
#RUN $CONDA_DIR/bin/conda install --yes -c r r-essentials r-base r-irkernel r-irdisplay r-ggplot2 r-repr r-rcurl
#RUN $CONDA_DIR/bin/conda create --yes  -n ir -c r r-essentials r-base r-irkernel r-irdisplay r-ggplot2 r-repr r-rcurl

#Configure Scala kernel
RUN mkdir -p /opt/conda/share/jupyter/kernels/scala
COPY kernel.json /opt/conda/share/jupyter/kernels/scala/

#Add Getting Started Notebooks and change Jupyter logo and download additional libraries
RUN wget http://repo.uk.bigstepcloud.com/bigstep/datalab/datalab_getting_started_in_scala__4.ipynb -O /user/notebooks/DataLab\ Getting\ Started\ in\ Scala.ipynb && \
 #  wget http://repo.bigstepcloud.com/bigstep/datalab/DataLab%2BGetting%2BStarted%2Bin%2BR%20%281%29.ipynb -O /user/notebooks/DataLab\ Getting\ Started\ in\ R.ipynb && \
   wget http://repo.bigstepcloud.com/bigstep/datalab/DataLab%2BGetting%2BStarted%2Bin%2BPython%20%283%29.ipynb -O /user/notebooks/DataLab\ Getting\ Started\ in\ Python.ipynb && \
   wget http://repo.bigstepcloud.com/bigstep/datalab/logo.png -O logo.png && \
 #  cp logo.png $CONDA_DIR/envs/python3/doc/global/template/images/logo.png && \
 #  cp logo.png $CONDA_DIR/envs/python3/lib/python3.5/site-packages/notebook/static/base/images/logo.png && \
   cp logo.png $CONDA_DIR/doc/global/template/images/logo.png && \
   rm -rf logo.png 
   
#RUN apt-get install -y libcairo2-dev  python3-cairo-dev
RUN apt-get install -y make

RUN pip install nose pillow

RUN cd /opt && \
    wget http://repo.uk.bigstepcloud.com/bigstep/bdl/bigstepdatalake-0.10.1-bin.tar.gz  && \
    tar -xzvf bigstepdatalake-0.10.1-bin.tar.gz && \
    rm -rf /opt/bigstepdatalake-0.10.1-bin.tar.gz && \
    export PATH=$PATH:/opt/bigstepdatalake-0.10.1/bin
    
RUN wget http://repo.uk.bigstepcloud.com/bigstep/datalab/DataLab%20Getting%20Started%20in%20Scala%202018.ipynb -O /user/notebooks/DataLab\ Getting\ Started\ in\ Scala.ipynb && \
    wget http://repo.uk.bigstepcloud.com/bigstep/datalab/DataLab%20Getting%20Started%20in%20Python%202018.ipynb -O /user/notebooks/DataLab\ Getting\ Started\ in\ Python.ipynb
    
#Install SparkMonitor extension
#RUN git clone https://github.com/krishnan-r/sparkmonitor && \
#   cd sparkmonitor/extension/ && \
#   yarn install && \
#   yarn run webpack && \
#   cd scalalistener/ && \
#   sbt package && \
#   cd .. 
#   pip install -e . 
#   jupyter nbextension install sparkmonitor --py --user --symlink && \
#   jupyter nbextension enable sparkmonitor --py --user  && \
#   jupyter serverextension enable --py --user sparkmonitor && \
#   ipython profile create && echo "c.InteractiveShellApp.extensions.append('sparkmonitor.kernelextension')" >>  $(ipython profile locate default)/ipython_kernel_config.py 
    
#        Jupyter 
EXPOSE   8888     

ENTRYPOINT ["/entrypoint.sh"]
