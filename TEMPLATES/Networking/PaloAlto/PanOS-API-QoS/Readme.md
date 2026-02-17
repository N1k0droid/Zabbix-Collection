# Template - PanOS-API - QoS (Dynamic Baseline)

[![Version](https://img.shields.io/badge/version-1.8.0-blue.svg)](https://github.com/N1k0droid/zabbix-panos-qos)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Zabbix](https://img.shields.io/badge/Zabbix-7.0%2B-orange.svg)](https://www.zabbix.com)
![Status](https://img.shields.io/badge/status-stable-brightgreen.svg)

Zabbix 7.x template to monitor per-class QoS throughput on Palo Alto Networks firewalls using the PAN-OS API.

---

## Features

- Interface discovery by macro (LLD)
- 8 dependent items per interface (Class 1 to Class 8)
- **Dual alerting:** Static thresholds + Dynamic baselines (spike/trend detection)
- **Per-class macro configuration:** Each QoS class (1-8) has independent parameters
- 57 triggers per interface (56 class triggers + 1 nodata)

---

## Requirements

- Zabbix 7.x
- Palo Alto firewall with API access
- PAN-OS API key

---

## Macros

### Global Macros (3)

- `{$API_KEY}` - PAN-OS API key *(required)*
- `{$QOS_INTERFACES}` - Pipe-separated interface list *(required)*
  - Example: `ethernet1/2|ethernet1/3|ethernet1/19`
- `{$QOS_NODATA}` - No data timeout (default: `10m`)

### Per-Class Macros (12 × 8 classes = 96)

Each QoS class (1-8) has:

**Static Thresholds (bps):**
- `{$QOS_THR_WARN_CLASSN}` = 10 Gbps *(dummy value, tune per class)*
- `{$QOS_THR_HIGH_CLASSN}` = 10 Gbps *(dummy value, tune per class)*
- `{$QOS_THR_DISASTER_CLASSN}` = 10 Gbps *(dummy value, tune per class)*

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

---

## Triggers Per Class

Each class (1-8) has **7 triggers**:
- 3 static threshold triggers (warning/high/disaster)
- 3 spike detection triggers (warning/high/disaster)
- 1 trend change trigger (info)

---

## How Triggers Work

Each QoS class monitors traffic with **three alerting strategies**:

### 1. Static Thresholds (Absolute Values)

Simple alerts based on absolute traffic levels:

- **Warning:** Traffic exceeds `{$QOS_THR_WARN_CLASSN}` (e.g., 300 Mbps)
- **High:** Traffic exceeds `{$QOS_THR_HIGH_CLASSN}` (e.g., 800 Mbps)
- **Disaster:** Traffic exceeds `{$QOS_THR_DISASTER_CLASSN}` (e.g., 1 Gbps)

**Example:** If Class 1 traffic reaches 850 Mbps and your HIGH threshold is 800 Mbps, a HIGH alert triggers.

### 2. Dynamic Baselines (Spike Detection)

Alerts based on traffic **behavior changes** compared to recent history:

- **Spike Warning:** Current traffic (last 10m) is **2× higher** than baseline (last 1h)
- **Spike High:** Current traffic is **3× higher** than baseline
- **Spike Disaster:** Current traffic is **5× higher** than baseline

**Example:** If Class 1 normally runs at 100 Mbps (1h average) and suddenly jumps to 300 Mbps (10m average), a spike HIGH alert triggers (3× baseline).

### 3. Trend Detection (Long-term Change)

Alerts when traffic pattern changes over days:

- **Trend Change (INFO):** Recent traffic (last 24h) is **1.5× higher** than long-term average (last 7d)

**Example:** If Class 2 averaged 200 Mbps for the past week but has been running at 320 Mbps for the last day, a trend INFO alert triggers (1.6× baseline).

### Why Three Strategies?

- **Static thresholds** catch absolute overload (e.g., link capacity limits)
- **Dynamic baselines** catch anomalies (e.g., DDoS, application misbehavior, unexpected growth)

Dynamic triggers prevent false positives on low-traffic classes by requiring minimum baseline (`{$QOS_MIN_BASELINE_CLASSN}` = 10 Mbps default).

---

## Installation

1. Import the template YAML: **Configuration** → **Templates** → **Import**
2. Link the template to your firewall host
3. Configure macros on the host or host group:
   - Set `{$API_KEY}` with your PAN-OS API key
   - Set `{$QOS_INTERFACES}` with pipe-separated interface list
   - Optionally tune per-class thresholds and factors

**API Key generation:**
```bash
https://<firewall>/api/?type=keygen&user=<username>&password=<password>
```

---

## License

MIT License © 2026 Nicola Gurgone (@N1k0droid)
