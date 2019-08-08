DESTDIR ?=
PREFIX ?= /opt/dowse
THREADS ?= 1

CC = gcc
CFLAGS = -Wall -fPIE -fPIC -pie -O3 -I.
CFLAGS+=$(shell pkg-config --cflags hiredis)
LIBS = -l:libhiredis.a -Llibdowse -l:libdowse.a

NODE_RED_MODULES= node-red \
		node-red-dashboard \
		node-red-contrib-ifttt \
		node-red-contrib-got \
		node-red-contrib-get-hrefs \
		node-red-contrib-get-feeds \
		node-red-contrib-device-stats \
		node-red-contrib-chatbot \
		node-red-ddm \
		node-red-node-pisrf \
		node-red-node-random \
		node-red-node-smooth \
		node-red-node-twitter

all: base springs
	#./checksum.sh $(DOWSE_USER)

node-red:
	npm install $(NODE_RED_MODULES)

libs:
	make -C libdowse

.PHONY: hiredis-lock

base: libs node-red netdata-plugins
	@echo "Compiled base"

netdata-plugins:
	make -C netdata-plugins

springs: dowse-to-gource dowse-to-osc dowse-to-mqtt dowse-cmd-fifo
	@echo "Dowse springs compiled"

#config:
	#@./config.sh ${DESTDIR}${PREFIX}

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@

dowse-log: dowse-log.o
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)

dowse-cmd-fifo: dowse-cmd-fifo.o
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)

hiredis-lock: hiredis-lock.o
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)

modprobe: modprobe.o kmod_log.o
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS) -lkmod

dowse-to-gource: dowse-to-gource.o
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)

dowse-to-osc: dowse-to-osc.o
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS) -llo

dowse-to-mqtt: dowse-to-mqtt.o
	$(CC) $(CFLAGS) -o $@ dowse-to-mqtt.o $(LIBS) -L./mosquitto/lib/ -lmosquitto    -lpthread

clean:
	rm -f *.o
	rm -f *.zkv
	rm -f database.h execrules.h
	rm -f dowse-to-osc dowse-to-gource dowse-to-mqtt
	rm -f hiredis-lock
	rm -f netdata/web/version.txt
	make -C netdata-plugins      clean
	make -C libdowse			 clean
