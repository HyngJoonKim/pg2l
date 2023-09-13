EXTENSION = pg2l
DATA = pg2l--1.0.sql

ifeq ($(PG_CONFIG),)
	PG_CONFIG = pg_config
endif

REGRESS = definitions
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)


POSTGRESQL_ACCOUNT_HOME=/var/lib/edb
TARGET_DIR = $(POSTGRESQL_ACCOUNT_HOME)/pg2l_test
install :
	mkdir -p $(TARGET_DIR)
	chown enterprisedb:enterprisedb $(TARGET_DIR)
