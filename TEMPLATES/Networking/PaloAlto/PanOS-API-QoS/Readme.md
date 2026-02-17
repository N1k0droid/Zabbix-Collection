# Template - PanOS-API - QoS (Dynamic Baseline)

[![Version](https://img.shields.io/badge/version-1.8.0-blue.svg)](https://github.com/N1k0droid/zabbix-panos-qos)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Zabbix](https://img.shields.io/badge/Zabbix-7.0%2B-orange.svg)](https://www.zabbix.com)
![Status](https://img.shields.io/badge/status-stable-brightgreen.svg)

Zabbix 7.x template to monitor per-class QoS throughput on Palo Alto Networks firewalls using the PAN-OS API.

**New in v1.8.0:** Independent macro configuration per QoS class allows fine-tuned thresholds and dynamic parameters for each traffic class.

## Features

- Interface discovery by macro (LLD)
- 8 dependent items per interface (Class 1 to Class 8)
- **Dual alerting:** Static thresholds + Dynamic baselines (spike/trend detection)
- **Per-class macro configuration:** Each QoS class (1-8) has independent parameters
- 57 triggers per interface (56 class triggers + 1 nodata)

## Requirements

- Zabbix 7.x
- Palo Alto firewall with API access
- PAN-OS API key

## Macros

### Global Macros (3)

- `{$API_KEY}` - PAN-OS API key *(required)*
- `{$QOS_INTERFACES}` - Pipe-separated interface list *(required)*
- `{$QOS_NODATA}` - No data timeout (default: 10m)

### Per-Class Macros (12 × 8 classes = 96)

Each QoS class (1-8) has:

**Static Thresholds (bps):**
- `{$QOS_THR_WARN_CLASSN}` = 10 Gbps
- `{$QOS_THR_HIGH_CLASSN}` = 10 Gbps
- `{$QOS_THR_DISASTER_CLASSN}` = 10 Gbps

**Dynamic Baseline:**
- `{$QOS_MIN_BASELINE_CLASSN}` = 10 Mbps
- `{$QOS_SPIKE_SHORT_CLASSN}` = 10m
- `{$QOS_SPIKE_LONG_CLASSN}` = 1h
- `{$QOS_SPIKE_WARN_CLASSN}` = 2×
- `{$QOS_SPIKE_HIGH_CLASSN}` = 3×
- `{$QOS_SPIKE_DISASTER_CLASSN}` = 5×

**Trend Detection:**
- `{$QOS_TREND_SHORT_CLASSN}` = 24h
- `{$QOS_TREND_LONG_CLASSN}` = 7d
- `{$QOS_TREND_FACTOR_CLASSN}` = 1.5×

## Configuration Examples

### Voice Traffic (Class 1) - High Priority

```
{$QOS_THR_WARN_CLASS1} = 1000000000     # 1 Gbps
{$QOS_SPIKE_WARN_CLASS1} = 1.5          # More sensitive
{$QOS_MIN_BASELINE_CLASS1} = 1000000    # 1 Mbps minimum
```

### Best Effort (Class 8) - Low Priority

```
{$QOS_THR_WARN_CLASS8} = 20000000000    # 20 Gbps
{$QOS_SPIKE_WARN_CLASS8} = 3            # Less sensitive
{$QOS_MIN_BASELINE_CLASS8} = 50000000   # 50 Mbps minimum
```

## Triggers Per Class

Each class (1-8) has 7 triggers:
- 3 static threshold triggers (warning/high/disaster)
- 3 spike detection triggers (warning/high/disaster)
- 1 trend change trigger (info)


## License

MIT License © 2026 Nicola Gurgone (@N1k0droid)
