# Template - PanOS-API - HA Sync Status

Template for monitoring Palo Alto Networks (PAN-OS) High Availability synchronization status via XML API.

## Scope

This template monitors HA synchronization state on Palo Alto firewalls through the PAN-OS XML API.

Included checks:

- Running configuration synchronization status
- Running configuration sync enabled status
- Preemptive status
- LLD discovery of compatibility fields such as `DLP`, `build-compat`, `app-compat`, `iot-compat`, `av-compat`, `threat-compat`, `vpnclient-compat`, and `gpclient-compat`

## Requirements

- Zabbix 7.0 or newer recommended.
- Reachable firewall management IP or FQDN.
- PAN-OS administrator account with XML API access enabled.
- PAN-OS XML API key.

## Template macro

Set the following macro before using the template:

- `{$API_KEY}` → PAN-OS XML API key

The template sends requests to:

- `https://{HOST.CONN}/api/`

## API key generation

Palo Alto documents API key generation through `type=keygen`, and the returned key is contained in the `<key>` element of the XML response.

Officially documented example from Palo Alto:

```bash
curl -H "Content-Type: application/x-www-form-urlencoded" -X POST https://firewall/api/?type=keygen -d 'user=<user>&password=<password>'
```

Practical equivalent command commonly used for direct testing:

```bash
curl -g -k -X GET "https://<FW-IP>/api/?type=keygen&user=<USER>&password=<PASSWORD>"
```

Expected response:

```xml
<response status="success"><result><key>API_KEY</key></result></response>
```

Copy the value inside `<key>...</key>` and populate the `{$API_KEY}` macro.

## Configuration

1. Import the YAML template into Zabbix.
2. Link the template to the target Palo Alto host.
3. Set `HOST.CONN` to the management IP or FQDN.
4. Generate the API key.
5. Populate `{$API_KEY}` with the generated value.
6. Verify that the firewall account can execute the XML API operational request used by the template.
## Monitored data

Main item:

- `panos.ha.get.raw` → retrieves `show high-availability all`

Dependent items:

- `panos.ha.running_sync`
- `panos.ha.running_sync_enabled`
- `panos.ha.running_preemptive`
- `panos.ha.compat[{#COMPATNAME}]`

## Triggers

The template includes alerts for:

- No data received from HA API
- Running configuration not synchronized
- Running configuration sync disabled
- Preemptive disabled
- Compatibility mismatch
- No data received for discovered compatibility fields

## Reference

- [Get Your API Key](https://docs.paloaltonetworks.com/pan-os/9-1/pan-os-panorama-api/get-started-with-the-pan-os-xml-api/get-your-api-key#idca192ed7-45df-4992-a0f7-41ebe94fbdac)

## Notes

- This template uses the PAN-OS XML API, not the REST API.
- For production environments, use a dedicated API account with minimum required permissions.
