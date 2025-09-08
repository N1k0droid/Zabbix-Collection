# Zabbix Server Housekeeper Stats by Zabbix Agent Active 

## Overview

This template monitors the Zabbix Server Housekeeper statistics using the agent in active mode. It tracks how often the housekeeper deletes records and the execution time, enabling administrators to identify performance bottlenecks and issues.

## Requirements

- **Zabbix Server** >= 7.0
- **Zabbix Agent** configured in active mode
- Read access to `/var/log/zabbix/zabbix_server.log`
- Housekeeper logging enabled (default in Zabbix)

## Import

1. Go to **Configuration → Templates → Import**
2. Select the YAML file of this template
3. Import with default settings

Ensure the `zabbix` user has read permissions on the log file:

```bash
sudo chown zabbix:zabbix /var/log/zabbix/zabbix_server.log
sudo chmod 644 /var/log/zabbix/zabbix_server.log
```

## Main Monitored Items

| Item Key                             | Description                                | Type       |
|------------------------------------|--------------------------------------------|------------|
| log["/var/log/zabbix/zabbix_server.log", ...] | Housekeeper log messages (master item) | Master (Log) |
| zabbix.housekeeper.del[alarms]     | Number of alarm records deleted           | Dependent  |
| zabbix.housekeeper.del[audit]      | Number of audit records deleted           | Dependent  |
| zabbix.housekeeper.del[autoreg_host] | Number of autoregistration host records deleted | Dependent  |
| zabbix.housekeeper.del[events]     | Number of event records deleted           | Dependent  |
| zabbix.housekeeper.del[history]    | Number of history and trend records deleted| Dependent  |
| zabbix.housekeeper.del[items]      | Number of item and trigger records deleted| Dependent  |
| zabbix.housekeeper.del[problems]   | Number of problem records deleted         | Dependent  |
| zabbix.housekeeper.del[records]    | Number of records deleted                  | Dependent  |
| zabbix.housekeeper.del[sessions]   | Number of session records deleted         | Dependent  |
| zabbix.housekeeper.exec[time]      | Execution time of last housekeeper run    | Dependent  |

## Configurable Macros

| Macro                    | Default | Description                    | Recommended Values            |
|--------------------------|---------|------------------------------|------------------------------|
| {$HOUSEKEEPER.TIME.WARN} | 60      | Warning threshold (seconds)    | 60-120 depending on scale    |

## Triggers

- **Housekeeper execution time is High**: Generates a warning if the average execution time over 24 hours exceeds `{$HOUSEKEEPER.TIME.WARN}` seconds.

## Changes for 7.0 Version

- Removed dashboard section (unsupported in Zabbix 7.0)
- Verified UUIDs and macros compatibility
- No changes in items or keys

## Tips

- If the template collects no data, verify permissions and check the presence of the log entries.
- Create manual dashboards if visualization is needed.

## Attribution

- **Original**: diasdm ([Zabbix_Out_of_The_Box](https://github.com/diasdmhub/Zabbix_Out_of_The_Box))
- **7.0 Adaptation**: N1k0droid (2025)
- **License**: GPL v3

---

> Tested on Zabbix Server 7.0. Imported with no errors, no dashboards included.
