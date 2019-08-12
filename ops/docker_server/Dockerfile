FROM dyne/devuan:beowulf

COPY . /opt/dowse
WORKDIR /opt/dowse

RUN ./install.sh

CMD /bin/sh scripts/start_supervisiond.sh -f

