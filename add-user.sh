#!/bin/bash

echo "Adding new user"
        read -p "MySQL root password: " mysqlrootpasswd
	read -p "Domain [example.com]: " domain
	read -p "User [user](@$domain will autoadd): " user
	read -p "Password: " password
        echo "INSERT INTO \`users\` (\`email\`, \`password\`, \`quota\`, \`domain\`) VALUES ('$user@$domain', encrypt('$password'), '20971520', '$domain');" | mysql -p$mysqlrootpasswd mail

