package appshield.kubernetes.KSV022

import data.lib.kubernetes

default failAdditionalCaps = false

__rego_metadata__ := {
	"id": "KSV022",
	"title": "Specific capabilities added",
	"version": "v1.0.0",
	"severity": "Medium",
	"type": "Kubernetes Security Check",
	"description": "According to pod security standard 'Capabilities', capabilities beyond the default set must not be added.",
	"recommended_actions": "Do not set spec.containers[*].securityContext.capabilities.add and spec.initContainers[*].securityContext.capabilities.add",
}

# Add allowed capabilities to this set
allowed_caps = set()

# getContainersWithDisallowedCaps returns a list of containers which have
# additional capabilities not included in the allowed capabilities list
getContainersWithDisallowedCaps[container] {
	allContainers := kubernetes.containers[_]
	set_caps := {cap | cap := allContainers.securityContext.capabilities.add[_]}
	caps_not_allowed := set_caps - allowed_caps
	count(caps_not_allowed) > 0
	container := allContainers.name
}

# cap_msg is a string of allowed capabilities to be print as part of deny message
caps_msg = "" {
	count(allowed_caps) == 0
} else = msg {
	msg := sprintf(" or set it to the following allowed values: %s", [concat(", ", allowed_caps)])
}

# failAdditionalCaps is true if there are containers which set additional capabiliites
# not included in the allowed capabilities list
failAdditionalCaps {
	count(getContainersWithDisallowedCaps) > 0
}

deny[res] {
	failAdditionalCaps

	msg := sprintf("container %s of %s %s in %s namespace should not set securityContext.capabilities.add%s", [getContainersWithDisallowedCaps[_], lower(kubernetes.kind), kubernetes.name, kubernetes.namespace, caps_msg])

	res := {
		"msg": msg,
		"id": __rego_metadata__.id,
		"title": __rego_metadata__.title,
		"severity": __rego_metadata__.severity,
		"type": __rego_metadata__.type,
	}
}
