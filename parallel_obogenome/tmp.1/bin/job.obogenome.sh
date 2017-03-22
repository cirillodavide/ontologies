rm -rf tmp/out.txt
rm -rf tmp/log.txt
rm -rf tmp/tmp.txt

cat $1 | sort -u > tmp/tmp.txt

bash bin/killer.sh tmp/tmp.txt &
bash bin/saver.sh tmp/tmp.txt &
wait
