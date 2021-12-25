# Digital Ocean Kubernetes Challenge

Repo for the Digital Ocean K8s Challenge

## Challenge

Deploy a Log Monitoring system.

## Solution

We will store our state in a space bucket (Equivalent to an S3 bucket)
Head to spaces and create a space named kube-terraform-state
Generate an API key for your doctl tool.
API -> Generate New Token
Make it read/write as it will be used for all the operations we will be doing.
Configure your doctl tool.
Clone the project repository
git clone https://github.com/duchaineo1/digitalocean-k8s-challenge
Explore the Terraform files
In provider.tf we’re defining the provider we will be using (digitalocean in this case) and we’re defining the variable for the token we created in step 2.
In main.tf we’re defining our backend, that’s where our state will be stored. Keeping it local wouldn’t be the end of the world in this case but it’s nice to know the state is stored in a safe place. Committing it is risky/bad practice because some secrets can get in the state file. We’re then defining the actual cluster from line 13 to 21.
Init and apply
terraform init
terraform apply enter the token you created in step 2 and confirm.
The init directive should tell you it initialized the backend in the bucket. The apply will take a couple of minutes before your cluster is provisioned.
Generate your .kubeconfig file
doctl kubernetes cluster kubeconfig save do-kubernetes-challenge
I named my cluster do-kubernetes-challenge so if you changed it in main.tf make sure to change your command accordingly.
This will replace (or create) your ~/.kube/config and enable you to use kubectl commands against your cluster.
Test using kubectl cluster-info
Provisioning our ELK stack
There is multiple .yml files defining our stack in the elk-stack directory. Feel free to adjust to your needs, I’ve created a bash script to provision all of them at once.
chmod +x provisioning.sh && ./provisioning.sh
After a couple of minutes validate the state of our stack kubectl -n kube-logging get pods
Your nodes need at least 2gb of ram to be able to handle Elasticsearch, if you have made no change to the main.tf file your cluster should be fine.
I used this documentation for the basis of the stack. Some basic modifications and some debugging was required to make it work.
Configure Kibana
kubectl -n kube-logging get pods
Copy the kibana container name
Port-forward the kibana container to localhost
kubectl -n kube-logging port-forward <kibana-container-name> 5601:5601
Open a browser to localhost:5601
Configure index pattern
Bottom left Management -> Index Pattern -> Create Index Pattern
Add logstash-*
Choose a filter and create the index
View your data
Top left corner Discover
You should see logs generated with the data associated with it.
Create a custom container
Let’s test with a custom container with some specific output. In this case it will be a counter with the date and my username (change it to yours in log-producer.yml).
kubectl apply -f log-producer.yml
Filtering by the container name and the stdout of the container should be available in your Kibana.
