# MTA

### Description

Postfix + dovecot config and install. Fast configuration for all. Can be used after *webmaster* and *clean-lemp* or existing installation.

### Warning

This script will replace existing configuration. MTA exim will be deleted.

### Use

Simple. First:

	git clone https://github.com/egeneralov/mta.git
	cd mta
	./install.sh

If you need to add new domain:

	./add-domain.sh

If you need to add new user:

	./add-user.sh
