# MTA 
## NOT WORKING FOR NOW
## please, wait

#### Config

	mysqlpasswd="killall33"

#### MUST run on clean

	echo -e "\e[31m +apt-get clean\e[0m"; apt-get clean > /dev/null 2>&1;
	echo -e "\e[31m +apt-get update\e[0m"; apt-get update > /dev/null 2>&1;
	echo -e "\e[31m +apt-get upgrade\e[0m"; apt-get upgrade -y > /dev/null 2>&1;
	echo -e "\e[31m +apt-get purge exim\e[0m"; apt-get remove --purge -y --force-yes exim4\* > /dev/null 2>&1;

#### Fuck off postfix installation

	debconf-set-selections <<< "postfix postfix/mailname string $domain"
	debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

#### Fuck off mysql installation

	debconf-set-selections <<< "mysql-server-5.5	mysql-server/root_password string $mysqlpasswd"
	debconf-set-selections <<< "mysql-server-5.5	mysql-server/root_password_again string $mysqlpasswd"

#### Installing packages

	echo -e "\e[31m + apt-get install mysql-server dovecot-core dovecot-imapd dovecot-mysql dovecot-pop3d dovecot-sieve postfix postfix-mysql\e[0m";
	apt-get install -y dovecot-core dovecot-imapd dovecot-mysql dovecot-pop3d dovecot-sieve postfix postfix-mysql > /dev/null 2>&1;

#### Stop services	

	echo -e "\e[31m service postfix stop\e[0m"; /etc/init.d/postfix stop
	echo -e "\e[31m service dovecot stop\e[0m"; /etc/init.d/dovecot stop

#### User and permissons

	echo -e "\e[31m Adding user for mail service\e[0m";
	groupadd -g 5000 vmail;
	useradd -g vmail -u 5000 vmail -d /var/mail;
	mkdir /var/mail/vhosts/;
	chown -R vmail:vmail /var/mail/;

#### Create mysql user for mail

	echo "CREATE USER 'mail'@'localhost' IDENTIFIED BY 'YRC29rNa';"
	echo "GRANT ALL PRIVILEGES ON mail.* TO 'mail'@'localhost';" | mysql -p$mysqlpasswd mail
	echo "FLUSH PRIVILEGES;" | mysql -p$mysqlpasswd mail

#### Import mysql tables

	mysql -p$mysqlpasswd mail < mail.sql

#### Replace config

	rm -rf /etc/dovecot
	rm -rf /etc/postfix
	mv postfix /etc/
	mv dovecot /etc/

#### Start services

	/etc/init.d/postfix start
	/etc/init.d/dovecot start












