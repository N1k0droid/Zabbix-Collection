# Zabbix-Collection

Personal collection of Zabbix templates, configurations, best practices and monitoring knowledge base.

## Goals

- Provide **ready-to-import templates** and practical monitoring solutions.
- Keep everything organized by area (DB, Networking, Housekeeping, etc.).
- Share reusable building blocks (templates, discovery rules, scripts, docs).

## Repository structure

- `TEMPLATES/` → Zabbix templates and related docs/scripts.
- Each template folder may contain:
  - `.yaml` template export
  - `README.md` with setup notes (macros, prerequisites, examples)
  - Optional scripts or extra configuration steps

## Available templates

### DB

- **Zabbix Server - Slow Query Stats**  
  Path: `TEMPLATES/DB/Zabbix Server - Slow Query Stats`  
  Link: https://github.com/N1k0droid/Zabbix-Collection/tree/main/TEMPLATES/DB/Zabbix%20Server%20-%20Slow%20Query%20Stats  
  Description: Collect and visualize slow query statistics from the Zabbix Server DB (see template README for requirements and data source).

### Housekeeping

- **Housekeeping**  
  Path: `TEMPLATES/Housekeeping`  
  Link: https://github.com/N1k0droid/Zabbix-Collection/tree/main/TEMPLATES/Housekeeping  
  Description: Templates/notes to monitor housekeeping-related aspects (database size, history/trends growth, retention and general cleanup indicators, depending on the included items).

### Networking / Juniper

- **Juniper MX204 - LED Status Discovery**  
  Path: `TEMPLATES/Networking/Juniper/Led Status Discovery`  
  Template file: `juniper_mx204_led_template.yaml`  
  Link: https://github.com/N1k0droid/Zabbix-Collection/blob/main/TEMPLATES/Networking/Juniper/Led%20Status%20Discovery/juniper_mx204_led_template.yaml  
  Description: Discovery-based monitoring for chassis/module LED status on Juniper MX204 (typically via SNMP/OID discovery, see folder content for details).

### SMB

- **SMB**  
  Path: `TEMPLATES/SMB`  
  Link: https://github.com/N1k0droid/Zabbix-Collection/blob/main/TEMPLATES/SMB/README.md  
  Description: SMB-related monitoring content (see README for supported scenarios and setup).

### Zabbix Internal Monitoring

- **Unsupported Item Monitor**  
  Path: `TEMPLATES/Unsupported Item`  
  Link: https://github.com/N1k0droid/Zabbix-Collection/tree/main/TEMPLATES/Unsupported%20Item  
  Description: Track unsupported items with 24h/7d/30d “buckets”, generate log+count metrics and escalation via internal actions. Includes script + Zabbix configuration walkthrough.

## How to use (quick)

1. Download the `.yaml` template from the relevant folder.
2. Import in Zabbix: **Configuration → Templates → Import**.
3. Link the template to a host: **Configuration → Hosts → Templates → Add**.
4. Review template **macros** (if present) and adjust thresholds to your environment.
5. If the template requires extra steps (scripts, permissions, internal actions), follow the template folder `README.md`.

## Compatibility

These templates are written for modern Zabbix versions (7.0+ recommended unless otherwise stated in each template folder).

## Contributing / Feedback

- Suggestions and improvements are welcome via Issues/PRs.
- If you open an Issue, include: Zabbix version, OS, template name, screenshots/log snippets, and exact steps to reproduce.

## License

This repository may be **multi-licensed**: check each template folder for its license (or README) before reusing/distributing.
