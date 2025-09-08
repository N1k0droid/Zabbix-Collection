# Zabbix 7.0 Slow Query Monitoring Templates

Comprehensive database slow query monitoring templates for **Zabbix 7.0+** using **Zabbix Agent**.

## 📋 Overview

These templates monitor database slow queries directly from Zabbix Server logs, providing insights into database performance issues and query optimization opportunities.

## 🎯 What Gets Monitored

| Metric | Description | Update Interval |
|--------|-------------|----------------|
| **Slow Query SQL** | Actual SQL query text | Real-time |
| **Slow Query Time** | Execution time in seconds | Real-time |
| **Daily Commit Count** | Slow commits per day | 5 minutes |
| **Daily Delete Count** | Slow deletes per day | 5 minutes |
| **Daily Insert Count** | Slow inserts per day | 5 minutes |
| **Daily Update Count** | Slow updates per day | 5 minutes |
| **Daily Total Count** | Total slow queries per day | 5 minutes |

## ⚙️ Requirements

### Zabbix Server
- **Zabbix Server 7.0** or higher
- **Database**: MySQL/MariaDB or PostgreSQL
- **Log file access** for Zabbix Agent

### Zabbix Agent
- **Zabbix Agent 6.0+** (compatible with 7.0 server)
- **File read permissions** on Zabbix Server log

## 🔧 Server Configuration

### 1. Enable Slow Query Logging

Edit `/etc/zabbix/zabbix_server.conf`:

```ini
### SLOW QUERY CONFIGURATION ###
# Enable debug level 3 (required for LogSlowQueries)
DebugLevel=3

# Log queries slower than 3000ms (3 seconds)
LogSlowQueries=3000

# Optional: Increase log file size limits
LogFileSize=100
```

### 2. Recommended LogSlowQueries Values

| Environment | Value | Description |
|-------------|-------|-------------|
| **Development** | `1000` | 1 second - aggressive monitoring |
| **Production** | `3000` | 3 seconds - balanced approach |
| **High-load Production** | `5000` | 5 seconds - fewer false positives |
| **Large Database** | `10000` | 10 seconds - only critical issues |

### 3. Restart Zabbix Server

```bash
sudo systemctl restart zabbix-server
sudo systemctl status zabbix-server
```

### 4. Verify Logging

Check that slow queries are being logged:
```bash
# Monitor for slow queries
tail -f /var/log/zabbix/zabbix_server.log | grep "slow query"

# Count today's slow queries
grep "slow query" /var/log/zabbix/zabbix_server.log | grep $(date '+%Y%m%d') | wc -l
```

## 🔧 Agent Configuration

### Active Mode (Recommended)

Edit `/etc/zabbix/zabbix_agentd.conf`:

```ini
### ACTIVE AGENT CONFIGURATION ###
# Server for active checks
ServerActive=your.zabbix.server

# Agent hostname (must match Zabbix host configuration)
Hostname=your-zabbix-server

# Buffer size for active checks
BufferSize=1000
```

### File Permissions

Ensure Zabbix agent can read the log file:

```bash
# Set proper ownership and permissions
sudo chown zabbix:zabbix /var/log/zabbix/zabbix_server.log
sudo chmod 644 /var/log/zabbix/zabbix_server.log

# Add zabbix user to adm group (if needed)
sudo usermod -a -G adm zabbix

# Verify permissions
sudo -u zabbix cat /var/log/zabbix/zabbix_server.log | tail -5
```

### Restart Agent

```bash
sudo systemctl restart zabbix-agent
sudo systemctl status zabbix-agent
```

## 📥 Template Installation

### 1. Download Template

### 2. Import Template
1. Go to **Configuration** → **Templates**
2. Click **Import**
3. Choose your template file
4. Click **Import**

### 3. Link to Host
1. Go to **Configuration** → **Hosts**
2. Find your **Zabbix Server** host
3. Click **Templates** tab
4. **Link** the slow query template
5. **Update**

## 🎛️ Template Configuration

### Macro Settings

| Macro | Default | Description | Recommended Values |
|-------|---------|-------------|-------------------|
| `{$SLOW.QUERY.WARN}` | `10` | Daily slow query threshold | Small env: `5`<br>Medium env: `20`<br>Large env: `50` |
| `{$ZBX.LOG.PATH}` | `/var/log/zabbix/zabbix_server.log` | Zabbix server log path | Adjust if different location |

### Customizing Thresholds

**For Small Environment (< 1000 items):**
```
{$SLOW.QUERY.WARN} = 5
LogSlowQueries = 2000
```

**For Medium Environment (1000-10000 items):**
```
{$SLOW.QUERY.WARN} = 20
LogSlowQueries = 3000
```

**For Large Environment (> 10000 items):**
```
{$SLOW.QUERY.WARN} = 50
LogSlowQueries = 5000
```

## 🚨 Triggers & Alerts

### Default Trigger
- **Name**: "High Number of Slow Queries per Day"
- **Expression**: `last() >= {$SLOW.QUERY.WARN}`
- **Severity**: Warning
- **Description**: Alerts when daily slow query count exceeds threshold

### Sample Log Entries

When working correctly, you'll see entries like:
```
301096:20240908:120135.386 slow query: 3.468095 sec, "commit;"
301095:20240908:120135.387 slow query: 4.271073 sec, "insert into history_uint (itemid,clock,ns,value) values..."
301094:20240908:120140.156 slow query: 8.054528 sec, "update hosts set lastaccess=1725789815 where hostid=10084"
```

## 🔍 Troubleshooting

### No Slow Queries Detected
1. **Check DebugLevel**: Must be 3 or 4
2. **Verify LogSlowQueries**: Set appropriate threshold
3. **Check permissions**: Agent must read log file
4. **Test manually**:
   ```bash
   sudo -u zabbix cat /var/log/zabbix/zabbix_server.log | grep "slow query"
   ```

### Agent Connection Issues

```bash
# Test agent connectivity
zabbix_get -s 127.0.0.1 -k agent.ping

# Check agent logs
tail -f /var/log/zabbix/zabbix_agentd.log
```

### High Log Volume

If logs grow too fast:
```ini
# In zabbix_server.conf
LogFileSize=50          # Reduce log file size
LogSlowQueries=5000     # Increase threshold
```

## 📊 Performance Impact

### Server Impact
- **DebugLevel=3**: Increases log volume significantly
- **CPU**: Minimal impact on log processing
- **Disk I/O**: Monitor log file growth

### Agent Impact
- **Active mode**: Lower server CPU usage
- **Log reading**: Minimal CPU/memory impact

## 📈 Best Practices

### 1. Start Conservative
```ini
LogSlowQueries=5000    # Start high, reduce gradually
{$SLOW.QUERY.WARN}=50  # Start high threshold
```

### 2. Monitor Database Performance
- Use slow query data to identify problem queries
- Correlate with database monitoring templates
- Plan maintenance windows based on patterns

### 4. Alerting Strategy
- **INFO**: Daily count > 10
- **WARNING**: Daily count > 50
- **AVERAGE**: Daily count > 100
- **HIGH**: Individual query > 30 seconds

## 🔗 Related Templates

Consider combining with:
- **MySQL by Zabbix Agent** - Database performance metrics
- **PostgreSQL by Zabbix Agent** - PostgreSQL specific monitoring
- **Linux by Zabbix Agent** - System resource monitoring

## 🤝 Credits

- **Original concept**: diasdm - [Zabbix_Out_of_The_Box](https://github.com/diasdmhub/Zabbix_Out_of_The_Box/)
- **7.0 Compatibility**: N1k0droid
- **License**: GNU General Public License v3.0

---

> **Production Note**: Always test in a development environment before deploying to production. Monitor disk space when enabling DebugLevel=3.
