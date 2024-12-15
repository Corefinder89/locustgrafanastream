# Generating a live stream grafana dashboard for Locust

## Description

This is an article which defines how to generate a live dashboard which streams data from locust using locust exporter 
and uses a time series db to store the perf data which then gets ingested by grafana to show the respective dashboard. 

## Brief

When we do a load test, we want to see the results instantly in the metrics we want. We may need to focus on a different 
metric in each load test. We need to be able to edit these metrics optionally and do customization on them. In this 
article, we will learn how to do load tests with locust, export metrics instantly with Prometheus, and show the metrics 
we want in Grafana.

First of all, what is this locust; Locust is an easy-to-use, scriptable and scalable performance testing tool. 
You define the behavior of your users in regular Python code, instead of using a clunky UI or domain-specific language.
In this test, we will use https://jsonplaceholder.typicode.com/ as the fake API. If you want to examine the details, 
you can see here what kind of fake API it is.

Now let’s prepare a simple test with locust. In a simple way, as you can see below, we determine on which endpoints 
we will simulate our load test with a simple piece of [code](load_tests/loadtest.py).

Use the codeblock to configure locust using the docker image

```docker
  locust:
    image: locustio/locust
    ports:
      - "8089:8089"
    volumes:
      - ./load_tests/:/mnt/locust
    command: -f /mnt/locust/loadtest.py
```

After running the docker-compose up command, we access our locust panel from the specified port.

![](images/locust.png)

After entering our values ​​according to the metrics we mentioned here, we can run our test. These are x 
concurrent users, hatch rate of 1 user/s, and host. When we start the test, we can see that it works somehow without 
any errors.

![](images/locustmetrics.png)

Now we need to export the locust metrics for Grafana because you need to perform the metric flow between locust and 
Grafana with a real-time tool. In this article, we will do it with Prometheus. First, we will use the exporter that 
`ContainerSolution` has prepared as a locust-exporter. If you want to examine it in more detail, you can reach here and 
create a different exporter for yourself. As you can see below, we update docker-compose.yml again. This time we 
integrate the locust-exporter and define our local locust as the environment.

```docker
  locust-metrics-exporter:
    image: containersol/locust_exporter
    ports:
      - "9646:9646"
    environment:
      - LOCUST_EXPORTER_URI=http://locust:8089
    depends_on:
      - locust
```

And as always — run docker-compose up. We should be able to see metrics under 
http://localhost:9646/metrics.

![](images/locust-exporter.png)

Let’s look at how we integrate Prometheus and send these metrics.
First, we need to create a Prometheus config file and here we determine where and how many seconds you will receive the 
data. (prometheus.yml)

```yml
scrape_configs:
- job_name: prometheus_scrapper
  scrape_interval: 5s
  static_configs:
    - targets:
        - locust-metrics-exporter:9646
```
Then, we update our docker-compose.yml file and do the Prometheus integration as follows.

```docker
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro  # Mount the config file
    ports:
      - "9090:9090"  # Expose Prometheus on port 9090
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'  # Explicit config file path
    restart: unless-stopped
```
Now it’s time to see our metrics on Prometheus, we start our load test and check whether the metrics are Prometheus.

![](images/prometheus.png)

Once this is done we can now use prometheus as the data source to visualize the data using graphana. Now since graphana
is already available in as a docker image we will be using docker compose to pull the docker image.

```docker
grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN=admin
      - GF_SECURITY_PASSWORD=admin
    restart: unless-stopped
volumes:
  grafana_data:  # Define the named volume here
```

![](images/grafana.png)

