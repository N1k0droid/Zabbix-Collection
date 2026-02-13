# Zabbix Unsupported Items Monitor

[![Version](https://img.shields.io/badge/version-3.1.3-blue.svg)](https://github.com/N1k0droid/zabbix-unsupported-items-monitor)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Zabbix](https://img.shields.io/badge/Zabbix-7.0%2B-orange.svg)](https://www.zabbix.com)
![Status](https://img.shields.io/badge/status-stable-brightgreen.svg)

A comprehensive **Zabbix alerting and tracking solution** for unsupported items with time-based categorization, persistent logging, and automated escalation. Transform internal events into actionable metrics.

## 🎯 Overview

This project provides a **complete solution** to monitor, track, and report on unsupported items in Zabbix through:

- **Flexible time-based categorization**: Three configurable escalation steps (default: 1h, 24h, 7d)
- **Persistent logging**: File-based state tracking via bash script
- **Automated escalation**: Internal actions trigger at configurable intervals respecting Zabbix's 7-day action step limit
- **Dashboard-ready metrics**: `zabbix_sender` integration for real-time reporting
- **Text logs**: Detailed entries showing timestamp, host, item, and state
- **Built-in triggers**: Pre-configured alerts for escalation thresholds

> **Perfect for:** Infrastructure teams managing large deployments who need visibility into problematic items and want to distinguish between *temporary glitches* and *persistent issues*.

---

## 🚀 Quick Start

### Prerequisites

- **Zabbix Server**: 7.0 or later (tested on 7.0.x)
- **OS**: Linux (tested on Rocky Linux 9, CentOS 8+, Debian 11+)
- **Packages**: `bash`, `grep`, `awk`, `zabbix-sender` utility
- **User**: `zabbix` user with execute permissions on the script
- **Disk**: ~10 MB per 1000 unsupported items annually

### 1️⃣ Installation

#### Create directory structure
```bash
sudo mkdir -p /var/lib/zabbix/unsupported-items/logs
sudo chown -R zabbix:zabbix /var/lib/zabbix/unsupported-items
sudo chmod 755 /var/lib/zabbix/unsupported-items
sudo chmod 755 /var/lib/zabbix/unsupported-items/logs
```

#### Deploy the script
```bash
sudo wget -O /usr/lib/zabbix/alertscripts/zbx_unsupported_monitor.sh \
  https://github.com/N1k0droid/Zabbix-Collection/blob/main/TEMPLATES/Unsupported%20Item/zbx_unsupported_monitor.sh
sudo chmod 755 /usr/lib/zabbix/alertscripts/zbx_unsupported_monitor.sh
sudo chown zabbix:zabbix /usr/lib/zabbix/alertscripts/zbx_unsupported_monitor.sh
```

#### Verify script location
```bash
ls -la /usr/lib/zabbix/alertscripts/zbx_unsupported_monitor.sh
```

### 2️⃣ Zabbix Configuration

#### Create Media Type

Go to **Administration → Media types → Create media type**

| Setting | Value |
|---------|-------|
| **Name** | `Script - Unsupported Items Monitor` |
| **Type** | `Script` |
| **Script name** | `zbx_unsupported_monitor.sh` |
| **Concurrent sessions** | `1` |
| **Attempts** | `1` |

**Script parameters** (in order):
```
{HOST.NAME}
{ITEM.NAME}
{ITEM.KEY}
{ITEM.STATE}
{EVENT.TIME}
{EVENT.DATE}
```

**Message templates:**

*Internal problem:*
```
Subject: {HOST.NAME}
Message: "{ITEM.NAME}" "{ITEM.KEY}" "{ITEM.STATE}" "{EVENT.TIME}" "{EVENT.DATE}"
```

*Internal problem recovery:*
```
Subject: {HOST.NAME}
Message: "{ITEM.NAME}" "{ITEM.KEY}" "{ITEM.STATE}" "{EVENT.TIME}" "{EVENT.DATE}"
```

#### Create Internal Action

Go to **Configuration → Actions → Internal actions → Create action**

| Setting | Value |
|---------|-------|
| **Name** | `Unsupported Items Monitor` |
| **Event source** | `Internal event` |
| **Conditions** | `Event type = Item became unsupported` |

**Operations:** Add operation for each escalation step:

**Step 1 (Execute at 1h - configurable):**
- Send to media type: `Script - Unsupported Items Monitor`
- Send to users: (or user groups)
- Custom message: `On`

**Step 2 (Execute at 24h - configurable):**
- Same as Step 1, delay = `24h` (or your preferred interval)

**Step 3 (Execute at 7d - configurable, max 7d due to Zabbix limitation):**
- Same as Step 1, delay = `7d` (or your preferred interval ≤ 7 days)

**Recovery operations:**
- Send to media type: `Script - Unsupported Items Monitor`
- Same custom message settings

> **Note:** Zabbix has a 7-day limit for action operation steps. Configure your timing intervals accordingly.

#### Import Template

Go to **Configuration → Templates → Import** and upload `zbx_unsupported_monitor_xx.yaml`:


Then link the template **Zabbix Unsupported Monitoring** to your **Zabbix Server** host.

---

## 📊 How It Works

### Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ ZABBIX SERVER: Internal Event (Item became unsupported)         │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │ Internal Action Triggers     │
        │ (Step 1, Step 2, Step 3)     │
        │ Configurable timing          │
        └──────────────┬───────────────┘
                       │
                       ▼
        ┌──────────────────────────────────────┐
        │ Media Type calls script:             │
        │ zbx_unsupported_monitor.sh           │
        │ with parameters (HOST, ITEM, etc)    │
        └──────────────┬───────────────────────┘
                       │
        ┌──────────────▼───────────────┐
        │ PHASE 1: Log & Categorize    │
        │ ├─ Read ITEM.STATE           │
        │ ├─ Find entry in step1/2/3   │
        │ ├─ Move or update file       │
        │ └─ Write syslog entry        │
        └──────────────┬───────────────┘
                       │
        ┌──────────────▼───────────────┐
        │ PHASE 2: Wait (3 seconds)    │
        │ (allow other concurrent runs)│
        └──────────────┬───────────────┘
                       │
        ┌──────────────▼──────────────────────┐
        │ PHASE 3: Send Metrics via zabbix_   │
        │ sender                              │
        │ ├─ count (integer)                  │
        │ ├─ log (text)                       │
        │ └─ For each: step1, step2, step3    │
        └──────────────┬──────────────────────┘
                       │
        ┌──────────────▼──────────────────────┐
        │ ZABBIX SERVER: Receives metrics     │
        │ Items updated:                      │
        │ ├─ zabbix.unsupported.step1[count]  │
        │ ├─ zabbix.unsupported.step1[log]    │
        │ ├─ zabbix.unsupported.step2[count]  │
        │ ├─ zabbix.unsupported.step2[log]    │
        │ ├─ zabbix.unsupported.step3[count]  │
        │ └─ zabbix.unsupported.step3[log]    │
        └──────────────┬──────────────────────┘
                       │
        ┌──────────────▼──────────────────────┐
        │ Triggers evaluate:                  │
        │ ├─ Count threshold checks           │
        │ ├─ Delta detection (new items)      │
        │ ├─ Nodata checks                    │
        │ └─ Dependencies resolve             │
        └─────────────────────────────────────┘
```

### File Structure

```
/var/lib/zabbix/unsupported-items/
├── logs/
│   ├── unsupported_step1.txt  ← Items in first escalation window
│   ├── unsupported_step2.txt  ← Items in second escalation window
│   ├── unsupported_step3.txt  ← Items in third escalation window
│   └── .lock                  ← Concurrency lock file
└── .gitkeep
```

### File Format

Each line in the log files follows this format:

```
TIMESTAMP|HOST|ITEM_NAME|ITEM_KEY|STATE
```

Example:
```
2026.02.09 18:35:22|web-01|CPU Usage|proc.cpu.util[1m]|Not supported
2026.02.09 18:40:15|db-02|Memory Free|vm.memory.size[available]|Not supported
```

### State Transitions

```
NEW UNSUPPORTED → unsupported_step1.txt
                       ↓ (after 1st action trigger)
                  unsupported_step2.txt
                       ↓ (after 2nd action trigger)
                  unsupported_step3.txt
                       ↓ (after 3rd action trigger)
                  ← stays in step3 until RESOLVED

RESOLVED → Removed from all files immediately
```

---

## 📋 Template Details

### Items

| Item Key | Type | History | Purpose |
|----------|------|---------|---------|
| `zabbix.unsupported.step1[count]` | TRAP | 90d | Count in first escalation window (e.g., 1h) |
| `zabbix.unsupported.step1[log]` | TRAP (TEXT) | 7d | Detailed log for step1 |
| `zabbix.unsupported.step2[count]` | TRAP | 90d | Count in second escalation window (e.g., 24h) |
| `zabbix.unsupported.step2[log]` | TRAP (TEXT) | 7d | Detailed log for step2 |
| `zabbix.unsupported.step3[count]` | TRAP | 90d | Count in third escalation window (e.g., 7d) |
| `zabbix.unsupported.step3[log]` | TRAP (TEXT) | 7d | Detailed log for step3 |

### Triggers

| Name | Expression | Severity | Condition |
|------|------------|----------|-----------|
| New unsupported items (1h) | `change(...)>0` | INFO | Count increased in step1 |
| Unsupported items present (1h) | `last(...) >= {$UNSUP_1}` | INFO | Threshold crossed in step1 |
| Unsupported persistent (> 24h) | `last(...) >= {$UNSUP_2}` | AVERAGE | Threshold crossed in step2 |
| Unsupported persistent (> 7d) | `last(...) >= {$UNSUP_3}` | HIGH | Threshold crossed in step3 |
| Monitor not updating | `nodata(..., {$UNSUP_NODATA})=1` | AVERAGE | Script/sender failure |

### Macros

| Macro | Default | Purpose |
|-------|---------|---------|
| `{$UNSUP_1}` | `1` | Alert if count ≥ this in step1 |
| `{$UNSUP_2}` | `1` | Alert if count ≥ this in step2 |
| `{$UNSUP_3}` | `1` | Alert if count ≥ this in step3 |
| `{$UNSUP_NODATA}` | `10m` | Alert if no data for this duration |

### Configure Macros

Go to **Configuration → Templates → Zabbix Unsupported Monitoring → Macros** and adjust thresholds:

```
{$UNSUP_1}       = 2    # Alert if 2+ items in step1
{$UNSUP_2}       = 1    # Alert if 1+ items persisting in step2
{$UNSUP_3}       = 0    # Alert immediately if step3 items exist
{$UNSUP_NODATA}  = 15m  # Alert if script hasn't reported in 15 min
```

---

## 🔧 Configuration Examples

### Example 1: Strict Monitoring (DevOps)

Set low thresholds to catch issues early:

```
{$UNSUP_1}  = 1
{$UNSUP_2}  = 0
{$UNSUP_3}  = 0
```

**Action timing:** 1h, 24h, 7d  
**Result:** Alert on any unsupported item immediately, escalate severity by age.

### Example 2: Lenient Monitoring (Large Legacy)

Increase thresholds for environments with expected temporary issues:

```
{$UNSUP_1}  = 10
{$UNSUP_2}  = 3
{$UNSUP_3}  = 1
```

**Action timing:** 2h, 12h, 5d  
**Result:** Only alert after thresholds crossed, focus on persistent problems.

### Example 3: Critical Systems Only

Monitor specific host groups with stricter rules:

```
# Apply template only to "Critical-Servers" host group
{$UNSUP_1}  = 0      # Any unsupported = alert
{$UNSUP_2}  = 0
{$UNSUP_3}  = 0
```

**Action timing:** 30m, 4h, 2d  
**Result:** Maximum sensitivity for critical infrastructure.

---

## 🚀 Large-Scale Environments

### Handling >250 Unsupported Items

**Why chunking?**
- Prevents `Argument list too long` errors when passing large data to `zabbix_sender`
- Avoids frontend performance issues (HTTP 500 errors) when displaying very long logs
- Maintains data integrity even with 1000+ unsupported items

**How it works:**
- Each log metric (`step1[log]`, `step2[log]`, `step3[log]`) is sent in parts if >250 items
- Parts are sent sequentially with 1-second delay between transmissions
- Last part displayed in frontend includes header: `Part X/Y, row A-B - Total: N`
- Count metrics (`[count]`) always reflect the true total

---

## 📖 Usage

### Manual Testing

Test the script directly:

```bash
# Simulate "Not supported" event
/usr/lib/zabbix/alertscripts/zbx_unsupported_monitor.sh \
  "web-01" \
  "CPU Usage" \
  "proc.cpu.util[1m]" \
  "Not supported" \
  "18:30:45" \
  "2026.02.09"

# Simulate recovery
/usr/lib/zabbix/alertscripts/zbx_unsupported_monitor.sh \
  "web-01" \
  "CPU Usage" \
  "proc.cpu.util[1m]" \
  "Normal" \
  "18:35:22" \
  "2026.02.09"
```

### Check Log Files

```bash
# View current step1 unsupported items
cat /var/lib/zabbix/unsupported-items/logs/unsupported_step1.txt

# Watch for updates in real-time
tail -f /var/lib/zabbix/unsupported-items/logs/unsupported_step1.txt

# Count items in each category
wc -l /var/lib/zabbix/unsupported-items/logs/unsupported_*.txt
```

### Check Syslog

```bash
# View script logs
sudo journalctl -u zabbix-server -f -g "zbx-unsupported"

# Or traditional syslog
sudo tail -f /var/log/messages | grep zbx-unsupported
```

### Enable Debug Logging

Edit the script and set:

```bash
DEBUG=1  # Default is 1, change to 0 to disable
```

Then check stderr output when running manually.

---

## 🐛 Troubleshooting

### Issue: Script Not Executing

**Check script permissions:**
```bash
ls -la /usr/lib/zabbix/alertscripts/zbx_unsupported_monitor.sh
# Should show: -rwxr-xr-x zabbix zabbix
```

**Fix:**
```bash
sudo chmod 755 /usr/lib/zabbix/alertscripts/zbx_unsupported_monitor.sh
sudo chown zabbix:zabbix /usr/lib/zabbix/alertscripts/zbx_unsupported_monitor.sh
```

### Issue: Directory Permission Denied

**Check directory ownership:**
```bash
ls -ld /var/lib/zabbix/unsupported-items/logs
# Should show: drwxr-xr-x zabbix zabbix
```

**Fix:**
```bash
sudo chown -R zabbix:zabbix /var/lib/zabbix/unsupported-items
sudo chmod 755 /var/lib/zabbix/unsupported-items/logs
```

### Issue: zabbix_sender Fails

**Verify zabbix_sender is installed:**
```bash
which zabbix_sender
/usr/bin/zabbix_sender
```

**Test connectivity to Zabbix Server:**
```bash
/usr/bin/zabbix_sender -z 127.0.0.1 -p 10051 -s "ZABBIX-SERVER" -k "test" -o "value"
# Should return: sent: 1; skipped: 0; total: 1
```

**Fix hostname mismatch in script:**
Edit `zbx_unsupported_monitor.sh` and verify:
```bash
readonly ZABBIX_HOSTNAME="ZABBIX-SERVER"  # Must match host name in Zabbix
```

### Issue: Items Not Receiving Data

**Check if media type is working:**
1. Go to **Administration → Media types → Script - Unsupported Items Monitor**
2. Click **Test** and review output
3. Check Zabbix Server logs: `tail -f /var/log/zabbix/zabbix_server.log | grep alert`

**Verify trigger condition:**
```bash
# Internal action should have trigger condition:
# Event type = Item became unsupported
```

**Check script output in action log:**
1. Trigger an unsupported item manually
2. Go to **Monitoring → Problems**
3. Find the unsupported item
4. Check **Event details** → **Action log**

---

## 📈 Dashboard Integration

### Sample Dashboard Panel

Create a new **Dashboard → Add widget → Data overview**

**Data set:**
- Host: `ZABBIX-SERVER` (or your Zabbix host)
- Item: `zabbix.unsupported.step1[count]`

**Panel options:**
- Color scheme: Green (0) → Orange (1+) → Red (5+)
- Refresh interval: 1m
- Display value: Current value

### Custom Chart

Add **Graph** widget:
- Item: `zabbix.unsupported.step1[count]`
- Show: Last 7 days
- Graph type: Line

This shows escalation over time.

---

## 🛠️ Maintenance

### Cleanup Old Entries

The script automatically maintains:
- **step1 log**: Entries moved to step2 after 1st trigger
- **step2 log**: Entries moved to step3 after 2nd trigger
- **step3 log**: Manual cleanup via recovery operations or external tools

To manually clean old entries:

```bash
# Backup first
cp /var/lib/zabbix/unsupported-items/logs/unsupported_step3.txt \
   /var/lib/zabbix/unsupported-items/logs/unsupported_step3.txt.bak.$(date +%s)

# Clear a category (keep only recent entries)
echo "" > /var/lib/zabbix/unsupported-items/logs/unsupported_step3.txt
```

### Backup Logs

```bash
# Daily backup
tar czf /backup/unsupported-items-$(date +%Y%m%d).tar.gz \
  /var/lib/zabbix/unsupported-items/logs/
```

### Monitor Script Performance

```bash
# Count executions per hour
grep "Script started" /var/log/messages | grep zbx-unsupported | tail -1h | wc -l

# Check for errors
grep "ERROR\|Failed" /var/log/messages | grep zbx-unsupported | tail -20
```

---

## 📝 Script Behavior Details

### Concurrency Handling

The script uses **file-based locking** (`flock`) to prevent race conditions:

```bash
exec 9>"$lock_file"
flock -x 9  # Exclusive lock
```

**Why?** If multiple unsupported items trigger simultaneously, the lock ensures sequential file updates.

### State Normalization

The script accepts flexible state values:

| Input | Normalized to |
|-------|---------------|
| `Not supported`, `NOT SUPPORTED`, `not supported` | `Not supported` |
| `Normal`, `NORMAL`, `normal` | `Normal` |
| Any other value | Rejected with error |

### Timestamp Handling

- **If EVENT.TIME and EVENT.DATE provided**: Uses `{EVENT.DATE} {EVENT.TIME}` format
- **If empty/missing**: Falls back to current system time
- **Format**: `YYYY.MM.DD HH:MM:SS`

### Metric Output Format

Log entries are reformatted for readability before sending to Zabbix:

**Stored in file:**
```
2026.02.09 18:30:45|web-01|CPU Usage|proc.cpu.util[1m]|Not supported
```

**Sent to Zabbix (log metric):**
```
2026.02.09 18:30:45 - HOST: web-01 ITEM: CPU Usage KEY: proc.cpu.util[1m] STATE: Not supported
```


---

## 📄 License

MIT License © 2026 Nicola Gurgone (@N1k0droid)

See [LICENSE](LICENSE) for details.

---

## 🔗 References

- [Zabbix Documentation: Internal Events](https://www.zabbix.com/documentation/current/en/manual/config/notifications/unsupported_item)
- [Zabbix Media Type Scripts](https://www.zabbix.com/documentation/current/en/manual/config/notifications/media/script)
- [Zabbix Internal Actions](https://www.zabbix.com/documentation/current/en/manual/config/actions/internal)
- [Custom Alert Scripts Guide](https://www.zabbix.com/documentation/current/en/manual/installation/install_from_sources/frontend_web_setup#configuring-php)

---

## 📞 Support

- 🐛 Found a bug? [Open an issue](https://github.com/N1k0droid/zabbix-unsupported-items-monitor/issues)
- 💡 Have a suggestion? [Start a discussion](https://github.com/N1k0droid/zabbix-unsupported-items-monitor/discussions)
- 📧 Questions? Reach out via GitHub Discussions

---

## 🎉 Acknowledgments

Built for infrastructure teams managing complex Zabbix deployments. Inspired by community discussions on [Zabbix Forums](https://www.zabbix.com/forum) about better unsupported item handling.

**Author:** Nicola Carmelo Gurgone (@N1k0droid)  
**Version:** 4.0.0  
**Last Updated:** February 2026
