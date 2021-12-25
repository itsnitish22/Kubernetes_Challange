# Digital Ocean K8 Challenge

Repo for the Digital Ocean K8s Challenge

## Challenge

Deploy a Log Monitoring stack. Decided to go with ELK (fairly standard), builidng in Filebeats and Logstash for internal cluster monitoring.

Kibana front-end can be viewed [here](https://159.65.208.143/) (a password is necessary, contact me if you want to view).

## Solution

I decided to undertake this challenge using only Manifests, apart from the deployment of the ECK Operator, for which I used a Helm repo.
Initially started with the deployment of Elasticsearch and Kibana, to ensure a base for the logging stack. The manifest for both are in the file elastic_kibana.yaml.

One thing to note that was a challenge was managing resources. I found myself having to resize my pods regularly as I wanted to deploy more services. Perhaps this is due to my lack of forsight, understanding of node resourcing, or something left to be learned in my way-of-working with Kubernetes.

<p align="center">
  <img src="https://github.com/harrywm/do-k8-challenge/blob/master/resources/dashboard.png?raw=true" alt="Dashboard"/>
</p>

## Working with Digital Ocean and `kubectl`

Configuring `kubectl` to work with Digital Ocean and the associated cluster was simple. Using the `doctl` CLI to configure my Digital Ocean credentials, then following simple instructions on passing the cluster information to my `kubeconfig`, I was quickly able to get started investigating and working with the cluster.

`doctl k8s cluster kubecfg save`

## Notable Debugging 

### Grokin' around the Christmas Tree

During the deployment of Logstash, I found myself spending a lot of time reconfiguring the Logstash Config-map, which contained the Grok filter for filtering logs coming into the pipeline. I tried many different Grok interpreters online but in the end settled on no filter, as I wasn't focusing on any specific logs. Though I do understand the benefit of filters, and can see how they may be applied to aggregated logging across a large microservice architecture using many different technologies.

Interestingly, Kibana dashboards were a hugely beneficial tool in finding and monitoring this issue. I developed a dashboard tracking the count of logs being indexed from Logstash (`index: logstash-*`) in a line graph, and matched against the count of logs being ingested with the tag `_grokfailure`. This allowed me to follow the impact of the changes I was making to the stack. As I re-configured and re-deployed Logstash and Logstash-configmap I could track that logs were in fact being indexed, and how many of them were attributable to a Grok filtering failure!

<p align="center">
  <img src="https://github.com/harrywm/do-k8-challenge/blob/master/resources/grokfailure.png?raw=true" alt="Grok Failure"/>
</p>

### "master_not_discovered_exception"

Resourcing Issues! As mentioned above, I had some trouble with finding the sweet spot for my pod resources. This involved a lot of `kubectl apply -f .`, `kubectl describe nodes` and rejigging of resource requests. You can see what I've settled on in each manifest for the services. This results in a full deployment on the highest spec nodes available on Digital Ocean within the challenge credit range. 

Debugging this was a bit of a task. It started with wondering why I couldn't get a healthcheck from my Elasticsearch URL. 
To make the whole ordeal a bit simpler, I forwarded the Elasticsearch port from the HTTP Service I spun up with the deployment.

<p align="center">
  <img src="https://github.com/harrywm/do-k8-challenge/blob/master/resources/portforward.PNG?raw=true" alt="Port Forwarding"/>
</p>
                                     
This allowed me to reach ES at localhost:9200, rather than having to keep the external IP of the service on hand. 
Hitting any ES endpoint, even a healthcheck, resulted in this painful error: 

`{"error":{"root_cause":[{"type":"master_not_discovered_exception","reason":null}],"type":"master_not_discovered_exception","reason":null},"status":503}`

I later found out this is due to the Elasticsearch cluster configuration not being able to delegate a master node! Which in turn was due to a lack of resources on my K8 nodes, stopping the deployment from being able to achieve 3 pods. 1 master and 2 worker (ES) nodes. Eventually after a few different configuration changes, I settled on a collection of values that worked for the nodes available, while also being able to maintain a Logstash pod, Filebeat daemonset, Kibana deployment and the ECK Operator.

## Resources

 - https://raphaeldelio.medium.com/deploy-the-elastic-stack-in-kubernetes-with-the-elastic-cloud-on-kubernetes-eck-b51f667828f9
 - https://www.digitalocean.com/community/tutorials/how-to-install-elasticsearch-logstash-and-kibana-elastic-stack-on-ubuntu-20-04
 - https://www.densify.com/kubernetes-tools/kubernetes-resource-limits
 - https://opster.com/guides/elasticsearch/operations/elasticsearch-master-node-not-discovered/
 - https://sookocheff.com/post/kubernetes/understanding-kubernetes-networking-model/#pod-to-service
 - https://unofficial-kubernetes.readthedocs.io/en/latest/concepts/workloads/controllers/daemonset/
 - http://www.yamllint.com/
 - https://artifacthub.io/packages/helm/elastic/eck-operator
