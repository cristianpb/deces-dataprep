SHELL=/bin/bash

PWD := $(shell pwd)
GIT = $(shell which git)
MAKE = $(shell which make)
RECIPE = dataprep_personnes-dedecees_search
TIMEOUT = 2520

dummy               := $(shell touch artifacts)

scaffold:
	${GIT} clone https://github.com/matchid-project/backend
	cp artifacts backend/artifacts
	echo "export ES_NODES=1" >> backend/artifacts
	echo "export PROJECTS=${PWD}/projects" >> backend/artifacts
	echo "export S3_BUCKET=fichier-des-personnes-decedees" >> backend/artifacts

up:
	${MAKE} -C backend backend elasticsearch
	${MAKE} -C backend wait-backend
	${MAKE} -C backend wait-elasticsearch

recipe-run:
	${MAKE} -C backend recipe-run RECIPE=${RECIPE}

watch-run:
	@timeout=${TIMEOUT} ; ret=1 ; \
		until [ "$$timeout" -le 0 -o "$$ret" -eq "0"  ] ; do \
			f=$$(find backend/log/ -iname '*dataprep_personnes-dedecees_search*' | sort | tail -1);\
		((tail $$f | grep "end of all" > /dev/null) || exit 1) ; \
		ret=$$? ; \
		if [ "$$ret" -ne "0" ] ; then \
			echo "waiting for end of job $$timeout" ; \
			tail $$f ;\
			sleep 10 ;\
		fi ; ((timeout--)); done ; exit $$ret
	@find backend/log/ -iname '*dataprep_personnes-dedecees_search*' | sort | tail -1 | xargs tail
backup:
	${MAKE} -C backend elasticsearch-backup

s3-push:
	${MAKE} -C backend elasticsearch-s3-push S3_BUCKET=fichier-des-personnes-decedees

down:
	${MAKE} -C backend backend-stop elasticsearch-stop

clean:
	sudo rm -rf backend

all: scaffold up recipe-run watch-run down backup s3-push clean
	@echo ended with succes !!!