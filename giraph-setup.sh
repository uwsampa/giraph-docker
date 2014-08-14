#!/bin/bash

# exit on error
set -o errexit

PREFIX=/usr/local

# TODO: do this in hadoop docker instance
echo Ensure Java 1.7 stays set as default....
alternatives --install /usr/bin/java java /usr/java/latest/bin/java 1
alternatives --set java /usr/java/latest/bin/java
alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 1
alternatives --set javac /usr/java/latest/bin/javac

echo Installing maven....
curl -L# https://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo > /etc/yum.repos.d/epel-apache-maven.repo
yum install -y maven2

echo Installing prebuilt Giraph....
curl -L# 'http://grappa.cs.washington.edu/files/giraph-1.1.0-bc9f823e23d110d3c54d6eb0f5ccf7eff155a6b7-prebuilt.tar.bz2' | tar -xj -C $PREFIX
ln -s $PREFIX/giraph-1.1.0-HEAD $PREFIX/giraph

echo Installing Zookeeper....
curl -L# 'http://apache.claz.org/zookeeper/current/zookeeper-3.4.6.tar.gz' | tar -xz -C $PREFIX
ln -s $PREFIX/zookeeper-3.4.6 $PREFIX/zookeeper
