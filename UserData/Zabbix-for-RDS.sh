#!/bin/bash
#�ϐ��錾
rdsnama= #RDS�G���h�|�C���g�����
rdsuser= #RDSMaster���[�U��
rdspassword= #RDSMaster�p�X���[�h
dbname=zabbix #�ڍs��DB��
dbuser=zabbix #�ڍs��DB���[�U��
dbpassword=zabbix #�ڍsDB�p�X���[�h
#MySQL�N��
service mysqld start
#conf�t�@�C����荞��
confdbhostget() {
cat /etc/zabbix/zabbix_server.conf |grep ^DBHost=|awk '{print substr($0,index($0,"=")+1,length($0))}'
}
confdbhost=`confdbhostget`
confdbnameget() {
cat /etc/zabbix/zabbix_server.conf |grep ^DBName=|awk '{print substr($0,index($0,"=")+1,length($0))}'
}
confdbname=`confdbnameget`
confdbuserget() {
cat /etc/zabbix/zabbix_server.conf |grep ^DBUser=|awk '{print substr($0,index($0,"=")+1,length($0))}'
}
confdbuser=`confdbuserget`
confdbpasswordget() {
cat /etc/zabbix/zabbix_server.conf |grep ^DBPassword=|awk '{print substr($0,index($0,"=")+1,length($0))}'
}
confdbpassword=`confdbpasswordget`
#dump�pmy.cnf
echo [mysql] >> /home/ec2-user/my.cnf 
echo host = ${confdbhost} >> /home/ec2-user/my.cnf
echo user = ${confdbuser} >> /home/ec2-user/my.cnf
echo password = ${confdbpassword} >> /home/ec2-user/my.cnf
#rds���X�g�A�pmy.cnf
echo [mysql] >> /home/ec2-user/my.cnf2
echo host = ${rdsnama} >> /home/ec2-user/my.cnf2
echo user = ${rdsuser} >> /home/ec2-user/my.cnf2
echo password = ${rdspassword} >> /home/ec2-user/my.cnf2
#config�C��
sed -i -e "s/^DBHost=${confdbhost}/DBHost=${rdsnama}/g" /etc/zabbix/zabbix_server.conf
sed -i -e "s/^DBName=${confdbname}/DBName=${dbname}/g" /etc/zabbix/zabbix_server.conf
sed -i -e "s/^DBUser=${confdbuser}/DBUser=${dbuser}/g" /etc/zabbix/zabbix_server.conf
sed -i -e "s/^DBPassword=${confdbpassword}/DBPassword=${dbpassword}/g" /etc/zabbix/zabbix_server.conf
sed -i -e "s/^\$DB\['SERVER'\]   = '${confdbhost}';/\$DB\['SERVER'\]   = '${rdsnama}';/g" /etc/zabbix/web/zabbix.conf.php
sed -i -e "s/^\$DB\['DATABASE'\] = '${confdbname}';/\$DB\['DATABASE'\] = '${dbname}';/g" /etc/zabbix/web/zabbix.conf.php
sed -i -e "s/^\$DB\['USER'\]     = '${confdbuser}';/\$DB\['USER'\]     = '${dbuser}';/g" /etc/zabbix/web/zabbix.conf.php
sed -i -e "s/^\$DB\['PASSWORD'\] = '${confdbpassword}';/\$DB\['PASSWORD'\] = '${dbpassword}';/g" /etc/zabbix/web/zabbix.conf.php
#dbdump
mysqldump --defaults-extra-file=/home/ec2-user/my.cnf -N ${confdbname} > /tmp/zabbix_db.sql
#db�쐬
echo "create database ${dbname} character set utf8 collate utf8_bin;" > /tmp/create.sql
mysql --defaults-extra-file=/home/ec2-user/my.cnf2  < /tmp/create.sql
mysql --defaults-extra-file=/home/ec2-user/my.cnf2 -N ${dbname} < /tmp/zabbix_db.sql
#db�����ύX
echo "grant all privileges on ${dbname}.* to ${dbuser}@\`%\` identified by '${dbpassword}';" > /tmp/grant.sql
mysql --defaults-extra-file=/home/ec2-user/my.cnf2 < /tmp/grant.sql
#��ƃt�@�C���폜
rm /tmp/zabbix_db.sql
rm /tmp/create.sql
rm /tmp/grant.sql
rm /home/ec2-user/my.cnf
rm /home/ec2-user/my.cnf2
#MySQL��~
service mysqld stop
chkconfig mysqld off