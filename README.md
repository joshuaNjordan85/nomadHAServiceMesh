# Nomad Hybrid Mesh Demo

## Tools
- [Nomad](https://github.com/hashicorp/nomad): _OSS or Enterprise_
- [Consul](https://github.com/hashicorp/consul): _OSS or Enterprise_
- Terraform: _[OSS](https://github.com/hashicorp/terraform) or [Enterprise](https://www.terraform.io/docs/enterprise/index.html)_
- [Consul-Template](https://github.com/hashicorp/consul-template) _OSS_
- [JQ](https://stedolan.github.io/jq/) _OSS_
- [NGINX](https://nginx.org/en/) _OSS_
- SIMPLEGOAPI _I decided to add the code here directly because it's a single file_: main.go

```go
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"github.com/julienschmidt/httprouter"
)

// get consul-template json file and send it back
func sendBackJobStats(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	http.ServeFile(w, r, "goStats/stats.json")
}

func main() {
	router := httprouter.New()
	router.GET("/", sendBackJobStats)
	port := fmt.Sprintf(":%s", os.Getenv("PORT"))
	log.Fatal(http.ListenAndServe(port, router))
}
```

**ABOUT GO-API**: You will [need to compile the binary for your architecture](https://www.digitalocean.com/community/tutorials/how-to-build-go-executables-for-multiple-platforms-on-ubuntu-16-04#step-4-%E2%80%94-building-executables-for-different-architectures) and you will need to make sure you have your [go environment set up correctly](https://golang.org/doc/install). Also, if you want to deploy some other binary, go for it.  

## Purpose
We want to use Nomad, Consul, Consul-Template, & NGINX to create a HA service-mesh architecture with containerized and non-containerized applications.

## Provision

### **BEFORE YOU BEGIN**
- _I've set up this demo with GCP, if you are not going to use GCP, then you need to get 9 nodes up in an environment somewhere with the associated network and firewall parameters applied. If you want to leverage IaC(Infrastructure As Code), you can check out Terraform's list of [providers](https://www.terraform.io/docs/providers/index.html) to see your cloud's spec exists._

- _If you don't want to use IaC, then provision in whatever way you feel comfortable. All of the necessary dependencies to run the demo can be applied to nodes post provisioning with the helpers I've included in the ```scripts/``` dir._

- _With that said, those who are very familiar with Terraform will notice that I've excluded [provisioners](https://www.terraform.io/docs/provisioners/index.html) from this repo, which is to say I'm not leveraging the provisioning block to install dependencies as an automated post provisioning workflow step. Please feel free to use this workflow if you want with a configuration manager or script of your choice. You could leverage [Packer](https://github.com/hashicorp/packer) as well, but I leave all that up to you._

### Spin Up
**READ_FIRST** _For this demo, I'm leveraging my ssh key for all access to everything I provision. You may want to restrict this type of access for production deployments. GCP automatically assigns my sudo user for ssh after I've provisioned as well, so if this is not the behavior of your cloud, then you will have to manage a non-root sudo user for ssh access._

To begin, you want to provision the cluster. You should read the ```main.tf``` file, then make necessary changes before running ```terraform init```. If all is good, follow up with ```terraform plan```, then ```terraform apply``` if there are no errors. Soon enough you should be able to ssh into your nodes.

### Deps Mgmt
Now we want to push all the dependencies to our nodes. You can leverage the ```scripts/distributeFile.sh``` script, terraform's providers block, a configuration manager, or some other means to accomplish this task.

The dependency breakdown is as follows:
- Consul:
  - every node needs the [consul binary](https://github.com/hashicorp/consul) _OSS reference_
  - 3 nodes run the consul agent in server mode:
    - configuration files:
      - ```configuration/consul.d/server.json```
      - ```configuration/systemd/consul-server.service```
  - 6 nodes run the consul agent in client mode:
    - configuration files:
      - ```configuration/consul.d/client.json```
      - ```configuration/systemd/consul-client.service```
- Nomad:
  - 6 nodes _not consul_ need the [nomad binary](https://github.com/hashicorp/nomad) _OSS reference_
  - 3 nodes run the nomad agent in server mode:
    - configuration files:
     - ```configuration/nomad.d/server.hcl```
     - ```configuration/systemd/nomad.service``` _pay attention to Unit file server or client hcl_
  - 3 nodes run the nomad agent in client mode:
    - these nodes have [nginx](https://www.nginx.com/resources/wiki/start/topics/tutorials/install/)
    - these nodes have [consul-template](https://github.com/hashicorp/consul-template)
    - these nodes have [simpleGoAPI]()
    - these nodes have [docker](https://docs.docker.com/install/linux/docker-ce/debian/) _check your version; I was using Debian_
    - configuration files:
      - ```configuration/nomad.d/client.hcl```
      - ```configuration/systemd/nomad.service``` _pay attention to Unit file server or client hcl_
      - ```configuration/systemd/consul-template.service```
      - ```loadBalancer/nginx.conf.tpl```

## Do Things

### System D on Nodes
Once you've set everything up, you have to run it, so, on each respective server make sure you run the following _this obviously depends on the previous dependencies you've deployed_

- ```sudo systemctl start consul-<client || server>.service```
  - _run consul servers first_
  - _then run all the consul clients_
- ```sudo systemctl start nomad.service```
- ```sudo systemctl start consul-template.service```
- ```sudo systemctl start nginx```
- _you can always check the status of any systemd service with ```sudo systemctl status <serviceName>```_

Make sure everything is up and running, open a browser and navigate to:
- Consul: ```<whateverYourIpIs>:8500```
- Nomad: ```<whateverYourIpIs>:4646/ui```

If you see things, then you did it right. Consul should have some nomad services up and running. Now it's time to move into the Orchestration part.

### Env Vars
Set some environment variables for your local machine so that you can more easily interact with the nomad environment.

- export NOMAD_SERVER_LEADER=<whateverIPThisIs>
- export NOMAD_ADDR=http://$NOMAD_SERVER_LEADER
- export NOMAD_CLIENT_1, 2, 3=<whateverIPs>
- export REMOTE_SUDO_USER=<theUserYouSetUpForSSH>

### Web Server
Let's start by peeking at the nginx conf on one of the nomad clients. You can leverage the inspectFile script included in this repo to do so.

```
. scripts/inspectRemoteFile.sh $NOMAD_CLIENT_<pick> /etc/nginx/conf.d/default.conf
```
You should see that both the / and /api paths in the nginx configuration are pointing to an upstream definition. These definition blocks should only have one ip listed and, if you were to navigate to the client ui, you would see a 502 network error. This isn't a bad thing, it just means that nginx can't find anything to route to because the consul-template definition supplied a default in case no services were discovered by our client agents running in our cluster.

Now take a look at the web server job ```configuration/job/web-server.nomad```. Go ahead and plan it ```nomad job plan configuration/job/web-server.nomad```, then, if all is well, run it ```nomad job run configuration/job/web-server.nomad```. You should get alloc text in the cli to confirm all is well.

You can navigate to the nomad ui ```<whateverYourServerIpIs>:4646/ui``` and watch the status of your deployment. After the job is complete and everything is running, you can take a peek at any of the nginx files on the nomad clients again.

```
. scripts/inspectRemoteFile.sh $NOMAD_CLIENT_<pick> /etc/nginx/conf.d/default.conf
```

Now you will see that our upstream definitions are populated with ip addresses. If you left the group count in the web-server.nomad file at 15, then you will see 15 ip addresses in the webserver upstream block.

Because Nomad automatically registers services with consul according to the job-group-task names of the files you deploy, consul-template will read the discovered values and rewrite the default.conf file used by nginx on all of your nomad client nodes.

If this were production, you could simply point your domain's A records to each of your nomad client IPs and drop all internet traffic into your service mesh. Let's go see what we've deployed!

Open a browser and navigate to one or all of your nomad clients. You should see some metrics at the top of the dashboard that is displayed. Now...refresh the screen, as many times as you like, paying careful attention to the metrics at the top. Notice how the client name, ip, and port change? This is a live running example of HA inside a service mesh. It doesn't matter if you hit the application from nomad client 0, you may still hit the container that holds the service from nomad client 1 or 2.

### GO API
Take a look at the ```configuration/jobs/simpleGoAPI.nomad``` file. Notice this isn't being run in a Docker container, we are running it as an [exec](https://www.nomadproject.io/docs/drivers/exec.html) system job. Issue the ```nomad job plan configuration/jobs/simpleGoAPI.nomad``` and ```nomad job run configuration/jobs/simpleGoAPI.nomad``` commands, ensure that the alloc ids were created in the cli, then navigate to the nomad server ui and check on the status of the services.

Again, leverage the inspectRemoteFile script to investigate the contents of the nginx default.conf file on one of the nomad servers. Again, as before, you will now see ip addresses in the goapi upstream block.

If you navigate back to the nomad client from a web browser, you should be able to click on the button and receive the same type of metric data from the go services deployed in your cluster. As before, you should get multiple values for node name, ip, and ports as a different service is requested across all of your nomad clients, regardless of whatever nomad client you made the request from.

_If you don't get multiple values from the goApi services by clicking the button, then you can navigate to http://$NOMAD_CLIENT_[0,1,2]/api and see the data change more readily_

## Let's Bin Pack
Now we need to check on the bin packing component of nomad. First, let's check the utilization of a service by getting it's allocation id. Run the following:
```
nomad status <web-server || nomad status go-api>
```

Regardless of which job you decided to check on, you will get a list of allocation ids back as output. Copy one of those allocation ids and run:

```
nomad alloc status -stats <alloc id>
```

You should be able to read about the usage of your service, such as it's cpu or memory utilization. The allocated memory for either job is probably way too high, so, you should go back to your job file and adjust the resources block:

```
resources {
  memory = 20
  cpu = 20
  ... whatever else was already here
}
```

Now that you've done this, you can ```nomad job plan configuration/jobs/<whichEverOneYouChose.nomad>``` and see the state changes in the output. Next, ```nomad job run configuration/jobs/<whichEverOneYouChose.nomad>``` and wait for your services to deploy.

After your services are running, you can peek into their utilization again:

```
nomad status <web-server || go-api>
```

Pick an alloc id and then...

```
nomad alloc status -stats <allocId>
```

You should be able to see the new allocation of resources applied to your service. Feel free to tinker with this as much as you want.

Now that we understand how to apply monitoring and editing of our resource footprints in our cluster, we can start to add large counts to our deployment. In either, or both of your job files, under the group, change the count to something greater. You can start with 50, but it's ultimately up to you at this point. If the resource limits are too high, when you run ```nomad job plan configuration/jobs/<whichEverOneYouChose>.nomad``` the output will let you know about it and you can make the necessary adjustments.

At this point, you've effectively deployed a nomad cluster in a single region and set up a highly available mesh network of 2 services: 1 for Docker; the other as a compiled binary written in golang. You've messed around with bin packing too, which, even though the use case of 50 or more trivial go apis and web-servers isn't very realistic, it certainly demonstrates how we can leverage nomad to easily build and deploy service applications while making the most of our compute capacity.

## Close Up
If you want to leverage the ```scripts/getMetrics.sh``` script to output the total alloc and try to compute how many services you can actually deploy please go for it. I'd also take the time to play around with any other [nomad commands](https://www.nomadproject.io/docs/commands/index.html) that are at your disposal before taking the network down.

```
nomad stop --purge <web-server || go-api>
```

Once you've killed your services, then you can clean up everything. If you used terraform, just leverage ```terraform destroy```, otherwise, be a good cloud citizen in any of the other ways you could have set this up.
