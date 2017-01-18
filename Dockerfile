FROM resin/rpi-raspbian:jessie

MAINTAINER "Lisa Ridley, lhridley@gmail.com"

## Dockerized version of https://gist.github.com/Lewiscowles1986/27cfeda001bb75a9151b5c974c2318bc

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
    bison

RUN cd /tmp \
 && git clone -b 10.1 https://github.com/MariaDB/server.git --depth=1 mariadb-server-src \
 && cd mariadb-server-src \
 && cmake -DWITH_WSREP=ON -DWITH_INNODB_DISALLOW_WRITES=ON ./ \
 && make \
 && make install \

 && cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld \
 && update-rc.d mysqld defaults

RUN echo "export PATH=\${PATH}:/usr/local/mysql/bin/" > /etc/profile.d/mysql \
 && groupadd mysql && useradd -g mysql mysql \
 && mkdir -p /srv/mysql \

 && rm -rf /etc/mysql \
 && install -v -dm 755 /etc/mysql \
 && cat > /etc/mysql/my.cnf << "EOF"
# Begin /etc/mysql/my.cnf

# The following options will be passed to all MySQL clients
[client]
#password       = your_password
port            = 3306
socket          = /run/mysqld/mysqld.sock

# The MySQL server
[mysqld]
port            = 3306
socket          = /run/mysqld/mysqld.sock
datadir         = /srv/mysql
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
sort_buffer_size = 512K
net_buffer_length = 16K
myisam_sort_buffer_size = 8M

# Don't listen on a TCP/IP port at all.
skip-networking

# required unique id between 1 and 2^32 - 1
server-id       = 1

# Uncomment the following if you are using BDB tables
#bdb_cache_size = 4M
#bdb_max_lock = 10000

# InnoDB tables are now used by default
innodb_data_home_dir = /srv/mysql
innodb_data_file_path = ibdata1:10M:autoextend
innodb_log_group_home_dir = /srv/mysql
# You can set .._buffer_pool_size up to 50 - 80 %
# of RAM but beware of setting memory usage too high
innodb_buffer_pool_size = 16M
innodb_additional_mem_pool_size = 2M
# Set .._log_file_size to 25 % of buffer pool size
innodb_log_file_size = 5M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash
# Remove the next comment character if you are not familiar with SQL
#safe-updates

[isamchk]
key_buffer = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout

# End /etc/mysql/my.cnf
EOF \

 && source /etc/profile.d/mysql \
 && /usr/local/mysql/scripts/mysql_install_db --user=mysql --datadir=/srv/mysql --basedir=/usr/local/mysql \
 && chown -R mysql:mysql /srv/mysql \
 && apt-get install -y libboost-program-options-dev check

RUN cd /tmp \
 && git clone https://github.com/codership/galera --depth=1 \
 && cd galera \
 && scons
