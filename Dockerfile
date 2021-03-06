FROM aninopteltd/nginx:1.11.9

MAINTAINER Jason Wilder mail@jasonwilder.com # Original maintainer
MAINTAINER Sebastian Sasu <sebastian.s@pocketplaylab.com> # This Fork's maintainer

# Install wget and install/updates certificates
RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    ca-certificates \
    wget \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*

# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/^http {/&\n    server_names_hash_bucket_size 128;/g;s/worker_processes  1;/worker_processes auto;/g;s/#gzip  on;/gzip  on;/g;s/access_log  \/var\/log\/nginx\/access.log  main;/access_log  off;/g;s/^http {/&\n    tcp_nodelay on;/g;s/#tcp_nopush     on;/tcp_nopush     on;/g;s/^http {/&\n    server_tokens off;/g;s/^http {/&\n    client_body_buffer_size 2m;/g;s/^http {/&\n    client_max_body_size 50m;/g' /etc/nginx/nginx.conf


# Install Forego
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod u+x /usr/local/bin/forego

# Add proxy parameters
COPY proxy.conf /etc/nginx/proxy.conf

ENV DOCKER_GEN_VERSION 0.7.3

RUN wget https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

COPY . /app/
WORKDIR /app/

ENV DOCKER_HOST unix:///tmp/docker.sock

VOLUME ["/etc/nginx/certs"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
