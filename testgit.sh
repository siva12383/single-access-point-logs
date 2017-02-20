#!/bin/ksh
### Execute rsync ###

#set -x

echo "jetty  logs...", `date`
echo "-------------------------------------------------"

#list of server
user=siva
serv1=google1.com
serv2=google.com
ist_dir=path for logs
ist_file1=$ist_dir/audit.log
ist_file2=$ist_dir/error.log
ist_file3=$ist_dir/debug.log
ist_file4=$ist_dir/metrics.log
myDir="/home/siva/Access_log"
ERROR_FILE=/tmp/ASDC_errors.err
email_file=/tmp/ASDC_Error_Alert.txt
compare_time=$(date -u --date="-30 minutes" '+%Y-%m-%dT%H:%M:%S')

## Check if the log directory exists
if [ ! -d $myDir ]
then
    mkdir -p $myDir
else
    rm $myDir/*
fi

#rsync -a $servers:$syncfile $mkdir
#rsync -zarv --include "*/" --exclude "*" --include "*.log" "$ist1:$ist1_dir" "$sync_file" --password_file "myPassword"
for server in $serv1 $serv2
do
    rsync -a "${user}@${server}:$ist_file1" ":$ist_file2" ":$ist_file3" ":$ist_file4" "$myDir"
    #rsync --append -a --backup --suffix "_${ist1}" "$ist2:$ist_file1" ":$ist_file2" ":$ist_file3" ":$ist_file4" "$myDir2"
    for i in $(ls ${myDir}/*.log)
    do
        echo $i
        mv $i ${i}_${server}
    done
done

ls -l $myDir

cd $myDir
echo compare_time = $compare_time
if [ -f $ERROR_FILE ]
then
    rm $ERROR_FILE
fi
if [ -f $email_file ]
then
    rm $email_file
fi
cd $myDir
for i in $(ls)
do
    file_name=$i
    egrep Error $file_name | egrep 'STATUS = "500"|STATUS = "502"|STATUS = "504"' > $ERROR_FILE
    while read line
    do
       error_date=$(echo $line | cut -d'|' -s -f1)
       echo Error Date = $error_date
       if [[ "$error_date" \> "$compare_time" ]]
       then
           echo $error_date is less than 30 minutes from now
           echo $file_name:$line >> $email_file
       else
           echo $error_date is older than 30 minutes from now
       fi
    done < $ERROR_FILE
done

## Send alert email
if [ -s $email_file ]
then
    cat $email_file | mailx -s "Error Alert" siva@gmail.com
fi
exit

if egrep Error * | egrep 'STATUS = "500"' >> $ERROR_FILE
then
    echo "Found Eroor 500"
fi
if egrep Error * | egrep 'STATUS = "502"' >> $ERROR_FILE
then
    echo "Found Eroor 502"
fi
echo printing error file
cat $ERROR_FILE

#while read line 
#do
        #print $line
        #if grep Error $line | grep 404
        #then
                #print $line
        #fi
#done < $LOG_FILE
exit

