package appshield.kubernetes.KSV015

import data.lib.kubernetes
import data.lib.utils

default failRequestsCPU = false

__rego_metadata__ := {
	"id": "KSV015",
	"title": "CPU requests not specified",
	"version": "v1.0.0",
	"severity": "Low",
	"type": "Kubernetes Security Check",
	"description": "When containers have resource requests specified, the scheduler can make better decisions about which nodes to place pods on, and how to deal with resource contention.",
	"recommended_actions": "Set 'containers[].resources.requests.cpu'.",
}

# getRequestsCPUContainers returns all containers which have set resources.requests.cpu
getRequestsCPUContainers[container] {
	allContainers := kubernetes.containers[_]
	utils.has_key(allContainers.resources.requests, "cpu")
	container := allContainers.name
}

# getNoRequestsCPUContainers returns all containers which have not set
# resources.requests.cpu
getNoRequestsCPUContainers[container] {
	container := kubernetes.containers[_].name
	not getRequestsCPUContainers[container]
}

# failRequestsCPU is true if containers[].resources.requests.cpu is not set
# for ANY container
failRequestsCPU {
	count(getNoRequestsCPUContainers) > 0
}

deny[res] {
	failRequestsCPU

	msg := kubernetes.format(sprintf("container %s of %s %s in %s namespace should set resources.requests.cpu", [getNoRequestsCPUContainers[_], lower(kubernetes.kind), kubernetes.name, kubernetes.namespace]))

	res := {
		"msg": msg,
		"id": __rego_metadata__.id,
		"title": __rego_metadata__.title,
		"severity": __rego_metadata__.severity,
		"type": __rego_metadata__.type,
	}
}
