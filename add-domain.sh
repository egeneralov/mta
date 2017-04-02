#!/bin/bash

echo "Adding new domain"
        read -p "MySQL root password: " mysqlrootpasswd
	read -p "New domain [example.com]: " domain
        echo "INSERT INTO \`domains\` (\`domain\`) VALUES ('$domain');" | mysql -p$mysqlrootpasswd mail

