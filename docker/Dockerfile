FROM debian:buster-slim

LABEL maintainer="Light Path CDN"

# Build arguments
ARG RESTY_VERSION="1.15.8.2"
ARG RESTY_OPENSSL_VERSION="1.1.1c"
ARG RESTY_PCRE_VERSION="8.43"
ARG RESTY_J="1"
ARG RESTY_CONFIG_OPTIONS="\
    --with-compat \
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    --with-http_slice_module \
    "
ARG RESTY_CONFIG_OPTIONS_MORE="\
    --add-module=/tmp/ngx_http_geoip2_module \
    --add-module=/tmp/ngx_brotli"
ARG RESTY_LUAJIT_OPTIONS="--with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT'"
ARG GREEN="\\033[32m"
ARG NC="\033[0m"

WORKDIR /tmp

# Run system update and install required packages
RUN echo "${GREEN}Running update and installing essential packages${NC}" \
	&& DEBIAN_FRONTEND=noninteractive apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    	build-essential \
    	ca-certificates \
    	curl \
    	gettext-base \
    	libgd-dev \
    	libgeoip-dev \
    	libncurses5-dev \
    	libperl-dev \
    	libreadline-dev \
    	libxslt1-dev \
    	make \
    	perl \
    	unzip \
    	zlib1g-dev \
    	wget \
    	curl \
    	git \
    	build-essential \
    	automake \
    	libtool \
    	libpcre3 \
    	libpcre3-dev \
    	libssl-dev \
    	cmake \
    	libmagickwand-dev \
    && echo "${GREEN}Done installing essential packages${NC}"

# Download and install libmaxmind
RUN echo "${GREEN}Installing Maxmind library${NC}" \
	&& git clone --recursive https://github.com/maxmind/libmaxminddb.git \
	&&  cd libmaxminddb \
	&&  ./bootstrap \
	&&  ./configure \
	&&  make \
	&&  make check \
	&&  make install \
	&&  echo /usr/local/lib  >> /etc/ld.so.conf.d/local.conf \
	&&  ldconfig \
	&&  cd /tmp  \
    && git clone https://github.com/leev/ngx_http_geoip2_module.git \
    && echo "${GREEN}Done installing Maxmind library${NC}"

# Download brotli
RUN echo "${GREEN}Installing Brotli library${NC}" \
	&& git clone --recursive https://github.com/google/brotli.git \
	&& cd brotli \
	&& mkdir out \
	&& cd out \
	&& ../configure-cmake \
	&& make \
	&& make test \
	&& make install \
	&& echo /usr/local/lib >> /etc/ld.so.conf.d/usrlocal.conf \
	&& ldconfig \
	&& cd /tmp \
    && git clone https://github.com/google/ngx_brotli.git \
	&& echo "${GREEN}Done installing Brotli library${NC}"


# Download and install Openresty OpenSSL library
RUN echo "${GREEN}Installing Openresty OpenSSL library${NC}" \
	&& curl -fSL https://www.openssl.org/source/openssl-${RESTY_OPENSSL_VERSION}.tar.gz -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
	&& tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
	&& cd openssl-${RESTY_OPENSSL_VERSION} \
	&& curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-1.1.1c-sess_set_get_cb_yield.patch | patch -p1 \
 	&& ./config \
      no-threads shared zlib -g \
      enable-ssl3 enable-ssl3-method \
      --prefix=/usr/local/openresty/openssl \
      --libdir=lib \
      -Wl,-rpath,/usr/local/openresty/openssl/lib \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install_sw \
    && cd /tmp \
    && echo "${GREEN}Done installing Openresty OpenSSL library${NC}"

# Download and install Openresty PCRE library
RUN echo "${GREEN}Installing Openresty PCRE library${NC}" \
	&& curl -fSL https://ftp.pcre.org/pub/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && cd pcre-${RESTY_PCRE_VERSION} \
    && ./configure \
        --prefix=/usr/local/openresty/pcre \
        --disable-cpp \
        --enable-jit \
        --enable-utf \
        --enable-unicode-properties \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && cd /tmp \
    && echo "${GREEN}Done installing Openresty PCRE library${NC}"

# Download and install Openresty
RUN echo "${GREEN}Installing Openresty${NC}" \
	&& curl -fSL https://github.com/openresty/openresty/releases/download/v${RESTY_VERSION}/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd openresty-${RESTY_VERSION} \
    && eval ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_CONFIG_OPTIONS_MORE} ${RESTY_LUAJIT_OPTIONS} \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && echo "${GREEN}Done installing Openresty${NC}"

# Download and install RocksDb library and lua module
# RUN echo "${GREEN}Instaling RocksDb library${NC}" \
#     && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
#         libgflags-dev \
#         libsnappy-dev \
#         zlib1g-dev \
#         libbz2-dev \
#         liblz4-dev \
#         libzstd-dev \
#     && git clone --branch master --single-branch https://github.com/facebook/rocksdb.git \
#     && cd rocksdb \
#     && echo "${GREEN}Compiling shared library${NC}" \
#     && make shared_lib \
#     && make install-shared \
#     && echo "${GREEN}Compiling static library${NC}" \
#     && make static_lib \
#     && make install-static \
#     && cd ../ \
#     && echo "${GREEN}Done installing RocksDb library${NC}" \
#     && echo "${GREEN} Installing RocksDb module${NC}" \
#     && git clone --recursive https://github.com/zaherm/lua-rocksdb.git \
#     && cd lua-rocksdb \
#     && sed -i "s|INC_PATH= /usr/local/include|INC_PATH= /usr/local/openresty/luajit/include/luajit-2.1|g" Makefile \
#     && sed -i "s|LIB_PATH= /usr/local/lib64|LIB_PATH= /usr/local/openresty/lualib|g" Makefile \
#     && make \
#     && make test \
#     && make install \
#     && cd /tmp \
#     && echo "${GREEN}Done installing RocksDb module{$NC}"

# Cleanup
RUN echo "${GREEN}Cleaing up installation${NC}" \
	&& rm -rf /tmp/* \
	&& DEBIAN_FRONTEND=noninteractive apt-get autoremove -y \
    && mkdir -p /var/run/openresty \
    && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log \
    && echo "${GREEN}Build finished, goodbye!${NC}"

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

# Copy default config files
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY nginx.vh.default.conf /etc/nginx/conf.d/default.conf

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

STOPSIGNAL SIGQUIT