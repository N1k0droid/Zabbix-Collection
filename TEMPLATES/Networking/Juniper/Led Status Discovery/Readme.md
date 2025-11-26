# Juniper MX204 LED Status Discovery Template for Zabbix 7.0

## Overview

This Zabbix 7.0 template provides comprehensive LED monitoring for Juniper MX204 routers via SNMP.

### Why This Template?

Official Zabbix templates do not include MX204 LED monitoring. Additionally, Juniper MX204 lacks the standard "snmp system status alarm" metrics available in other Juniper router families (see [Juniper Support Portal](https://supportportal.juniper.net/s/article/SNMP-is-not-pulling-data-for-the-Chassis-Alarm-on-MX204)). This template fills that gap by monitoring all LED indicators directly from the `jnxLEDTable`, enabling proactive hardware health tracking and master alarm detection.

## Known Limitations

### Chassis Alarm LED Special Handling
Due to the non-standard OID structure of the Chassis Alarm LED in jnxLEDTable, this template uses **dedicated static items** for monitoring:
- Chassis Alarm LED: LED State (status)
- Chassis Alarm LED: LED State Ordered (severity)  
- Chassis Alarm LED: LED Originator (owner)

Unlike other discovered LEDs, these items use 4-level OIDs (e.g., `1.3.6.1.4.1.2636.3.1.10.1.8.3.1.0.0`) instead of the standard 5-level pattern. This ensures reliable monitoring of the system master alarm indicator without discovery rule interference.

### OID Index Differences
- **Standard LEDs**: Use `{#SNMPINDEX}` for table indexing (e.g., `...3.{#SNMPINDEX}`)
- **Chassis Alarm LED**: Uses fixed OID `...3.1.0.0` due to different internal table structure

### What It Does

- **Automatic Discovery** – Discovers all LEDs on the MX204 (chassis alarm, PSU, fans, FPC, etc.)
- **Real-time Monitoring** – Collects LED state, severity, and component origin via SNMP
- **Intelligent Alerting** – Generates WARNING/CRITICAL/UNKNOWN triggers based on LED severity
- **Chassis Alarm Detection** – Special trigger for the master system alarm LED

---

## Prerequisites

### On Zabbix Server
- Zabbix 7.0 or higher
- SNMP monitoring capability enabled

### On Juniper MX204
- SNMP enabled and configured

---

## What Gets Monitored

For each discovered LED, the template collects:

| Item | OID | Interval | Description |
|------|-----|----------|-------------|
| **LED State (status)** | 1.3.6.1.4.1.2636.3.1.10.1.8 | 60s | Physical LED state (off/green/amber/blinking) |
| **LED State Ordered (severity)** | 1.3.6.1.4.1.2636.3.1.10.1.9 | 60s | Standardized severity (1=unknown, 2=ok, 3=warning, 4=major, 5=critical, 6=offline) |
| **LED Originator (owner)** | 1.3.6.1.4.1.2636.3.1.10.1.6 | 1h | Hardware component controlling the LED (chassis/PSU/fan/etc) |

### Expected Discovered LEDs

```
- chassis alarm LED
- PEM 0 LED
- PEM 1 LED
- FAN 0 LED
- FAN 1 LED
- FAN 2 LED
- FPC slot 0 OK/Fail LED
- Routing Engine LED
- CB slot 0 LED
```

---

## Triggers

The template generates 4 triggers per LED:

| Trigger | Condition | Priority |
|---------|-----------|----------|
| LED State WARNING (Amber) | Severity = 3 | AVERAGE |
| LED State CRITICAL (Red) | Severity ≥ 4 | HIGH |
| LED State UNKNOWN | Severity = 1 | INFO |
| **CRITICAL - Main Chassis Alarm LED** | Origin = 0.0 AND Severity ≥ 3 | HIGH |

---

## Compatibility

**Tested on:** Juniper MX204

**May work on:** Other MX-series routers using the same jnxLEDTable OID structure.

To verify compatibility on other Juniper platforms, run: `show snmp mib walk jnxLEDDescr | display xml`

Check if the OID matches `1.3.6.1.4.1.2636.3.1.10.1.7`. If different, adjust the template OIDs accordingly.

---

## References

- [Juniper jnxLEDTable MIB](https://www.juniper.net/documentation/)
- [Zabbix Low-Level Discovery](https://www.zabbix.com/documentation/current/en/manual/discovery/low_level_discovery)
- [Juniper SNMP Chassis Alarm Issue](https://supportportal.juniper.net/s/article/SNMP-is-not-pulling-data-for-the-Chassis-Alarm-on-MX204)
