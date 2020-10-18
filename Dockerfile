
# docker run -it --rm ibrezm1/alpine-ansible-py3:412a5de /bin/sh
  
ARG ALPINE_VERSION=latest
FROM alpine:${ALPINE_VERSION}

LABEL maintainer="Johannes Denninger"
ARG ANSIBLE_VERSION="2.9.6"

COPY ./entrypoint.sh /usr/local/bin

RUN echo "===> Installing sudo to emulate normal OS behavior..."  && \
    apk add --no-cache sudo bash                                        


RUN set -euxo pipefail ;\
    sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories ;\
    apk add --no-cache --update --virtual .build-deps g++ python3-dev build-base libffi-dev openssl-dev ;\
    apk add --no-cache --update python3 ca-certificates openssh-client sshpass dumb-init su-exec openssh openrc;\
    if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi ;\
    echo "**** install pip ****" ;\
    python3 -m ensurepip ;\
    rm -r /usr/lib/python*/ensurepip ;\
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi ;\
    pip3 install --no-cache --upgrade pip ;\
    pip3 install --no-cache --upgrade setuptools wheel ansible==${ANSIBLE_VERSION} ;\
    apk del --no-cache --purge .build-deps ;\
    rm -rf /var/cache/apk/* ;\
    rm -rf /root/.cache ;\
    mkdir -p /etc/ansible/ ;\
    /bin/echo -e "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts ;\
    ssh-keygen -q -t ed25519 -N '' -f /root/.ssh/id_ed25519 ;\
    mkdir -p ~/.ssh && echo "Host *" > ~/.ssh/config && echo " StrictHostKeyChecking no" >> ~/.ssh/config ;\
    chmod +x /usr/local/bin/entrypoint.sh ;\
    adduser -s /bin/ash -u 1000 -D -h /ansible ansible

RUN echo "===> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible                        && \
    echo 'localhost' > /etc/ansible/hosts        && \
	sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config   && \
	sed -i 's/#*PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config   && \
	sed -i 's/#*PermitEmptyPasswords no/PermitEmptyPasswords yes/g' /etc/ssh/sshd_config   && \
    echo 'root:pass' | chpasswd

RUN ssh-keygen -A   && \
    rc-status  && \
    touch /run/openrc/softlevel && \
    /etc/init.d/sshd start 
	
	
CMD ["/bin/bash"]
