EXTENSION = pg2l
DATA = pg2l--1.0.sql

ifeq ($(PG_CONFIG),)
	PG_CONFIG = pg_config
endif

REGRESS = definitions
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)


TARGET_DIR = $(PG_HOME)/pg2l
install :
	mkdir -p $(TARGET_DIR)
	cp ./exp_lob_from_ora.pl $(TARGET_DIR)
	chown -R enterprisedb:enterprisedb $(TARGET_DIR)
