# MTA

### Description

Postfix + dovecot config and install. Fast configuration for all. Can be used after *webmaster* and *clean-lemp* or existing installation.

### Warning

This script will replace existing configuration. MTA exim will be deleted.

### Install and use

Simple. First:

	git clone https://github.com/egeneralov/mta.git
	cd mta
	./install.sh

#### If you need to add new domain support:

	./add-domain.sh

- Q: MySQL root password
- #:   Enter ROOT passwd.
- Q: Domain: my-new-domain.ru

#### If you need to add new user:

	./add-user.sh

- Q: MySQL root password
- #:   Enter ROOT passwd.
- Q: Domain: my-new-domain.ru
- Q: User: new-user
- #:   New domain will be applied, you need enter only username. In database it looks line: new-user@my-new-domain.ru
- Q: Password:
- #:   Enter password for mail user.
