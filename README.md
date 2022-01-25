# Mikrotik Duck DNS Dynamic IP Updater

This project is forked from [Mikrotik-Duckdns-Dynamic-IP-Updater](https://github.com/beeyev/Mikrotik-Duckdns-Dynamic-IP-Updater) and modified to fit Hinet PPPoE dual stack dynamic address

Main changes:

* Get current IP from interface instead of using third-party API
* Previous IP will be stored in local file

For IPv6, the script should work fine if you get a IPv6 prefix from ISP and generate IPv6 from router.

## How to use

1. Duck DNS token and subdomain

    Go to [duckdns.org](https://www.duckdns.org) register and get your token.
    ![](/howto/get-token.png)

    Then create your new subdomain.
    ![](/howto/make-subdomain.png)

2. Create new mikrotik script

    Using WinBox or WebFig, go to: System -> Scripts [Add]

    ![](/howto/script-name-params.png)

    * Name

        Script name (will be used in next step)

    * Policy

        Check following permissions: ftp, read, write, policy, test

    * Source

        Put [script](/mikrotik-duckdns-dynamic-ip-updater.rsc) into source and set your variables.


        For example, if you have a subdomain `abc` with token `qwerty-asdfgh-zxcv` and only need IPv4, and you connect to ISP with PPPoE with interface name `pppoe-out`, your setting should look like this:

            # DuckDNS Sub Domain
            :local duckdnsSubDomain "abc"

            # DuckDNS Token
            :local duckdnsToken "qwerty-asdfgh-zxcv"

            # IP Version
            # Set true (without quotes) for ip version you need to update
            :local ipv4Mode true;
            :local ipv6Mode false;

            # Interface Argument
            # For IPv4 (no need to change if you don't need ipv4)
            :local wanInterface "pppoe-out"
            # For IPv6 (no need to change if you don't need ipv6)
            :local lanInterface "PUT-LAN-INTERFACE"
            :local ipv6Pool "IPV6-ADDRESS-POOL"

        For IPv6, if you receive IPv6 prefix from ISP and use this prefix to create a IPv6 pool named `ipv6-pool` for interface `bridge-lan`, then the setting should look like this:

            # DuckDNS Sub Domain
            :local duckdnsSubDomain "abc"

            # DuckDNS Token
            :local duckdnsToken "qwerty-asdfgh-zxcv"

            # IP Version
            # Set true (without quotes) for ip version you need to update
            :local ipv4Mode true;
            :local ipv6Mode true;

            # Interface Argument
            # For IPv4 (no need to change if you don't need ipv4)
            :local wanInterface "pppoe-out"
            # For IPv6 (no need to change if you don't need ipv6)
            :local lanInterface "bridge-lan"
            :local ipv6Pool "ipv6-pool"

    Click `Run Script` and check log to see if the script work.

3. Create scheduled task

    WinBox or WebFig: System -> Scheduler [Add]

    ![](/howto/scheduler-task.png)

    * Name

        Scheduler name

    * Start Date
    * Start Time
    * Interval

        Set scheduler interval, `00:30:00` stands for 30 minutes

    * Policy

        Check ftp, read, write, policy, test

    * On Event

        Fill with:

        `/system script run YOUR-SCRIPT-NAME;`

        Replace `YOUR-SCRIPT-NAME` with script name you set in previous step

---
If you love this project, please consider giving me a ⭐
