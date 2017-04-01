#!/bin/bash

# Hello!

	clear;

	echo "Hello! I will setup MTA (posfix+dovecot) for you."
	read -p "Enter your main domain:" domain
	echo $domain > /etc/mailname
	read -p "Enter your future mail user [@$domain]:" user
	read -p "Enter your password for $user@$domain: " password
	read -p "MySQL root password: " mysqlrootpasswd

# MUST run on clean

	echo -e "\e[31m + apt-get clean\e[0m"; apt-get clean > /dev/null 2>&1;
	echo -e "\e[31m + apt-get update\e[0m"; apt-get update > /dev/null 2>&1;
	echo -e "\e[31m + apt-get upgrade\e[0m"; apt-get upgrade -y > /dev/null 2>&1;
	echo -e "\e[31m + apt-get purge exim\e[0m"; apt-get remove --purge -y --force-yes exim4\* > /dev/null 2>&1;

# Auto postfix installation

	debconf-set-selections <<< "postfix postfix/mailname string $domain"
	debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

# Auto mysql installation

	debconf-set-selections <<< "mysql-server-5.5	mysql-server/root_password string $mysqlrootpasswd"
	debconf-set-selections <<< "mysql-server-5.5	mysql-server/root_password_again string $mysqlrootpasswd"

# Installing packages

	echo -e "\e[31m + apt-get install mysql-server dovecot-core dovecot-imapd dovecot-mysql dovecot-pop3d dovecot-sieve postfix postfix-mysql\e[0m";
	apt-get install -y mysql-server dovecot-core dovecot-imapd dovecot-mysql dovecot-pop3d dovecot-sieve postfix postfix-mysql > /dev/null 2>&1;

# Stop services	

	echo -e "\e[31m service postfix stop\e[0m"; /etc/init.d/postfix stop
	echo -e "\e[31m service dovecot stop\e[0m"; /etc/init.d/dovecot stop

# User and permissons

	echo -e "\e[31m Adding user for mail service\e[0m";
	groupadd -g 5000 vmail;
	useradd -g vmail -u 5000 vmail -d /home/vmail;
	mkdir -p /home/vmail/$domain/$user;
	chown -R vmail:vmail /home/vmail/;

# Create mysql user for mail

	echo -e "\e[31m -> configuring mysql\e[0m";
	echo "CREATE DATABASE mail;" | mysql -p$mysqlrootpasswd mysql || echo -e "\e[31m >> creating database failed\e[0m";
	echo "CREATE USER 'mail'@'localhost' IDENTIFIED BY 'YRC29rNa';" | mysql -p$mysqlrootpasswd mail || echo -e "\e[31m >>create user failed\e[0m";
	echo "GRANT ALL PRIVILEGES ON mail.* TO 'mail'@'localhost';" | mysql -p$mysqlrootpasswd mail || echo -e "\e[31m >> mysql set user permissions failed\e[0m";
	echo "FLUSH PRIVILEGES;" | mysql -p$mysqlrootpasswd mail || echo -e "\e[31m >> flush privileges failed\e[0m";

# Import mysql tables

	echo -e "\e[31m -> importing .sql \e[0m"; 
	mysql -p$mysqlrootpasswd mail < mail.sql || echo -e "\e[31m failed\e[0m";

# Replace config

	rm -rf /etc/dovecot || echo -e "\e[31m >> remove /etc/dovecot failed\e[0m";
	rm -rf /etc/postfix || echo -e "\e[31m >> remove /etc/postfix failed\e[0m";
	mv postfix /etc/ || echo -e "\e[31m >> replace dovecot config failed\e[0m";
	mv dovecot /etc/ || echo -e "\e[31m >> replace postfix config failed\e[0m";

# Start services

	/etc/init.d/postfix start || echo -e "\e[31m >> postfix start failed \e[0m" # systemctl status postfix.service -l
	/etc/init.d/dovecot start || echo -e "\e[31m >> dovecot start failed \e[0m" # systemctl status dovecot.service -l

# Adding domain

	echo "INSERT INTO \`domains\` (\`domain\`) VALUES ('$domain');" | mysql -p$mysqlrootpasswd mail

# Adding user

	echo "INSERT INTO \`users\` (\`email\`, \`password\`, \`quota\`, \`domain\`) VALUES ('$user@$domain', encrypt('$password'), '20971520', '$domain');" | mysql -p$mysqlrootpasswd mail








