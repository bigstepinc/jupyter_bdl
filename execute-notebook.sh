#!/bin/bash

counter="0"

#MODEL_BDL_FILE=`basename $MODEL_BDL_PATH`

while [ $counter -lt 10 ]
do
echo "Trying to execute local notebook" 
jupyter nbconvert --to notebook --execute /lentiq/notebooks/on-boarding.ipynb
rm /lentiq/notebooks/on-boarding.ipynb

FILE=/lentiq/notebooks/HairEyeColor.csv
if test -f "$FILE"; then
    echo "$FILE exists"
    rm /lentiq/notebooks/HairEyeColor.csv
    rm /lentiq/notebooks/on-boarding.ipynb
    exit 0
else 
  echo "$FILE does not exist"
  sleep 10
  counter=$[$counter+1]
fi
done

#curl -XPUT -H "content-type: application/json"   -d "{\"path\":\"/models/$MODEL_BDL_FILE\"}" http://localhost:65327/model
#result=$?
#if [ $result -eq 0 ]; then
#	echo "Succesfully loaded the model" >> /tmp/model_load
#	exit 0
#else
#	echo "Failed to load the model" >> /tmp/model_load
#	sleep 10
#	counter=$[$counter+1]
#fi
#done

echo "Failed to find the file,killing main process" 
# if it wasn't able to perform the load after 10 tries, kill the main process
kill 1
