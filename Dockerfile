FROM resin/rpi-raspbian:jessie

MAINTAINER "Lisa Ridley, lhridley@gmail.com"

## Some borrowed from https://gist.github.com/Lewiscowles1986/27cfeda001bb75a9151b5c974c2318bc
## The rest from https://github.com/hypriot/rpi-mysql/blob/master/Dockerfile

ENV MYSQL_VERSION 5.5

RUN echo "deb http://mirrordirector.raspbian.org/raspbian/ stretch main contrib non-free rpi" > /etc/apt/sources.list.d/stretch.list \
 && echo "APT::Default-Release \"jessie\";" > /etc/apt/apt.conf.d/99-default-release \

 && apt-get update -y && apt-get upgrade -y \
 && apt-get dist-upgrade -y \
 && apt-get install -y \
    build-essential \
    git \
    cmake \
    scons \
    rpi-update \
    libarchive-dev \
    libevent-dev \
    libssl-dev \
    libboost-dev \
 && apt-get install -t stretch -y \
    libncurses5-dev \
    libbison-dev \
    bison \

 # FATAL ERROR: please install the following Perl modules before executing /usr/local/mysql/scripts/mysql_install_db:
 # File::Basename
 # File::Copy
 # Sys::Hostname
 # Data::Dumper
 && apt-get install -y perl --no-install-recommends && rm -rf /var/lib/apt/lists/* \

 # the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
 # also, we set debconf keys to make APT a little quieter
 && { \
 		echo mysql-server mysql-server/data-dir select ''; \
 		echo mysql-server mysql-server/root-pass password ''; \
 		echo mysql-server mysql-server/re-root-pass password ''; \
 		echo mysql-server mysql-server/remove-test-db select false; \
 	} | debconf-set-selections \
 	&& apt-get update && apt-get install -y mysql-server="${MYSQL_VERSION}"* && rm -rf /var/lib/apt/lists/* \
 	&& rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql \

 && echo "export PATH=\${PATH}:/usr/local/mysql/bin/" > /etc/profile.d/mysql \
 #&& groupadd mysql && useradd -g mysql mysql \

 && rm -rf /etc/mysql \
 && install -v -dm 755 /etc/mysql \
 && { \
echo '# Begin /etc/mysql/my.cnf'; \
echo '# The following options will be passed to all MySQL clients'; \
echo '[client]'; \
echo '#password       = your_password'; \
echo 'port            = 3306'; \
echo 'socket          = /run/mysqld/mysqld.sock'; \
echo ''; \
echo '# The MySQL server'; \
echo '[mysqld]'; \
echo 'port            = 3306'; \
echo 'socket          = /run/mysqld/mysqld.sock'; \
echo 'datadir         = /srv/mysql'; \
echo 'skip-external-locking'; \
echo 'key_buffer_size = 16M'; \
echo 'max_allowed_packet = 1M'; \
echo 'sort_buffer_size = 512K'; \
echo 'net_buffer_length = 16K'; \
echo 'myisam_sort_buffer_size = 8M'; \
echo ''; \
echo '# Dont listen on a TCP/IP port at all.'; \
echo 'skip-networking'; \
echo ''; \
echo '# required unique id between 1 and 2 to the 32 - 1'; \
echo 'server-id       = 1'; \
echo ''; \
echo '# Uncomment the following if you are using BDB tables'; \
echo '#bdb_cache_size = 4M'; \
echo '#bdb_max_lock = 10000'; \
echo ''; \
echo '# InnoDB tables are now used by default'; \
echo 'innodb_data_home_dir = /srv/mysql'; \
echo 'innodb_data_file_path = ibdata1:10M:autoextend'; \
echo 'innodb_log_group_home_dir = /srv/mysql'; \
echo '# You can set .._buffer_pool_size up to 50 - 80 %'; \
echo '# of RAM but beware of setting memory usage too high'; \
echo 'innodb_buffer_pool_size = 16M'; \
echo 'innodb_additional_mem_pool_size = 2M'; \
echo '# Set .._log_file_size to 25 % of buffer pool size'; \
echo 'innodb_log_file_size = 5M'; \
echo 'innodb_log_buffer_size = 8M'; \
echo 'innodb_flush_log_at_trx_commit = 1'; \
echo 'innodb_lock_wait_timeout = 50'; \
echo ''; \
echo '[mysqldump]'; \
echo 'quick'; \
echo 'max_allowed_packet = 16M'; \
echo ''; \
echo '[mysql]'; \
echo 'no-auto-rehash'; \
echo '# Remove the next comment character if you are not familiar with SQL'; \
echo '#safe-updates'; \
echo ''; \
echo '[isamchk]'; \
echo 'key_buffer = 20M'; \
echo 'sort_buffer_size = 20M'; \
echo 'read_buffer = 2M'; \
echo 'write_buffer = 2M'; \
echo ''; \
echo '[myisamchk]'; \
echo 'key_buffer_size = 20M'; \
echo 'sort_buffer_size = 20M'; \
echo 'read_buffer = 2M'; \
echo 'write_buffer = 2M'; \
echo ''; \
echo '[mysqlhotcopy]'; \
echo 'interactive-timeout'; \
echo ''; \
echo '# End /etc/mysql/my.cnf'; \
} > /etc/mysql/my.cnf \

# && source /etc/profile.d/mysql \
 && /usr/local/mysql/scripts/mysql_install_db --user=mysql --datadir=/srv/mysql --basedir=/usr/local/mysql \
 && chown -R mysql:mysql /srv/mysql \
 && apt-get install -y libboost-program-options-dev check

 && cd /tmp \
 && git clone https://github.com/codership/galera --depth=1 \
 && cd galera \
 && scons

 && apt-get purge -y --auto-remove \
     build-essential \
     git \
     cmake \
     scons \
     rpi-update \
     libarchive-dev \
     libevent-dev \
     libssl-dev \
     libboost-dev \
     libncurses5-dev \
     libbison-dev \
     bison

VOLUME /var/lib/mysql

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 3306 4567 4568 4444 13306

CMD ["mysqld"]