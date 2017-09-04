#!/bin/bash 
#Agustus 2017
#Create by Dhenyaw
#Report Akun Platinum
#Dalam skrip ini di butuhkan aplikasi nc
#Install menggunakan yum install nc untuk centos, dan apt-get install nc untuk debian.

TZ='Asia/Jakarta'
export TZ

#Harus di sesuaikan
email=dhenymwn@gmail.com    
send_date=20
support_dir=/home/s10066
domain=bsrgroup.co.id

#Fungsi input data ke file csv
function entry
{
    echo -e $(date +%d) $(date +%b) $(date +%Y), $(cat $report_web), $(cat $report_pop3) , $(cat $report_smtp) , $(cat $report_queue) ,$(cat $report_ping),$(cat $report_sql) ,$(cat $report_quota) , >> $csvfile
}

#Cek service apache2
function cekweb
{
/etc/init.d/httpd status
}

#Cek service POP3
function pop3
{
  nc -z $domain 110
}

#Cek service SMTP
function smtp
{
  nc -z $domain 587
}

#Cek Antrian Email
function queue
{
  exim -bpc > $report_exim
}

#Cek service MySQL
function ceksql
{
  /etc/init.d/mysql status
}

#Cek pemakaian Quota user
function cekquota
{
  quota -sv $user | awk 'NR==4 {print $1;}' > $report_quota
}

#Cek Statistik
function statistik
{
        sed -n '/BEGIN_DAY/,/END_DAY/p' /home/$user/tmp/awstats/awstats$(date +"%m""%Y").$domain.txt > $support_dir/awstat_$domain.txt
        get_=$(echo $(date +%Y%m%d -d "yesterday"))
        hit=$(grep $get_ $support_dir/awstat_$domain.txt | awk '{print $3}')
        get2_=$(echo $(date +%d -d "yesterday") $(date +%b) $(date +%Y))
        get3_=$(echo $(date +%d -d "yesterday"))
}
#Kirim Email
function send_email
(
    body_msg="Laporan Platinum Periode $(echo $(date +%b) $(date +%Y))"
    subject="Laporan Platinum $domain"
    echo "$body_msg" | mailx -s "$subject" -a $csvfile $email
)

#Validasi file
function validasi
{
  cat $csvfile | awk '{print $1}' | cut -d "," -f1 | grep $(cat $report_tgl)
}



csvfile=$support_dir/$domain$(date +_%m%Y).csv
queue_threshold=700
user=$(/scripts/whoowns $domain)

#Temporary File
newstat=$support_dir/awstat_$domain.txt
report_tgl=$support_dir/reporttgl.txt
report_web=$support_dir/reportweb.txt
report_ping=$support_dir/reportping.txt
report_pop3=$support_dir/reportpop3.txt
report_smtp=$support_dir/reportsmtp.txt
report_exim=$support_dir/reportexim.txt
report_queue=$support_dir/reportqueue.txt
report_sql=$support_dir/reportsql.txt
report_quota=$support_dir/reportquota.txt

#Mengecek file csv, jika tidak ada akan di buatkan
   if [ ! -f $csvfile ]
   then 
   printf ", , ,\n\nPlatinum,Report,$(date +"%B"),$(date | awk '{print $6}')\n" > $csvfile
   printf "Date,Web/HTTP,POP3,SMTP,Email Queue,Network,MySQL,Quota,Statistik\n" >> $csvfile
   fi

#Cek tanggal
date +%d > $report_tgl

#Cek service http
   cekweb > /dev/null  2>&1
   if [ $? -eq 0 ]
   then
      echo "Up" > $report_web
   else
      echo "Down" > $report_web
   fi

#Cek port pop3
   pop3 > /dev/null 2>&1
   if [ $? -eq 0 ]
      then 
      echo "Ok" > $report_pop3
   else
      echo "Down" > $report_pop3
   fi

#Cek port smtp
   smtp > /dev/null 2>&1
   if [ $? -eq 0 ]
      then
      echo "Ok" > $report_smtp
   else
      echo "Down" > $report_smtp
   fi

#Cek antrian email
   queue 
   exim=$(cat $report_exim)
   if [ $exim -ge $queue_threshold ]
      then
      echo "Not Ok" > $report_queue
   else
      echo "Ok" > $report_queue
   fi

#Cek Ping Times
   ping -c 2 $domain | awk 'NR==2{print $8$9}' | cut -f2 -d '=' > $report_ping

#Cek mysql
  ceksql > /dev/null 2>&1
  if [ $? -eq 0 ]
     then
     echo "Ok" > $report_sql
  else
     echo "Down" > $report_sql
  fi

#Pemakaian Quota
  cekquota

#Validarsi dan entry
   validasi
   if [ $? -eq 1 ]
      then
      entry
   fi

#Statistik
  statistik
  cek_hit=$(grep "$get2_" $csvfile | awk '{print $13}')

  if [ "$cek_hit" != "$hit" ]
    then
    sed -i "/^$get3_/s/$/ $hit/" $csvfile
  fi
  
#Kirim Email
  cek_date=$(date +%d)
  if [ $cek_date = $send_date ]
    then
    send_email
  fi

   rm -f $report_web
   rm -f $report_tgl
   rm -f $report_ping
   rm -f $newstat
   rm -f $report_pop3
   rm -f $report_smtp
   rm -f $report_exim
   rm -f $report_queue
   rm -f $report_sql
   rm -f $report_quota
