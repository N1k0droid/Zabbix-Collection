# Graylog Monitoring by REST API

[![Zabbix](https://img.shields.io/badge/Zabbix-7.0_LTS-D40000?logo=zabbix&logoColor=white)](https://www.zabbix.com/)
[![Graylog](https://img.shields.io/badge/Graylog-REST_API-FF3633)](https://graylog.org/)
[![Collection](https://img.shields.io/badge/N1k0droid-Zabbix--Collection-blue?logo=github)](https://github.com/N1k0droid/Zabbix-Collection)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](../../LICENSE)

A native **Zabbix 7 template** that collects operational metrics through the **Graylog REST API** by using Zabbix HTTP agent items, dependent items, JavaScript/JSONPath preprocessing, triggers, and low-level discovery (LLD).

It monitors Graylog buffers, journal, JVM, message throughput, traffic, processing latency, application logs, GELF, event processors, scheduler jobs, streams, stream rules, and Elasticsearch/OpenSearch indexer health.

No Zabbix agent, external script, `curl`, `jq`, Python, or Graylog plugin is required.


## Highlights

- Native monitoring through the Graylog HTTP/REST API.
- One master request for `/api/system/metrics`, shared by static items and discovery rules.
- One additional request for `/api/system/indexer/cluster/health`.
- Dependent items avoid one API request per metric.
- Automatic discovery of Graylog inputs and aggregation event processors.
- Multi-version scheduler discovery for current and legacy metric families.
- Optional allowlist-based discovery of streams and stream rules.
- Configurable thresholds for buffers, journal, JVM, logs, indexer shards, and traffic anomalies.
- HTTPS peer and hostname verification enabled.
- Safe handling of optional or version-specific Graylog metrics.
- Discovery validation and hard limits to prevent uncontrolled item creation.

## How it works

The primary HTTP agent item requests:

```text
{$GRAYLOG.API.SCHEME}://{$GRAYLOG.ENDPOINT}:{$GRAYLOG.API.PORT}{$GRAYLOG.API.PATH}
```

By default, this resolves to:

```text
https://localhost:9000/api/system/metrics
```

The response is validated as JSON and distributed to dependent items and discovery rules. JSONPath and JavaScript preprocessing extract individual Graylog gauges, counters, meters, timers, and histograms. Dependent items do not generate additional requests to Graylog.

A second HTTP agent item requests indexer health from:

```text
{$GRAYLOG.API.SCHEME}://{$GRAYLOG.ENDPOINT}:{$GRAYLOG.API.PORT}{$GRAYLOG.INDEXER.HEALTH.PATH}
```

The template also performs an independent TCP availability check against `{HOST.CONN}:{$GRAYLOG.TCP.PORT}`. With the default intervals, the template generates two Graylog API requests per minute plus the TCP check.

If a metric is not exposed by a particular Graylog version or configuration, the corresponding value is discarded instead of making the item unsupported. This allows one template to work across different Graylog metric sets, although the available items can vary by version and enabled feature.

## Static metrics

The template contains **47 static items**, including two raw API master items and the TCP service check.

| Area | Collected metrics |
|---|---|
| Availability | Metrics API payload validity; TCP service availability |
| Buffers | Input, process, and output buffer utilization (%) |
| Journal | Append rate; read rate; utilization; write-time p95; discarded writes; uncommitted entries; uncommitted messages; unflushed messages |
| JVM | Heap used, maximum, and utilization; direct buffer memory; live, runnable, blocked, and deadlocked threads |
| Throughput | Input and output messages per second |
| Traffic | Input and output bytes per second calculated from cumulative counters |
| Application logs | Cumulative DEBUG, INFO, WARN, ERROR, and FATAL events |
| Processing | Pipeline execution p95; message decode p95; process-buffer processing p95; invalid timestamps |
| GELF | Duplicate chunks and expired messages |
| Indexing | Elasticsearch output failures; indexer buffer flush failures; output process-time p95; indexer failure queue |
| Indexer health | Green/yellow/red state; active, initializing, relocating, and unassigned shards |

The indexer flush-failure item supports both the current `BatchedMessageFilterOutput` metric and the legacy `BlockingBatchedESOutput` metric.

Traffic deviation triggers compare a short-period average with a longer baseline and alert on sharp increases or decreases only when the minimum baseline is met. Counter-based triggers also ignore unrealistically large changes that can occur when Graylog restarts and a cumulative counter resets.

## Dynamic metrics

Low-level discovery uses the primary metrics payload and does not create extra API traffic.

| Discovery | Limit | Dynamically created metrics |
|---|---:|---|
| Graylog inputs | 100 inputs | Empty messages; incoming count; incoming one-minute rate; open connections; codec parse-time p95; processed one-minute rate; read bytes/s |
| Aggregation event processors | 100 processors | Executions; successful executions; exceptions; execution-time p95 |
| Scheduler | 7 allowlisted metrics | Failed executions; execution-time p95; free slots; total slots; waiting jobs; legacy running jobs; legacy total jobs |
| Configured streams | 20 streams | Incoming message count and one-minute rate |
| Configured stream rules | 20 rules | Rule execution-time p95 |

Input and event-processor IDs must be 24-character hexadecimal ObjectIds. The discovery scripts accept only known metric families and enforce entity limits.

Stream and stream-rule discovery are **disabled by default** because their allowlist macros are empty. They create items only for valid configured IDs that are also present in the Graylog metrics payload.

## Requirements

- Zabbix Server or Proxy must be able to connect to the Graylog REST API.
- A Zabbix host with a valid interface is required for the `{HOST.CONN}` TCP check.
- A dedicated Graylog user or access token with permission to read the required API endpoints.
- Basic HTTP authentication accepted by the Graylog endpoint.
- A trusted HTTPS certificate whose name matches `{$GRAYLOG.ENDPOINT}`, unless plain HTTP is intentionally used.
- Access to `/api/system/metrics` and, for indexer monitoring, `/api/system/indexer/cluster/health`.

Graylog operational metrics are available through its REST API and can be inspected from the Graylog API Browser. See the [Graylog operational metrics documentation](https://go2docs.graylog.org/current/interacting_with_your_log_data/metrics.html) and [REST API documentation](https://go2docs.graylog.org/current/setting_up_graylog/rest_api.html).

## Compatibility

| Component | Compatibility |
|---|---|
| Zabbix | Native YAML export schema `7.0`; designed for Zabbix 7.0 LTS. Test the import and trigger syntax before using it on later 7.x releases. |
| Graylog | Designed for Graylog installations exposing `/api/system/metrics`; includes compatibility logic for legacy and newer scheduler/output metric names. Metric availability depends on the Graylog version, plugins, inputs, and enabled features. |
| Graylog 3.x | Legacy metric families are supported where present. Some newer items, event processors, streams, scheduler, or indexer-health fields may be absent. |
| Graylog 4.x–6.x | Intended to use the current metric families while retaining selected legacy fallbacks. Validate against the exact release before production rollout. |
| Elasticsearch/OpenSearch | Monitored indirectly through Graylog's indexer-health API. This is not a replacement for direct Elasticsearch or OpenSearch monitoring. |
| Authentication | Basic authentication with a Graylog account, or a Graylog access token used through Basic authentication if supported by the installed release. |

This template intentionally tolerates missing version-specific metrics. Compatibility therefore means that the template remains usable; it does not mean every item exists on every Graylog release.

## Installation

### Create the Graylog user

Use a dedicated, non-administrative account for Zabbix. The following procedure creates `zbx-usr`, assigns the built-in `Reader` role, adds explicit access to Graylog system metrics, and verifies both API endpoints used by the template.

> Graylog menu names vary by release. User management may be under **System → Users**, **System → Authentication → Users**, or **System → Users and Teams**.

#### 1. Create `zbx-usr`

Sign in to the Graylog web interface as an administrator and create a local user with the following values:

| Field | Value/example |
|---|---|
| Username | `zbx-usr` |
| First name | `Zabbix` |
| Last name | `Monitoring` |
| Email | A valid service-account or operations address |
| Role | `Reader` |
| Password | A long, unique password stored in a secret manager |

Save the user. Graylog requires users to have either the built-in `Reader` or `Admin` role; use `Reader` for this non-administrative monitoring account.

All examples consistently use `zbx-usr`, which is also the default value of `{$GRAYLOG.API.USER}`. If you choose a different username, update the Zabbix macro accordingly.

#### 2. Create `Metrics Access`

Graylog's documented restricted-user pattern grants `metrics:*` to retrieve the complete `/system/metrics` resource. Some releases include `metrics:read` in the built-in `Reader` role, but the explicit `Metrics Access` role ensures the monitoring integration has the required metrics permissions without assigning `Admin`.

Run the following command from a trusted Linux shell that can reach Graylog. Supplying only `-u 'admin'` makes `curl` prompt for the administrator password instead of placing it in shell history:

```bash
curl -sS -u 'admin' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-Requested-By: cli' \
  -X POST \
  -d '{
    "name": "Metrics Access",
    "description": "Read access to Graylog system metrics for Zabbix",
    "permissions": ["metrics:*"],
    "read_only": false
  }' \
  'https://<FQDN-Graylog-server>:9000/api/roles' |
python3 -m json.tool
```

Replace `<FQDN-Graylog-server>` with the certificate-matching Graylog FQDN. Do not add `-k` only to bypass certificate errors; install the issuing CA on the administration client and Zabbix Server/Proxy instead.

If the role might already exist, inspect it before attempting to create it again:

```bash
curl -sS -u 'admin' \
  -H 'Accept: application/json' \
  'https://<FQDN-Graylog-server>:9000/api/roles/Metrics%20Access' |
python3 -m json.tool
```

Permission names can differ between major Graylog releases. The permissions exposed by the installed server can be inspected with an administrator account:

```bash
curl -sS -u 'admin' \
  -H 'Accept: application/json' \
  'https://<FQDN-Graylog-server>:9000/api/system/permissions' |
python3 -m json.tool
```

#### 3. Assign the role

Return to the Graylog web interface, edit `zbx-usr`, assign **Metrics Access** in addition to **Reader**, and save the user.

The two roles serve different purposes:

- `Reader` supplies Graylog's basic read-only permissions, including permissions needed by related system endpoints such as indexer-cluster health on supported releases.
- `Metrics Access` explicitly grants access to the complete operational metrics resource.

Do not assign `Admin` to the Zabbix monitoring account.

#### 4. Verify metrics on Linux

Test with `zbx-usr` first. Testing only with `admin` proves that the endpoint exists, but does not prove that the monitoring account has sufficient permissions.

Save the operational metrics and print the HTTP status:

```bash
curl -sS -u 'zbx-usr' \
  -H 'Accept: application/json' \
  -o /tmp/graylog-metrics.json \
  -w 'HTTP %{http_code}\n' \
  'https://<FQDN-Graylog-server>:9000/api/system/metrics'
```

Validate the downloaded JSON:

```bash
python3 -m json.tool /tmp/graylog-metrics.json >/dev/null &&
echo 'Valid Graylog metrics JSON'
```

The request must return HTTP `200`. The response should contain one or more top-level metric sections such as `gauges`, `meters`, `counters`, `timers`, or `histograms`.

Verify the second endpoint used by the template:

```bash
curl -sS -u 'zbx-usr' \
  -H 'Accept: application/json' \
  -o /tmp/graylog-indexer-health.json \
  -w 'HTTP %{http_code}\n' \
  'https://<FQDN-Graylog-server>:9000/api/system/indexer/cluster/health'

python3 -m json.tool /tmp/graylog-indexer-health.json
```

If `zbx-usr` fails while `admin` succeeds, the problem is authorization rather than endpoint availability. Use the administrator account only as a diagnostic comparison:

```bash
curl -sS -u 'admin' \
  -H 'Accept: application/json' \
  -o /tmp/graylog-metrics-admin.json \
  -w 'HTTP %{http_code}\n' \
  'https://<FQDN-Graylog-server>:9000/api/system/metrics'
```

Run the final tests from the Zabbix Server or Proxy that will execute the HTTP agent items. A successful test from an administrator workstation does not prove that DNS, routing, firewall rules, TLS trust, or credentials work from the Zabbix poller.

#### 5. Verify metrics on Windows

In PowerShell, use `curl.exe` explicitly because `curl` can be an alias in older Windows PowerShell installations. These commands prompt for the password and save the responses in the current directory:

```powershell
curl.exe -sS -u "zbx-usr" `
  -H "Accept: application/json" `
  -o ".\graylog-metrics.json" `
  -w "HTTP %{http_code}`n" `
  "https://<FQDN-Graylog-server>:9000/api/system/metrics"

curl.exe -sS -u "zbx-usr" `
  -H "Accept: application/json" `
  -o ".\graylog-indexer-health.json" `
  -w "HTTP %{http_code}`n" `
  "https://<FQDN-Graylog-server>:9000/api/system/indexer/cluster/health"
```

Validate the saved files in PowerShell:

```powershell
Get-Content -Raw ".\graylog-metrics.json" | ConvertFrom-Json | Out-Null
Get-Content -Raw ".\graylog-indexer-health.json" | ConvertFrom-Json | Out-Null
Write-Host "Valid Graylog API JSON"
```

If required for diagnosis, repeat the first request with `-u "admin"` and save it under a different filename:

```powershell
curl.exe -sS -u "admin" `
  -H "Accept: application/json" `
  -o ".\graylog-metrics-admin.json" `
  -w "HTTP %{http_code}`n" `
  "https://<FQDN-Graylog-server>:9000/api/system/metrics"
```

Do not overwrite the `zbx-usr` result: comparing status codes and payload structures helps isolate permission problems.

The downloaded files can contain internal component names, node details, IDs, rates, and capacity information. Treat them as operationally sensitive and sanitize them before attaching them to a public GitHub issue.

### Import into Zabbix

1. Create and verify the dedicated Graylog monitoring user as described above.
2. Download the YAML file from this folder.
3. In Zabbix, open **Data collection → Templates → Import**.
4. Select the YAML file and review the import changes.
5. Import `Template - Graylog Monitoring by REST API`.
6. Create or select the Zabbix host representing the Graylog node.
7. Ensure the host interface used by `{HOST.CONN}` points to the node checked by the TCP item.
8. Link the template to the host.
9. Override the connection and credential macros at host or template level.
10. Wait at least two polling intervals and check **Monitoring → Latest data**.
11. Confirm that both raw HTTP items return valid data and that the LLD rules have run.
12. Review all trigger thresholds before enabling alerts in production.

Zabbix documents YAML template import in its [template import guide](https://www.zabbix.com/documentation/7.0/en/manual/xml_export_import/templates).

## Basic configuration

Review these macros for every monitored host.

| Macro | Default | Purpose |
|---|---:|---|
| `{$GRAYLOG.ENDPOINT}` | `localhost` | Graylog API hostname, IP address, or FQDN. Do not include protocol, port, or path. |
| `{$GRAYLOG.API.SCHEME}` | `https` | API protocol: `http` or `https`. |
| `{$GRAYLOG.API.PORT}` | `9000` | Graylog REST API port. |
| `{$GRAYLOG.API.PATH}` | `/api/system/metrics` | Operational metrics endpoint. |
| `{$GRAYLOG.API.USER}` | `zbx-usr` | Dedicated Graylog monitoring username. |
| `{$GRAYLOG.API.PASSWORD}` | empty | Monitoring-user password. |
| `{$GRAYLOG.API.INTERVAL}` | `1m` | Operational metrics polling interval. |
| `{$GRAYLOG.API.TIMEOUT}` | `15s` | HTTP request timeout. |
| `{$GRAYLOG.TCP.PORT}` | `9000` | Port checked against `{HOST.CONN}` by the simple TCP item. |
| `{$GRAYLOG.INDEXER.HEALTH.PATH}` | `/api/system/indexer/cluster/health` | Indexer-health endpoint. |
| `{$GRAYLOG.INDEXER.HEALTH.INTERVAL}` | `1m` | Indexer-health polling interval. |

Do not store real credentials in the public repository. Keep the password macro empty in the shared template and override it on each host using a **Secret text** macro or your preferred Zabbix secret-management method.

### Example

```text
{$GRAYLOG.ENDPOINT}             = graylog01.example.net
{$GRAYLOG.API.SCHEME}           = https
{$GRAYLOG.API.PORT}             = 9000
{$GRAYLOG.API.USER}             = zbx-usr
{$GRAYLOG.API.PASSWORD}         = <secret>
{$GRAYLOG.TCP.PORT}             = 9000
```

## Threshold macros

Defaults are starting points, not universal production values. Tune them to the normal workload and capacity of each Graylog node.

| Macro | Default | Trigger use |
|---|---:|---|
| `{$GRAYLOG.BUFFER.WARN}` | `70` | Warning threshold for input, process, and output buffer utilization. |
| `{$GRAYLOG.BUFFER.HIGH}` | `90` | High threshold for input, process, and output buffer utilization. |
| `{$GRAYLOG.JOURNAL.WARN}` | `70` | Journal utilization warning (%). |
| `{$GRAYLOG.JOURNAL.HIGH}` | `85` | Journal utilization high threshold (%). |
| `{$GRAYLOG.JOURNAL.ENTRIES.WARN}` | `10000` | Uncommitted journal-entry threshold sustained for 10 minutes. |
| `{$GRAYLOG.JOURNAL.UNCOMMITTED.WARN}` | `10000` | Uncommitted journal-message threshold sustained for 10 minutes. |
| `{$GRAYLOG.JOURNAL.UNFLUSHED.WARN}` | `1000` | Unflushed journal-message threshold sustained for 10 minutes. |
| `{$GRAYLOG.JVM.HEAP.WARN}` | `75` | JVM heap utilization warning (%). |
| `{$GRAYLOG.JVM.HEAP.HIGH}` | `85` | JVM heap utilization high threshold (%). |
| `{$GRAYLOG.JVM.BLOCKED.MAX}` | `5` | Maximum blocked threads sustained for 5 minutes. |
| `{$GRAYLOG.LOG.ERRORS.MAX}` | `5` | Maximum new ERROR events between samples. |
| `{$GRAYLOG.LOG.WARN.MAX}` | `10` | Maximum new WARN events between samples. |
| `{$GRAYLOG.INDEXER.FAILURE.QUEUE.MAX}` | `0` | Maximum indexer failure-queue size sustained for 5 minutes. |
| `{$GRAYLOG.INDEXER.SHARDS.UNASSIGNED.MAX}` | `0` | Maximum unassigned shards sustained for 5 minutes. |
| `{$GRAYLOG.INDEXER.SHARDS.INITIALIZING.MAX}` | `0` | Maximum initializing shards sustained for 10 minutes. |
| `{$GRAYLOG.INDEXER.SHARDS.RELOCATING.MAX}` | `0` | Maximum relocating shards sustained for 10 minutes. |
| `{$GRAYLOG.INPUT.NODATA.PERIOD}` | `10m` | Evaluation period for the disabled per-input no-traffic trigger. |
| `{$GRAYLOG.TRAFFIC.SHORT.PERIOD}` | `5m` | Short window for node traffic anomaly detection. |
| `{$GRAYLOG.TRAFFIC.BASELINE.PERIOD}` | `1h` | Baseline window for node traffic anomaly detection. |
| `{$GRAYLOG.TRAFFIC.BASELINE.MIN}` | `1024` | Minimum baseline traffic in Bps before anomaly triggers are evaluated. |
| `{$GRAYLOG.TRAFFIC.INCREASE.PCT}` | `80` | Increase above baseline that triggers a warning. |
| `{$GRAYLOG.TRAFFIC.DECREASE.PCT}` | `80` | Decrease below baseline that triggers a warning. |

Warning triggers for high buffer, journal, and JVM utilization depend on their corresponding high-severity triggers to reduce duplicate notifications.

## Optional stream monitoring

Stream monitoring is allowlist-based and disabled until IDs are configured.

### Streams

Set `{$GRAYLOG.STREAM.IDS}` to a comma-separated list of Graylog stream ObjectIds:

```text
{$GRAYLOG.STREAM.IDS} = 64a111111111111111111111,64a222222222222222222222
```

| Macro | Default | Purpose |
|---|---:|---|
| `{$GRAYLOG.STREAM.IDS}` | empty | Comma-separated stream-ID allowlist. Empty disables discovery. |
| `{$GRAYLOG.STREAM.MAX}` | `20` | Maximum streams accepted; values above 20 are capped at 20. |
| `{$GRAYLOG.STREAM.NODATA.PERIOD}` | `10m` | Period for the disabled no-traffic trigger. |
| `{$GRAYLOG.STREAM.SHORT.PERIOD}` | `5m` | Short stream-rate averaging window. |
| `{$GRAYLOG.STREAM.BASELINE.PERIOD}` | `1h` | Stream-rate baseline window. |
| `{$GRAYLOG.STREAM.BASELINE.MIN}` | `1` | Minimum baseline in msg/s before deviation alerts are evaluated. |
| `{$GRAYLOG.STREAM.INCREASE.PCT}` | `80` | Stream-rate increase above baseline that triggers a warning. |
| `{$GRAYLOG.STREAM.DECREASE.PCT}` | `80` | Stream-rate decrease below baseline that triggers a warning. |

The per-stream no-traffic trigger prototype is disabled by default. Enable it only for streams expected to receive messages continuously.

### Stream rules

Set `{$GRAYLOG.STREAM.RULES}` to comma-separated `stream_id:rule_id` pairs:

```text
{$GRAYLOG.STREAM.RULES} = 64a111111111111111111111:64b111111111111111111111
```

| Macro | Default | Purpose |
|---|---:|---|
| `{$GRAYLOG.STREAM.RULES}` | empty | Allowlist of `stream_id:rule_id` pairs. Empty disables discovery. |
| `{$GRAYLOG.STREAM.RULE.MAX}` | `20` | Maximum rules accepted; values above 20 are capped at 20. |
| `{$GRAYLOG.STREAM.RULE.P95.WARN}` | `1` | Stream-rule p95 execution-time warning threshold in seconds. |
| `{$GRAYLOG.STREAM.RULE.P95.PERIOD}` | `5m` | Evaluation period for slow stream-rule execution. |

Only valid 24-character hexadecimal IDs whose metrics exist in the payload are discovered. The template displays IDs because it does not make extra API calls to resolve stream or rule names.

## Main alerts

The included triggers cover:

- Invalid or unavailable Graylog metrics API payload.
- Graylog TCP service unavailable.
- High and critical input, process, or output buffer utilization.
- High or critical journal utilization and persistent journal backlog.
- Discarded journal writes.
- High JVM heap usage, blocked threads, and JVM deadlocks.
- New WARN, ERROR, or FATAL application events.
- New GELF expired messages and invalid timestamps.
- Elasticsearch output failures and indexer buffer-flush failures.
- Non-empty indexer failure queue.
- Indexer health unavailable, yellow, or red.
- Persistent initializing, relocating, or unassigned shards.
- Sharp increases or decreases in input/output byte traffic.
- Event-processor exceptions.
- Empty input messages.
- Optional input or stream no-traffic conditions, disabled by default.
- Stream traffic anomalies and slow stream rules when stream monitoring is configured.

## HTTPS and security

The HTTP agent items use `verify_peer: YES` and `verify_host: YES`. For private or self-signed PKI, install the appropriate CA certificate on the Zabbix Server/Proxy rather than disabling TLS verification.

Recommended practices:

- Use the dedicated `zbx-usr` identity with `Reader` and `Metrics Access` roles.
- Store credentials as host-level Secret text macros or external secrets.
- Restrict API access to the Zabbix Server/Proxy network addresses.
- Use HTTPS for credentials and metrics in transit.
- Grant only the permissions required by this template.
- Never use the Graylog administrator account in Zabbix.

## Troubleshooting

### API item is unsupported

Check `Graylog: Get metrics` in **Monitoring → Latest data** and review the preprocessing error.

- Confirm the URL, port, path, username, and password.
- Run the test request from the Zabbix Server or Proxy, not only from a workstation.
- Confirm that a reverse proxy is not returning an HTML login or error page.
- Verify the certificate chain and hostname when using HTTPS.
- Confirm that the response contains at least one Graylog metric section such as `gauges`, `meters`, `counters`, or `timers`.

### HTTP 401 or 403

- HTTP `401` normally indicates invalid credentials or an authentication problem.
- HTTP `403` normally indicates that the authenticated user lacks permission.
- Confirm that `zbx-usr` has both `Reader` and `Metrics Access`.
- Compare the result with an administrator request only for diagnosis.
- Query `/api/system/permissions` to verify the permission names available on the installed Graylog version.

### Indexer health is unavailable

If the status item is `-1`, test `/api/system/indexer/cluster/health` directly using `zbx-usr`. The endpoint may be unavailable in the installed Graylog version, blocked by permissions, or changed by a reverse-proxy base path.

### Expected items are missing

- Graylog may not expose that metric on the installed version.
- The associated input, plugin, event processor, stream, or scheduler component may not be active.
- Input and event-processor IDs must match a 24-character hexadecimal ObjectId.
- Stream and stream-rule IDs must be explicitly allowlisted.
- A discovery cap may have been reached.
- Some metrics appear only after the component has processed data.

### TCP check fails but API works

The TCP item checks `{HOST.CONN}`, while the API items use `{$GRAYLOG.ENDPOINT}`. Align the host interface with the Graylog node or modify the TCP item if these addresses intentionally differ.

### Traffic rate has no first value

The Bps items use change-per-second preprocessing on cumulative counters and need at least two valid samples before calculating a rate.

## Scope and limitations

This is an application-level Graylog monitoring template. It does not replace:

- Operating-system monitoring for CPU, RAM, disk, filesystem, network, or process state.
- Kernel-level UDP packet-loss and receive-error monitoring.
- Direct MongoDB monitoring.
- Direct Elasticsearch or OpenSearch performance and capacity monitoring.
- Monitoring of load balancer or reverse-proxy infrastructure.

For complete coverage, link an appropriate Linux or Windows template and dedicated database/search-cluster templates to the relevant hosts.

## Repository integration

This template is part of the [N1k0droid - Zabbix Collection](https://github.com/N1k0droid/Zabbix-Collection), a collection of Zabbix templates, configurations, monitoring best practices, discovery rules, scripts, and operational documentation.



## Contributing

Issues and pull requests are welcome. When reporting a problem, include:

- Zabbix Server/Proxy and frontend version.
- Graylog version and edition.
- Elasticsearch/OpenSearch version where relevant.
- Failed item or discovery-rule name.
- Item error and sanitized API response structure.
- Whether Graylog is accessed directly or through a reverse proxy.

Never include passwords, access tokens, session cookies, or unsanitized sensitive logs.

## License

Unless a separate license is added to this folder, this template follows the repository's [GNU General Public License v3.0](../../LICENSE). It is provided without warranty; validate all items, triggers, permissions, and thresholds in a test environment before production use.
