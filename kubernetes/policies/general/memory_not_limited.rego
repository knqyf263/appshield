package appshield.kubernetes.KSV018

import data.lib.kubernetes
import data.lib.utils

default failLimitsMemory = false

__rego_metadata__ := {
	"id": "KSV018",
	"title": "Memory not limited",
	"version": "v1.0.0",
	"severity": "Low",
	"type": "Kubernetes Security Check",
	"description": "Enforcing memory limits prevents DoS via resource exhaustion.",
	"recommended_actions": "Set a limit value under 'containers[].resources.limits.memory'.",
}

# getLimitsMemoryContainers returns all containers which have set resources.limits.memory
getLimitsMemoryContainers[container] {
	allContainers := kubernetes.containers[_]
	utils.has_key(allContainers.resources.limits, "memory")
	container := allContainers.name
}

# getNoLimitsMemoryContainers returns all containers which have not set
# resources.limits.memory
getNoLimitsMemoryContainers[container] {
	container := kubernetes.containers[_].name
	not getLimitsMemoryContainers[container]
}

# failLimitsMemory is true if containers[].resources.limits.memory is not set
# for ANY container
failLimitsMemory {
	count(getNoLimitsMemoryContainers) > 0
}

deny[res] {
	failLimitsMemory

	msg := kubernetes.format(sprintf("container %s of %s %s in %s namespace should set resources.limits.memory", [getNoLimitsMemoryContainers[_], lower(kubernetes.kind), kubernetes.name, kubernetes.namespace]))

	res := {
		"msg": msg,
		"id": __rego_metadata__.id,
		"title": __rego_metadata__.title,
		"severity": __rego_metadata__.severity,
		"type": __rego_metadata__.type,
	}
}
