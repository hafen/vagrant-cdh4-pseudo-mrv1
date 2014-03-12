source /vagrant/install-java.sh

echo Install packages

sudo -E apt-get --yes --force-yes update
sudo -E apt-get --yes --force-yes install curl wget
sudo -E mkdir -p /etc/apt/sources.list.d
sudo -E touch /etc/apt/sources.list.d/cloudera.list
echo "deb [arch=amd64] http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh precise-cdh4 contrib" > /etc/apt/sources.list.d/cloudera.list
echo "deb-src http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh precise-cdh4 contrib" >> /etc/apt/sources.list.d/cloudera.list
curl -s http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh/archive.key > precise.key
sudo -E apt-key add precise.key
sudo -E apt-get --yes --force-yes update
sudo -E apt-get --yes --force-yes install hadoop-0.20-conf-pseudo
dpkg -L hadoop-0.20-conf-pseudo
ls /etc/hadoop/conf.pseudo.mr1

echo Stop all

for x in `cd /etc/init.d ; ls hadoop-0.20-mapreduce-*` ; do sudo -E service $x stop ; done
for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo -E service $x stop ; done

echo Edit config files

sudo -E sed -i 's/localhost:8020/192.168.56.20:8020/g' /etc/hadoop/conf/core-site.xml
sudo -E sed -i 's/localhost:8020/192.168.56.20:8020/g' /etc/hadoop/conf.pseudo.mr1/core-site.xml

sudo -E sed -i 's/localhost:8021/192.168.56.20:8021/g' /etc/hadoop/conf/mapred-site.xml
sudo -E sed -i 's/localhost:8021/192.168.56.20:8021/g' /etc/hadoop/conf.pseudo.mr1/mapred-site.xml

echo "export JAVA_HOME=/opt/jdk1.6.0_45" | sudo -E tee -a /etc/default/hadoop

echo Format namenode

sudo -E -u hdfs hdfs namenode -format

echo Start HDFS

for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo -E service $x start ; done

sudo -E -u hdfs hadoop fs -mkdir /tmp
sudo -E -u hdfs hadoop fs -chmod -R 1777 /tmp

sudo -E -u hdfs hadoop fs -mkdir -p /var/lib/hadoop-hdfs/cache/mapred/mapred/staging
sudo -E -u hdfs hadoop fs -chmod 1777 /var/lib/hadoop-hdfs/cache/mapred/mapred/staging
sudo -E -u hdfs hadoop fs -chown -R mapred /var/lib/hadoop-hdfs/cache/mapred

sudo -E -u hdfs hadoop fs -ls -R /

sudo -E -u hdfs hadoop fs -mkdir /user/hdfs 
sudo -E -u hdfs hadoop fs -chown hdfs /user/hdfs

echo Start MapReduce

for x in `cd /etc/init.d ; ls hadoop-0.20-mapreduce-*` ; do sudo -E service $x start ; done

## install other components

sudo apt-get --yes --force-yes install git
sudo apt-get --yes --force-yes install ant
sudo apt-get --yes --force-yes install maven

## install R 3.0.3

CRAN=${CRAN:-"http://cran.rstudio.com"}
OS=$(uname -s)

PATH="${PATH}:/usr/texbin"

R_BUILD_ARGS=${R_BUILD_ARGS-"--no-build-vignettes --no-manual"}
R_CHECK_ARGS=${R_CHECK_ARGS-"--no-build-vignettes --no-manual --as-cran"}

sudo apt-get --yes --force-yes install software-properties-common
sudo apt-get --yes --force-yes install python-software-properties

# Set up our CRAN mirror.
sudo add-apt-repository "deb ${CRAN}/bin/linux/ubuntu $(lsb_release -cs)/"
sudo gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E084DAB9

# Add marutter's c2d4u repository.
sudo add-apt-repository -y "ppa:marutter/rrutter"
sudo add-apt-repository -y "ppa:marutter/c2d4u"

# Update after adding all repositories.  Retry several times to work around
# flaky connection to Launchpad PPAs.
sudo apt-get --yes --force-yes update -qq

# Install an R development environment. qpdf is also needed for
# --as-cran checks:
#   https://stat.ethz.ch/pipermail/r-help//2012-September/335676.html
sudo apt-get --yes --force-yes install --no-install-recommends r-base-dev r-recommended qpdf

# Change permissions for /usr/local/lib/R/site-library
# This should really be via 'staff adduser travis staff'
# but that may affect only the next shell
sudo chmod 2777 /usr/local/lib/R /usr/local/lib/R/site-library



