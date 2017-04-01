# MTA 
# NOT WORKING

### Config

	mysqlpasswd="killall33"
	mail_db_name="mail"
	mail_db_user="killall33"
	mail_db_passwd="killall33"
	main_domain="egeneralov.ml"
	#read -p "Enter main domain (like [$main_domain]): "

### MUST run on clean

	apt-get clean
	apt-get update
	apt-get upgrade -y
	apt-get remove --purge -y --force-yes exim4\* rpcbind

#### Fuck off postfix installation

	debconf-set-selections <<< "postfix postfix/mailname string $domain"
	debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

#### Fuck off mysql installation

	debconf-set-selections <<< "mysql-server-5.5	mysql-server/root_password string $mysqlpasswd"
	debconf-set-selections <<< "mysql-server-5.5	mysql-server/root_password_again string $mysqlpasswd"

### Install postfix

	apt-get install -y postfix postfix-mysql 

### Install dovecot

	apt-get install -y dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql 

### Install mysql

	apt-get install -y mysql-server

### Install mailutils - need for sendmail use

	apt-get install -y mailutils

### Install openssl - need for ssl generate

	apt-get install -y openssl

### Create mysql database for mail

	mysqladmin -p$mysqlpasswd create $mail_db_name

### Create mysql user for mail

	echo "GRANT SELECT ON $mail_db_name.* TO '$mail_db_user'@'127.0.0.1' IDENTIFIED BY '$mail_db_passwd';" | mysql -p$mysqlpasswd $mail_db_name 
	echo "FLUSH PRIVILEGES;" | mysql -p$mysqlpasswd $mail_db_name

### Table for domains

	echo 'CREATE TABLE `virtual_domains` (
	  `id` int(11) NOT NULL auto_increment,
	  `name` varchar(50) NOT NULL,
	  PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;' | mysql -p$mysqlpasswd $mail_db_name

### Table for users

	echo 'CREATE TABLE `virtual_users` (
	  `id` int(11) NOT NULL auto_increment,
	  `domain_id` int(11) NOT NULL,
	  `password` varchar(106) NOT NULL,
	  `email` varchar(100) NOT NULL,
	  PRIMARY KEY (`id`),
	  UNIQUE KEY `email` (`email`),
	  FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;' | mysql -p$mysqlpasswd $mail_db_name

### Table for aliases

	echo 'CREATE TABLE `virtual_aliases` (
	  `id` int(11) NOT NULL auto_increment,
	  `domain_id` int(11) NOT NULL,
	  `source` varchar(100) NOT NULL,
	  `destination` varchar(100) NOT NULL,
	  PRIMARY KEY (`id`),
	  FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;' | mysql -p$mysqlpasswd $mail_db_name

### Construction for add start-up domains and users

	groupadd -g 5000 vmail
	useradd -g vmail -u 5000 vmail -d /var/mail
	mkdir /var/mail/vhosts/
	chown -R vmail:vmail /var/mail/

read -p "fuck construction" temp

	i=1;
	for domain in `ls domains`; do
	        echo "INSERT INTO \`"$mail_db_name"\`.\`virtual_domains\` (\`id\` ,\`name\`) VALUES ('1', '$domain');" | mysql -p$mysqlpasswd $mail_db_name
		mkdir -p /var/mail/vhosts/$domain
		chown -R vmail:vmail /var/mail/vhosts/$domain
		chmod -R 775 /var/mail/vhosts/$domain
	        for current in `cat domains/$domain`; do
		        current=`echo $current | sed 's/:/      /g'`
		        user=`echo $current | awk '{print $1}'`
		        passwd=`echo $current | awk '{print $2}'`
		        echo "INSERT INTO $mail_db_name.virtual_users (\`id\`, \`domain_id\`, \`password\`, \`email\`) VALUES " \
		        "('$i', '$i', ENCRYPT('$passwd'), '$user@$domain');" | mysql -p$mysqlpasswd $mail_db_name
		        i=$(($i+1));
	        done
	done

read -p "construction finished" temp

### Aliases

###### INSERT INTO `$mail_db_name`.`virtual_aliases`
###### (`id`, `domain_id`, `source`, `destination`)
###### VALUES
###### ('1', '1', 'alias@example.com', 'email1@example.com');

### Test

###### SELECT * FROM $mail_db_name.virtual_domains;
###### SELECT * FROM $mail_db_name.virtual_users;
###### SELECT * FROM $mail_db_name.virtual_aliases;

### Stop recommend

###### postfix stop

### Backup config

read -p "postfix" temp

	cp /etc/postfix/main.cf /etc/postfix/main.cf.orig

	cat <<< "
	#myorigin = /etc/mailname
	smtpd_banner = $myhostname ESMTP $mail_name (Ubuntu)
	biff = no
	append_dot_mydomain = no
	#delay_warning_time = 4h
	readme_directory = no
	# TLS parameters
	#smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
	#smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
	#smtpd_use_tls=yes
	#smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
	#smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache
	
	smtpd_tls_cert_file=/etc/dovecot/dovecot.pem
	smtpd_tls_key_file=/etc/dovecot/private/dovecot.pem
	smtpd_use_tls=yes
	smtpd_tls_auth_only = yes
	#Enabling SMTP for authenticated users, and handing off authentication to Dovecot
	smtpd_sasl_type = dovecot
	smtpd_sasl_path = private/auth
	smtpd_sasl_auth_enable = yes
	smtpd_recipient_restrictions =
        permit_sasl_authenticated,
        permit_mynetworks,
        reject_unauth_destination
	myhostname = $main_domain
	alias_maps = hash:/etc/aliases
	alias_database = hash:/etc/aliases
	myorigin = /etc/mailname
	mydestination = localhost
	relayhost =
	mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
	mailbox_size_limit = 0
	recipient_delimiter = +
	inet_interfaces = all
	virtual_transport = lmtp:unix:private/dovecot-lmtp
	
	virtual_mailbox_domains = mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
	virtual_mailbox_maps = mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
	virtual_alias_maps = mysql:/etc/postfix/mysql-virtual-alias-maps.cf,
	mysql:/etc/postfix/mysql-virtual-email2email.cf
	" > /etc/postfix/main.cf
	
	cat <<< "
	user = $mail_db_user
	password = $mail_db_passwd
	hosts = 127.0.0.1
	dbname = $mail_db_name
	query = SELECT 1 FROM virtual_domains WHERE name='%s'
	" > /etc/postfix/mysql-virtual-mailbox-domains.cf
	
	cat <<< "
	user = $mail_db_user
	password = $mail_db_passwd
	hosts = 127.0.0.1
	dbname = $mail_db_name
	query = SELECT 1 FROM virtual_aliases WHERE name='%s'
	" > /etc/postfix/mysql-virtual-mailbox-maps.cf

	cat <<< "
	user = $mail_db_user
	password = $mail_db_passwd
	hosts = 127.0.0.1
	dbname = $mail_db_name
	query = SELECT 1 FROM virtual_domains WHERE name='%s'
	" > /etc/postfix/mysql-virtual-alias-maps.cf
	
	cat <<< "
	user = $mail_db_user
	password = $mail_db_passwd
	hosts = 127.0.0.1
	dbname = $mail_db_name
	query = SELECT 1 FROM virtual_users WHERE name='%s'
	" >/etc/postfix/mysql-virtual-email2email.cf
	
### Restart service

	service postfix restart

### Test

###### postmap -q $domain mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
###### postmap -q $user@domain mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
###### postmap -q $user_alias@domain mysql:/etc/postfix/mysql-virtual-alias-maps.cf

### Backup master.cf

	cp /etc/postfix/master.cf /etc/postfix/master.cf.orig

### Write master.cf
	cat <<< "
	smtp      inet  n       -       -       -       -       smtpd
	submission inet n       -       -       -       -       smtpd
	  -o syslog_name=postfix/submission
	  -o smtpd_tls_security_level=encrypt
	  -o smtpd_sasl_auth_enable=yes
	  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
	  -o milter_macro_daemon_name=ORIGINATING
	smtps     inet  n       -       -       -       -       smtpd
	  -o syslog_name=postfix/smtps
	  -o smtpd_tls_wrappermode=yes
	  -o smtpd_sasl_auth_enable=yes
	  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
	  -o milter_macro_daemon_name=ORIGINATING
	" > /etc/postfix/master.cf

### Permission

	chmod -R o-rwx /etc/postfix

### Apply, postfix ready

	service postfix restart

read -p "finish postfix" temp

### Dovecot backup

	cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.orig
	cp /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.orig
	cp /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.orig
	cp /etc/dovecot/dovecot-sql.conf.ext /etc/dovecot/dovecot-sql.conf.ext.orig
	cp /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.orig
	cp /etc/dovecot/conf.d/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf.orig

### Write config

	cat <<< "
	## Dovecot configuration file
	!include_try /usr/share/dovecot/protocols.d/*.protocol
	protocols = imap pop3 lmtp
	#listen = *, ::
	#base_dir = /var/run/dovecot/
	#instance_name = dovecot
	#login_greeting = Dovecot ready.
	#login_trusted_networks =
	#login_access_sockets = 
	#verbose_proctitle = no
	#shutdown_clients = yes
	#doveadm_worker_count = 0
	#doveadm_socket_path = doveadm-server
	#import_environment = TZ
	dict {
	  #quota = mysql:/etc/dovecot/dovecot-dict-sql.conf.ext
	  #expire = sqlite:/etc/dovecot/dovecot-dict-sql.conf.ext
	}
	!include conf.d/*.conf
	!include_try local.conf
	" > /etc/dovecot/dovecot.conf
	
	sed -i "s/mail_location/mail_location = maildir:\/var\/mail\/vhosts\/%d\/%n \#/g" /etc/dovecot/conf.d/10-mail.conf
	sed -i "s/\#mail_privileged_group/mail_privileged_group = mail \#/g" /etc/dovecot/conf.d/10-mail.conf
	sed -i "s/auth_mechanisms = plain/auth_mechanisms = plain login/g"  /etc/dovecot/conf.d/10-auth.conf
	sed -i "s/\!include auth-system.conf.ext/\#\!include auth-system.conf.ext/g" /etc/dovecot/conf.d/10-auth.conf
	sed -i "s/\#\!include auth-sql.conf.ext/\!include auth-sql.conf.ext/g" /etc/dovecot/conf.d/10-auth.conf
	
	cat <<< "
	passdb {
	  driver = sql
	  args = /etc/dovecot/dovecot-sql.conf.ext
	}
	userdb {
	  driver = static
	  args = uid=vmail gid=vmail home=/var/mail/vhosts/%d/%n
	}
	" > /etc/dovecot/conf.d/auth-sql.conf.ext
	
	sed -i "s/\#driver =/driver = mysql/g" /etc/dovecot/dovecot-sql.conf.ext
	echo "connect = host=127.0.0.1 dbname=$mail_db_name user=$mail_db_user password=$mail_db_passwd" >> /etc/dovecot/dovecot-sql.conf.ext
	sed -i "s/\#default_pass_scheme = MD5/default_pass_scheme = SHA512-CRYPT/g" /etc/dovecot/dovecot-sql.conf.ext
	echo "password_query = SELECT email as user, password FROM virtual_users WHERE email='%u';" >> /etc/dovecot/dovecot-sql.conf.ext
	
### Permissions

	chown -R vmail:dovecot /etc/dovecot
	chmod -R o-rwx /etc/dovecot

	cat <<< "
	service imap-login {
	  inet_listener imap {
	    port = 0
	  }
	  inet_listener imaps {
	  }
	}
	service pop3-login {
	  inet_listener pop3 {
	    port = 0
	  }
	  inet_listener pop3s {
	  }
	}
	service lmtp {
	 unix_listener /var/spool/postfix/private/dovecot-lmtp {
	   mode = 0600
	   user = postfix
	   group = postfix
	  }
	}
	service imap {
	}
	service pop3 {
	}
	service auth {
	  unix_listener /var/spool/postfix/private/auth {
	    mode = 0666
	    user = postfix
	    group = postfix
	  }
	
	  unix_listener auth-userdb {
	    mode = 0600
	    user = vmail
	    #group = vmail
	  }
	  user = dovecot
	}
	service auth-worker {
	  user = vmail
	}
	service dict {
	  unix_listener dict {
	  }
	}
	" > /etc/dovecot/conf.d/10-master.conf

### Gen ssl cer

read -p "gen ssl" temp

	openssl req -x509 -nodes -days 1 -newkey rsa:2048 -keyout /etc/ssl/private/dovecot.pem -out /etc/ssl/certs/dovecot.pem -subj "/C=RU/ST=test/L=test/O=test/CN=$main_domain" >> /root/log.txt 2>&1

	cat <<< "
	ssl = required
	ssl_cert = </etc/ssl/certs/dovecot.pem
	ssl_key = </etc/ssl/private/dovecot.pem
	" > /etc/dovecot/conf.d/10-ssl.conf
	
### Finish dovecot

	service dovecot restart

read -p "finished" temp

