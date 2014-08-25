# Standalone Apache Giraph Docker image

The graph processing system Giraph takes some effort to get set up properly. We built this image to make it easier to try things out on Giraph. It's based on the SequenceIQ pseudo-distributed standalone [Hadoop Docker image](https://registry.hub.docker.com/u/sequenceiq/hadoop-docker/). 

This image is built using a snapshot of the Giraph repo for compatibility with Hadoop 2.4.x and Yarn. When a Giraph release supports these versions, we will switch to that.

## Using the image

### Pull the image

The image is released through Docker's automated build repository. You can get it like this:

```
docker pull uwsampa/giraph-docker
```

### Start a container

Once you've pulled the image, you can run it like this:

```
docker run --volume $HOME:/myhome --rm --interactive --tty uwsampa/giraph-docker /etc/giraph-bootstrap.sh -bash
```
Once it starts you'll be at a root prompt where you can run Giraph jobs.

(Explanation of flags: the ```--volume $HOME:/myhome``` flag maps your home directory outside the container to the ```/myhome``` directory inside the container. The ```--rm``` flag cleans up the image once you shut it down so it doesn't take up disk space. The ```--interactive``` and ```--tty``` flags make the container behave as you'd expect for human usage. ```uwsampa/giraph-docker``` is the name of the image. ```/etc/giraph-bootstrap.sh``` is the script that starts the Hadoop and Zookeeper daemons, and with the ```-bash``` option it dumps you into a shell so you can use them.)

### Running an example

Here's how to run the Giraph single-source shortest paths example app on a small dataset.

First, change to the Giraph source directory.
```
cd $GIRAPH_HOME
```

Now, prepare some input. We've left a simple example graph in this directory; to process it with Giraph you must first copy it into HDFS:
```
$HADOOP_HOME/bin/hdfs dfs -put tiny-graph.txt /user/root/input/tiny-graph.txt
```

Now we can run the example:
```
$HADOOP_HOME/bin/hadoop jar $GIRAPH_HOME/giraph-examples/target/giraph-examples-1.1.0-SNAPSHOT-for-hadoop-2.4.1-jar-with-dependencies.jar org.apache.giraph.GiraphRunner org.apache.giraph.examples.SimpleShortestPathsComputation --yarnjars giraph-examples-1.1.0-SNAPSHOT-for-hadoop-2.4.1-jar-with-dependencies.jar --workers 1 --vertexInputFormat org.apache.giraph.io.formats.JsonLongDoubleFloatDoubleVertexInputFormat --vertexInputPath /user/root/input/tiny-graph.txt -vertexOutputFormat org.apache.giraph.io.formats.IdWithValueTextOutputFormat --outputPath /user/root/output
```

Eventually you'll see ```Completed Giraph: org.apache.giraph.examples.SimpleShortestPathsComputation: SUCCEEDED```. Now you can examine the output:
```
$HADOOP_HOME/bin/hdfs dfs -cat /user/root/output/part-m-00001
```

### Compiling and running your own Giraph code

Here's how to build a simple example. We'll use a quick-and-dirty method to build a jar file containing all necessary Giraph code along with our code by copying the Giraph examples jar with dependences and adding our code to that.

First we'll create a workspace using the directory you mapped inside the container. Create a working directory outside the container in your home directory (which we mapped inside the container), along with a package directory for your code:
```
mkdir $HOME/giraph-work
mkdir $HOME/giraph-work/mypackage
```

Our example will be a simple computation that just updates weights on vertices and passes the graph through unmodified. Put the following example code in ```$HOME/giraph-work/mypackage/DummyComputation.java```:
```java
package mypackage;

import org.apache.giraph.graph.BasicComputation;
import org.apache.giraph.graph.Vertex;
import org.apache.hadoop.io.Writable;
import org.apache.hadoop.io.WritableComparable;

import org.apache.giraph.conf.LongConfOption;
import org.apache.giraph.edge.Edge;
import org.apache.hadoop.io.DoubleWritable;
import org.apache.hadoop.io.FloatWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.log4j.Logger;

import java.io.IOException;

public class DummyComputation extends BasicComputation<
        LongWritable, DoubleWritable, FloatWritable, DoubleWritable> {
    @Override
    public void compute(Vertex<LongWritable, DoubleWritable, FloatWritable> vertex,
                        Iterable<DoubleWritable> messages) throws IOException {
        vertex.setValue(new DoubleWritable(1.0));
        vertex.voteToHalt();
    }
}
```

Now, go inside the container and compile the code. Set the classpath to include both the Giraph examples jar with dependences along with the auto-generated Hadoop classpath:
```
cd /myhome
javac -cp /usr/local/giraph/giraph-examples/target/giraph-examples-1.1.0-SNAPSHOT-for-hadoop-2.4.1-jar-with-dependencies.jar:$($HADOOP_HOME/bin/hadoop classpath) mypackage/DummyComputation.java
```

Now, we'll make a copy of the Giraph examples jar and add our class files to it.
```
cp /usr/local/giraph/giraph-examples/target/giraph-examples-1.1.0-SNAPSHOT-for-hadoop-2.4.1-jar-with-dependencies.jar ./myjar.jar
jar uf myjar.jar mypackage
```

Now we can run the code using the extended jar file:
```
$HADOOP_HOME/bin/hadoop jar myjar.jar org.apache.giraph.GiraphRunner mypackage.DummyComputation --yarnjars myjar.jar --workers 1 --vertexInputFormat org.apache.giraph.io.formats.JsonLongDoubleFloatDoubleVertexInputFormat --vertexInputPath /user/root/input/tiny-graph.txt -vertexOutputFormat org.apache.giraph.io.formats.IdWithValueTextOutputFormat --outputPath /user/root/dummy-output
```
