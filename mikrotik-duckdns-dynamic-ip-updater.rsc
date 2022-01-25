#----------MODIFY THIS SECTION AS NEEDED----------------------------------------
# DuckDNS Sub Domain
:local duckdnsSubDomain "PUT-SUBDOMAIN-HERE"

# DuckDNS Token
:local duckdnsToken "PUT-TOKEN-HERE"

# IP Version
# Set true (without quotes) for ip version you need to update
:local ipv4Mode false;
:local ipv6Mode false;

# Interface Argument
# For IPv4 (no need to change if you don't need ipv4)
:local wanInterface "PUT-WAN-INTERFACE"
# For IPv6 (no need to change if you don't need ipv6)
:local lanInterface "PUT-LAN-INTERFACE"
:local ipv6Pool "IPV6-ADDRESS-POOL"
#----------End Section----------------------------------------------------------

:local currentIPv4
:local currentIPv6
:local previousIPv4
:local previousIPv6

# Get current ip from interface
:if $ipv4Mode do={
	:set currentIPv4 value=[/ip address get [find where interface=$wanInterface] value-name=address]
	:set currentIPv4 value=[:pick $currentIPv4 -1 [:find $currentIPv4 "/" -1] ]
}
:if $ipv6Mode do={
	:set currentIPv6 value=[/ipv6 address get [find where global=yes interface=$lanInterface from-pool=$ipv6Pool] value-name=address]
	:set currentIPv6 value=[:pick $currentIPv6 -1 [:find $currentIPv6 "/" -1] ]
}

# File name for ip record
:local previousIPv4File ("duckdns-".$duckdnsSubDomain)
:local previousIPv6File ("duckdns-".$duckdnsSubDomain."-v6")

# Function to get previous ip from file
:local getPreviousIP do={
	# Initial file to record current ip for domain
	:if ([:len [/file find where name=($previousIPFile.".txt")]] < 1 ) do={
		/file print file=$previousIPFile
		:delay 2s
		/file set ($previousIPFile.".txt") contents=$defaultContents
	};
	# Get previous ip from file
	:local previousIP value=[/file get [find where name=($previousIPFile.".txt") ] value-name=contents];
	:return $previousIP
}

# Get previous ip from file
:if $ipv4Mode do {
	:set previousIPv4 [$getPreviousIP previousIPFile=$previousIPv4File defaultContents="0.0.0.0"]
	:log info "DuckDNS: DNS IP $previousIPv4, current IPv4 $currentIPv4"
}
:if $ipv6Mode do {
	:set previousIPv6 [$getPreviousIP previousIPFile=$previousIPv6File defaultContents="::1"]
	:log info "DuckDNS: DNS IP $previousIPv6, current IPv6 $currentIPv6"
}

# Update ip if needed
:if ($currentIPv4 != $previousIPv4 || $currentIPv6 != $previousIPv6) do={
	:log info "DuckDNS: Current IP is not equal to previous IP, update needed"
	:log info "DuckDNS: Sending update for $duckdnsSubDomain.duckdns.org"
	:local duckRequestUrl "https://www.duckdns.org/update\?domains=$duckdnsSubDomain&token=$duckdnsToken&verbose=true"
	if ($ipv4Mode && $ipv6Mode) do={
		:set duckRequestUrl ($duckRequestUrl."&ip=".$currentIPv4."&ipv6=".$currentIPv6)
	} else={
		if $ipv4Mode do={
			:set duckRequestUrl ($duckRequestUrl."&ip=".$currentIPv4)
		}
		if $ipv6Mode do={
			:set duckRequestUrl ($duckRequestUrl."&ip=".$currentIPv6)
		}
	}
	:log info "DuckDNS: using GET request: $duckRequestUrl"

	:local duckResponse
	:do {:set duckResponse ([/tool fetch url=$duckRequestUrl output=user as-value]->"data")} on-error={
		:log error "DuckDNS: could not send GET request to the DuckDNS server. Going to try again in a while."
		:delay 5m;
			:do {:set duckResponse ([/tool fetch url=$duckRequestUrl output=user as-value]->"data")} on-error={
				:log error "DuckDNS: could not send GET request to the DuckDNS server for the second time."
				:error "DuckDNS: bye!"
			}
	}
	# Check server's answer
	:if ([:pick $duckResponse 0 2] = "OK") do={
		:log info "DuckDNS: New IP address $currentIPv4 / $currentIPv6 for domain $duckdnsFullDomain has been successfully set!"
		# Write current ip to file
		if $ipv4Mode do={
			/file set ($previousIPv4File.".txt") contents=$currentIPv4
		}
		if $ipv6Mode do={
			/file set ($previousIPv6File.".txt") contents=$currentIPv6
		}
	} else={ 
		:log warning "DuckDNS: There is an error occurred during IP address update, server did not answer with \"OK\" response!"
	}
}
:log info message="END: DuckDNS.org DDNS Update finished"
