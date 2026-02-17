# Template - PanOS-API - QoS (Dynamic Baseline)

Zabbix 7.x template to monitor per-class QoS throughput on Palo Alto Networks firewalls using the PAN-OS API.

This template discovers a list of QoS interfaces, collects raw QoS throughput output per interface, and creates per-class numeric metrics (Class 1 to Class 8) in bps. Alerting is based on dynamic baselines using short versus long averages (spike detection) and long-term trend changes.

---

## Features

- Interface discovery by macro (LLD)
- Master item (HTTP Agent) using PAN-OS API key authentication
- 8 dependent items per interface (Class 1 to Class 8)
- Unit conversion from kbps to bps
- Dynamic alerting:
  - Spike detection (short vs long window, factor-based)
  - Trend change detection (24h vs 7d, factor-based)
- No data trigger for master item polling

---

## Requirements

- Zabbix 7.x
- Palo Alto firewall with API access enabled
- HTTPS connectivity from Zabbix to firewall management interface
- PAN-OS API key

---

## How It Works

1. LLD discovery reads the macro `{$QOS_INTERFACES}`
2. For each interface in the list, Zabbix creates:
   - 1 master item: `panos.qos.raw[{#IFNAME}]`
   - 8 dependent items: `panos.qos.classX.bps[{#IFNAME}]` where X = 1..8
3. The master item queries PAN-OS with: `show qos interface <IFNAME> throughput 0`
4. Dependent items extract `Class X <value> kbps` via REGEX and multiply by 1000 to store in bps
5. Trigger prototypes evaluate dynamic conditions using averages

---

## Installation

1. Import the template YAML: **Configuration** → **Templates** → **Import**
2. Link the template to your firewall host
3. Configure required macros on the host or host group (see below)

---

## Macros

### Authentication

**`{$API_KEY}`** *(required)*  
PAN-OS API key used by the HTTP Agent master item.

**Key generation example:**  
```
https://<firewall>/api/?type=keygen&user=<user>&password=<password>
```

### Interface Discovery

**`{$QOS_INTERFACES}`** *(required)*  
Pipe-separated list of interfaces to monitor.

**Example:**  
```
ethernet1/2|ethernet1/3|ethernet1/19
```

---

## Dynamic Alerting Macros

Dynamic alerting is based on comparing averages across different time windows.

### Baseline Guardrail

**`{$QOS_MIN_BASELINE}`** *(default: `10000000`)*  
Minimum baseline average in bps required to evaluate dynamic triggers.

- Prevents false positives when the baseline traffic is near zero
- If the long window average is below this value, spike and trend triggers will not evaluate as true
- Default: `10000000` bps = 10 Mbps

### Spike Detection (short vs long)

Spike detection compares: `avg(item, {$QOS_SPIKE_SHORT})` against `avg(item, {$QOS_SPIKE_LONG})`

**`{$QOS_SPIKE_SHORT}`** *(default: `10m`)*  
Short averaging window used to measure current behavior (average of the last 10 minutes)

**`{$QOS_SPIKE_LONG}`** *(default: `1h`)*  
Long averaging window used as baseline reference (average of the last 1 hour)

**`{$QOS_SPIKE_WARN}`** *(default: `2`)*  
Warning spike factor (warning when short average > 2x long average)

**`{$QOS_SPIKE_HIGH}`** *(default: `3`)*  
High spike factor (high when short average > 3x long average)

**`{$QOS_SPIKE_DISASTER}`** *(default: `5`)*  
Disaster spike factor (disaster when short average > 5x long average)

**Spike triggers are mutually exclusive by factor range:**
- **Warning:** > WARN and ≤ HIGH
- **High:** > HIGH and ≤ DISASTER
- **Disaster:** > DISASTER

### Trend Change Detection (long term)

Trend detection compares: `avg(item, {$QOS_TREND_SHORT})` against `avg(item, {$QOS_TREND_LONG})`

**`{$QOS_TREND_SHORT}`** *(default: `24h`)*  
Short trend window (average of the last 24 hours)

**`{$QOS_TREND_LONG}`** *(default: `7d`)*  
Long trend window (average of the last 7 days)

**`{$QOS_TREND_FACTOR}`** *(default: `1.5`)*  
Trend factor (event when 24h average > 1.5x 7d average)  
Default trigger severity: **INFO**

### No Data Monitoring

**`{$QOS_NODATA}`** *(default: `10m`)*  
No data window for the master item. A **HIGH** severity event is generated if no master item data is received for 10 minutes.

---

## Items Created Per Interface

**Master item:**
- `panos.qos.raw[{#IFNAME}]` *(Text, HTTP Agent)*

**Dependent items:**
- `panos.qos.class1.bps[{#IFNAME}]` .. `panos.qos.class8.bps[{#IFNAME}]` *(Numeric float, bps)*

---

## Triggers Created Per Interface and Class

**For each class item (1..8):**
- Spike warning *(WARNING)*
- Spike high *(HIGH)*
- Spike disaster *(DISASTER)*
- Trend change *(INFO)*

**For each interface (master item):**
- No data *(HIGH)*

---

## Notes and Tuning Guidance

- If traffic patterns vary strongly by time of day, increase baseline windows:
  - `{$QOS_SPIKE_LONG}` to `6h`
  - `{$QOS_TREND_LONG}` to `14d`
- If you see false positives on low-usage classes, increase `{$QOS_MIN_BASELINE}`
- To increase sensitivity:
  - Lower spike factors (`WARN/HIGH/DISASTER`)
  - Lower `{$QOS_TREND_FACTOR}`

---

**Author:** Nicola Carmelo Gurgone (@N1k0droid)

**Version:** 1.6.0

Last Updated: February 2026

---

## 📄 License

MIT License © 2026 Nicola Gurgone (@N1k0droid)

See [LICENSE](LICENSE) for details.

---
