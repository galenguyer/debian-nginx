FROM debian:buster AS builder
RUN apt-get update -y && \
    apt-get install -y make gcc g++ libmaxminddb0 libmaxminddb-dev libpcre3 \
    libpcre3-dev openssl libssl-dev zlib1g zlib1g-dev libxslt1.1 libxslt1-dev curl git

WORKDIR /src/pcre
ARG PCRE_VER="8.44"
RUN curl -L -O "https://cfhcable.dl.sourceforge.net/project/pcre/pcre/$PCRE_VER/pcre-$PCRE_VER.tar.gz"
RUN tar xzf "/src/pcre/pcre-$PCRE_VER.tar.gz"

# download headers-more-nginx module
RUN git clone https://github.com/openresty/headers-more-nginx-module /src/headers-more-nginx-module

# download ngx_http_geoip2 module
RUN git clone https://github.com/leev/ngx_http_geoip2_module /src/ngx_http_geoip2_module

# download brotli module
RUN git clone https://github.com/google/ngx_brotli /src/ngx_brotli && \
    cd /src/ngx_brotli && \
    git submodule update --init 

# download fancy-index module
RUN git clone https://github.com/aperezdc/ngx-fancyindex.git /src/ngx-fancyindex

# download ngx_http_hs_challenge module
RUN git clone https://github.com/simon987/ngx_http_js_challenge_module.git /src/ngx_http_js_challenge_module 

WORKDIR /src/nginx
ARG NGINX_VER
RUN curl -L -O "http://nginx.org/download/nginx-$NGINX_VER.tar.gz"
RUN tar xzf "nginx-$NGINX_VER.tar.gz"

# configure and build nginx
WORKDIR /src/nginx/nginx-"$NGINX_VER"
RUN ./configure --prefix=/usr/share/nginx \
	--sbin-path=/usr/sbin/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/run/nginx.pid \
	--lock-path=/run/lock/subsys/nginx \
	--http-client-body-temp-path=/tmp/nginx/client \
	--http-proxy-temp-path=/tmp/nginx/proxy \
	--user=www-data \
	--group=www-data \
	--with-threads \
	--with-file-aio \
	--with-pcre="/src/pcre/pcre-$PCRE_VER" \
	--with-pcre-jit \
	--with-http_addition_module \
    --add-module=/src/headers-more-nginx-module \
    --add-module=/src/ngx_http_geoip2_module \
    --add-module=/src/ngx_brotli \
    --add-module=/src/ngx-fancyindex \
    --add-dynamic-module=/src/ngx_http_js_challenge_module \ 
    --with-compat \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
	--with-cc-opt="-Wl,--gc-sections -O2 -ffunction-sections -fdata-sections -fPIC -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security"

ARG CORE_COUNT="1"
RUN make -j"$CORE_COUNT"
RUN make install

FROM debian:buster AS deb
ARG VERSION
WORKDIR /root/
COPY pkg-debian/ ./pkg-debian/
COPY --from=builder /usr/sbin/nginx ./pkg-debian/usr/sbin/nginx
RUN sed -i "s/[{][{] VERSION [}][}]/$VERSION/g" ./pkg-debian/DEBIAN/control
RUN dpkg -b pkg-debian nginx_"$VERSION"_amd64.deb

FROM scratch AS final
ARG VERSION
COPY --from=deb /root/nginx_"$VERSION"_amd64.deb .
