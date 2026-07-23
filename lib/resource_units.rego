package lib.resource_units

import rego.v1

# Shared helpers for Kubernetes resource quantity canonicalization.
# Converts CPU and memory strings to a common numeric base for comparison.
#
# CPU values are normalized to millicores (integer).
# Memory/storage values are normalized to millibytes (integer).
#
# Supports all Kubernetes quantity formats:
#   CPU:     "100m", "0.5", "2", 1 (numeric)
#   Memory:  "128Mi", "1Gi", "512000", "1e9" (numeric)
#   Suffixes: E, P, T, G, M, k, m, Ki, Mi, Gi, Ti, Pi, Ei

# --- CPU canonicalization ---

canonify_cpu(orig) := new if {
	is_number(orig)
	new := orig * 1000
}

canonify_cpu(orig) := new if {
	not is_number(orig)
	endswith(orig, "m")
	new := to_number(replace(orig, "m", ""))
}

canonify_cpu(orig) := new if {
	not is_number(orig)
	not endswith(orig, "m")
	regex.match(`^[0-9]+(\.[0-9]+)?$`, orig)
	new := to_number(orig) * 1000
}

# --- Memory / storage suffix multipliers ---

mem_multiple("E") := 1000000000000000000000

mem_multiple("P") := 1000000000000000000

mem_multiple("T") := 1000000000000000

mem_multiple("G") := 1000000000000

mem_multiple("M") := 1000000000

mem_multiple("k") := 1000000

mem_multiple("") := 1000

# Kubernetes accepts millibyte precision when it probably shouldn't.
# https://github.com/kubernetes/kubernetes/issues/28741
mem_multiple("m") := 1

mem_multiple("Ki") := 1024000

mem_multiple("Mi") := 1048576000

mem_multiple("Gi") := 1073741824000

mem_multiple("Ti") := 1099511627776000

mem_multiple("Pi") := 1125899906842624000

mem_multiple("Ei") := 1152921504606846976000

# --- Suffix extraction ---

get_suffix(quantity) := suffix if {
	not is_string(quantity)
	suffix := ""
}

get_suffix(quantity) := suffix if {
	is_string(quantity)
	count(quantity) > 0
	suffix := substring(quantity, count(quantity) - 1, -1)
	mem_multiple(suffix)
}

get_suffix(quantity) := suffix if {
	is_string(quantity)
	count(quantity) > 1
	suffix := substring(quantity, count(quantity) - 2, -1)
	mem_multiple(suffix)
}

get_suffix(quantity) := suffix if {
	is_string(quantity)
	count(quantity) > 1
	not mem_multiple(substring(quantity, count(quantity) - 1, -1))
	not mem_multiple(substring(quantity, count(quantity) - 2, -1))
	suffix := ""
}

get_suffix(quantity) := suffix if {
	is_string(quantity)
	count(quantity) == 1
	not mem_multiple(substring(quantity, count(quantity) - 1, -1))
	suffix := ""
}

get_suffix(quantity) := suffix if {
	is_string(quantity)
	count(quantity) == 0
	suffix := ""
}

# --- Memory / storage canonicalization ---

canonify_mem(orig) := new if {
	is_number(orig)
	new := orig * 1000
}

canonify_mem(orig) := new if {
	not is_number(orig)
	suffix := get_suffix(orig)
	raw := replace(orig, suffix, "")
	regex.match(`^[0-9]+(\.[0-9]+)?$`, raw)
	new := to_number(raw) * mem_multiple(suffix)
}

# --- Field presence helpers ---

missing(obj, field) if {
	not obj[field]
}

missing(obj, field) if {
	obj[field] == ""
}
