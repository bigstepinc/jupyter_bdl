#!/bin/bash

counter="0"

echo "Trying to download the script from the repo"
cd /opt && wget https://repo.lentiq.com/starter.py 

while [ $counter -lt 10 ]
do
echo "Trying to execute local notebook" 
python /opt/starter.py >> /opt/output.txt

FILE=/opt/output.txt
if [[ 'grep 'DONE' $FILE' ]];then
    echo "The execution of the starter script has ended successfully"
    rm /opt/output.txt
    rm /opt/starter.py
    exit 0
else 
  echo "The execution of the starter script has not ended successfully"
  sleep 10
  counter=$[$counter+1]
fi
done

echo "Failed to execute the starter script, killing main process" 
# if it wasn't able to perform the load after 10 tries, kill the main process
kill 1
