FROM dyne/devuan:beowulf

COPY . /opt/dowse
WORKDIR /opt/dowse

RUN ./install.sh

EXPOSE 8000

CMD /bin/sh scripts/start_supervisiond.sh -f

