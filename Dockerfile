FROM nginx:1.23.0-alpine

ARG VERSION=0.0.0
ENV VERSION=${VERSION}

# CGit
ARG CGIT_VERSION=1.2.3-r2
ENV CGIT_VERSION=${CGIT_VERSION}

# CGit default options
ENV CGIT_TITLE="CGit"
ENV CGIT_DESC="The hyperfast web frontend for Git repositories"
ENV CGIT_VROOT="/"
ENV CGIT_SECTION_FROM_STARTPATH=0
ENV CGIT_MAX_REPO_COUNT=50

LABEL version="${VERSION}" \
    description="The hyperfast web frontend for Git repositories on top of Alpine and Nginx." \
    maintainer="gpix13"

RUN set -eux \
    && apk add --no-cache \
        ca-certificates \
        cgit=${CGIT_VERSION} \
        fcgiwrap \
        git \
        lua5.3-libs \
        py3-markdown \
        py3-pygments \
        python3 \
        spawn-fcgi \
        tzdata \
        xz \
        zlib \
        openssh \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* \
    && true

# Key generation on the server
RUN ssh-keygen -A

# -D flag avoids password generation
# -s flag changes user's shell
RUN mkdir -p /git-server/keys \
  && adduser -D -s /usr/bin/git-shell git \
  && echo git:12345 | chpasswd \
  && mkdir /home/git/.ssh

# This is a login shell for SSH accounts to provide restricted Git access.
# It permits execution only of server-side Git commands implementing the
# pull/push functionality, plus custom commands present in a subdirectory
# named git-shell-commands in the user’s home directory.
# More info: https://git-scm.com/docs/git-shell
# COPY git-shell-commands /home/git/git-shell-commands

# sshd_config file is edited for enable access key and disable access password
COPY sshd_config /etc/ssh/sshd_config

COPY cgit/cgit.conf /tmp/cgitrc.tmpl
COPY docker-entrypoint.sh /
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

RUN set -eux \
    && echo "Creating application directories..." \
    && mkdir -p /var/cache/cgit \
    && mkdir -p /srv/git \
    && true

RUN set -eux \
    && echo "Testing Nginx server configuration files..." \
    && nginx -c /etc/nginx/nginx.conf -t \
    && true

ENTRYPOINT [ "/docker-entrypoint.sh" ]

EXPOSE 80
EXPOSE 22

STOPSIGNAL SIGQUIT

CMD [ "nginx", "-g", "daemon off;" ]


# Metadata
LABEL org.opencontainers.image.vendor="gpix13" \
    org.opencontainers.image.url="https://github.com/gpix13/docker-cgit" \
    org.opencontainers.image.title="docker-cgit" \
    org.opencontainers.image.description="The hyperfast web frontend for Git repositories on top of Alpine and Nginx." \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.documentation="https://github.com/gpix13/docker-cgit"
