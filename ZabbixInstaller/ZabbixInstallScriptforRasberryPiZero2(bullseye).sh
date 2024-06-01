# ===================================================
# Zabbix Automatic configuration Script
# for Raspbian GNU/Linux 11 (bullseye)
# H/W Raspberry Pi Zero2
# --------------------------------------------------
# Zabbix-Server:5.51
# MariaDB:10.10.xx Under
# Apache:2.xx
# php:7.4
# --------------------------------------------------
# DB Password:password
#====================================================


# Web Server(Apache) Install
sudo apt -y install apache2

# PHP Install
sudo apt -y install lsb-release apt-transport-https ca-certificates
sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
sudo apt -y update
sudo apt -y upgrade

sudo apt -y install php7.4
sudo apt -y install php7.4-gd php7.4-bcmath php7.4-xml php7.4-mbstring php7.4-mysql

sudo sh -c "sed -ie \"s/; mbstring.language = Japanese/mbstring.language = Japanese/\" /etc/php/7.4/apache2/php.ini"
sudo apt -y install php7.4-fpm

# Apache Start
sudo systemctl restart apache2

# MariaDB Install( TargetVer < Ver10.10.xx)
sudo apt -y install mariadb-server
##sudo  mysql_secure_installation

# Password Set
vMariadbRootPasswd="password"

# mysql_secure_installation(SQL automate)
sudo mysql -u root --password=${vMariadbRootPasswd} -e "
    show create user root@localhost;
    UPDATE mysql.global_priv SET priv=json_set(priv, '$.plugin', 'mysql_native_password', '$.authentication_string', PASSWORD('${vMariadbRootPasswd}')) WHERE User='root';
    DELETE FROM mysql.global_priv WHERE User='';
    DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    FLUSH PRIVILEGES;
    UPDATE mysql.global_priv SET priv=json_set(priv, '$.password_last_changed', UNIX_TIMESTAMP(), '$.plugin', 'mysql_native_password', '$.authentication_string', 'invalid', '$.auth_or', json_array(json_object(), json_object('plugin', 'unix_socket'))) WHERE User='root';"

# grantt all privileges
sudo mysql -u root --password=${vMariadbRootPasswd} -e "
    grant all privileges on *.* to root@localhost identified by 'password' with grant option;"
    

# Zabix Install
wget wget https://repo.zabbix.com/zabbix/5.5/raspbian/pool/main/z/zabbix-release/zabbix-release_5.5-1+debian11_all.deb
sudo dpkg -i zabbix-release_5.5-1+debian11_all.deb
sudo apt update

sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent zabbix-sql-scripts

mysql -u root --password=${vMariadbRootPasswd} -e "
    create database zabbix character set utf8 collate utf8_bin;
    create user zabbix@localhost identified by 'password';
    grant all privileges on zabbix.* to zabbix@localhost;"

# Initial Table Add
sudo zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -p zabbix --password=${vMariadbRootPasswd}

mysql -u root --password=${vMariadbRootPasswd} -e "
    set global log_bin_trust_function_creators = 0;"

# zabbix config setting
sudo sh -c "sed -ie \"s/# DBPassword=/DBPassword=password/\" /etc/zabbix/zabbix_server.conf"

# Install Japanese UTF-8
sudo sh -c "sed -ie \"s/# ja/ja/\" /etc/locale.gen"
sudo sh -c "sed -ie \"s/# en/en/\" /etc/locale.gen"

apt-get install locales -y
sudo locale-gen

# ServiceStart
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2
