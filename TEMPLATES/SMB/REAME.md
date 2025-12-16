# SMB Shares Monitoring – Zabbix Template

Zabbix template for discovering and monitoring disk usage on SMB shares (Total, Used, Free, Free %, Used %).

---

## Requirements

- Zabbix Server (tested on 7.0).
- Shell access to the Zabbix server.
- `smbclient` package installed.
- External scripts enabled and a directory configured (for example `/usr/lib/zabbix/externalscripts` – adjust according to your setup).

---

## External scripts installation

1. Copy the scripts into the Zabbix external scripts directory.
   
3. Make the scripts executable:

   ```bash
   chmod +x /usr/lib/zabbix/externalscripts/discover_smb_shares.sh
   chmod +x /usr/lib/zabbix/externalscripts/check_smb_folder_size-v2.sh
   ```

4. Test the scripts manually from the Zabbix server (as `zabbix` user):

   ```bash
   sudo -u zabbix /usr/lib/zabbix/externalscripts/discover_smb_shares.sh '\\server\share'
   sudo -u zabbix /usr/lib/zabbix/externalscripts/check_smb_folder_size-v2.sh '\\server\share' user password DOMAIN total
   ```

   Make sure you get valid JSON from the discovery script and a numeric value from the check script.

---

## Template import

1. In the Zabbix UI go to:  
   `Configuration → Templates → Import`.
2. Select the `SMB_Shares_Monitoring.yaml` file.
3. Import it with default options.
4. Link the template to the desired host(s):  
   `Configuration → Hosts → [host] → Templates → Link new template`.

---

## Macros to configure

The template uses the following macros, which can be set at template level or overridden per host.

### `{$SMB.USER}`

- Description: SMB user with read access to the shares.
- Example:  
  `zabbix_monitor`

### `{$SMB.PASSWORD}`

- Description: Password of the SMB user.
- Type: Secret text in the template (hidden).
- Example:  
  `MyS3cretP@ss`

### `{$SMB.DOMAIN}`

- Description: SMB domain or workgroup.
- If you do not use AD, you can set the workgroup name or leave it empty if authentication works without it.
- Examples:  
  `MYDOMAIN`  
  `WORKGROUP`

### `{$SMB.SHARES.LIST}`

- Description: Comma-separated list of SMB shares to monitor.
- Format: UNC paths with double backslashes as required by the scripts.
- Examples:

  ```text
  \\fileserver1\share1,\\fileserver2\backup,\\10.0.0.10\Archive
  ```

---

## How it works

- The discovery rule calls `discover_smb_shares.sh` using the `{$SMB.SHARES.LIST}` macro to generate LLD data.
- For each discovered share, the template creates items for:
  - Total size (bytes)
  - Used space (bytes)
  - Free space (bytes)
  - Free space (%)
  - Used space (%)
- The `check_smb_folder_size-v2.sh` script is used as an external check for each metric/share combination.
- Trigger prototypes are included to alert on high usage thresholds (for example >80%, >85%, >90% used).
