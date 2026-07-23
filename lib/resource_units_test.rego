package lib.resource_units_test

import rego.v1

import data.lib.resource_units

# --- CPU tests ---

test_canonify_cpu_millicores if {
	resource_units.canonify_cpu("100m") == 100
}

test_canonify_cpu_millicores_large if {
	resource_units.canonify_cpu("2000m") == 2000
}

test_canonify_cpu_whole_number_string if {
	resource_units.canonify_cpu("2") == 2000
}

test_canonify_cpu_fractional_string if {
	resource_units.canonify_cpu("0.5") == 500
}

test_canonify_cpu_numeric if {
	resource_units.canonify_cpu(1) == 1000
}

test_canonify_cpu_numeric_fractional if {
	resource_units.canonify_cpu(0.25) == 250
}

# --- Memory tests ---

test_canonify_mem_gi if {
	resource_units.canonify_mem("1Gi") == 1073741824000
}

test_canonify_mem_mi if {
	resource_units.canonify_mem("128Mi") == 134217728000
}

test_canonify_mem_ki if {
	resource_units.canonify_mem("256Ki") == 262144000
}

test_canonify_mem_numeric if {
	resource_units.canonify_mem(1000) == 1000000
}

test_canonify_mem_plain_bytes_string if {
	resource_units.canonify_mem("512000") == 512000000
}

test_canonify_mem_g_decimal if {
	resource_units.canonify_mem("1G") == 1000000000000
}

test_canonify_mem_m_decimal if {
	resource_units.canonify_mem("500M") == 500000000000
}

# --- Suffix extraction tests ---

test_get_suffix_gi if {
	resource_units.get_suffix("128Mi") == "Mi"
}

test_get_suffix_single_char if {
	resource_units.get_suffix("1G") == "G"
}

test_get_suffix_no_suffix if {
	resource_units.get_suffix("512000") == ""
}

test_get_suffix_numeric if {
	resource_units.get_suffix(1000) == ""
}

# --- Missing field tests ---

test_missing_absent if {
	resource_units.missing({}, "cpu")
}

test_missing_empty_string if {
	resource_units.missing({"cpu": ""}, "cpu")
}

test_not_missing_present if {
	not resource_units.missing({"cpu": "100m"}, "cpu")
}
