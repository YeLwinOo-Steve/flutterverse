<!--
Adding or removing a company in config/jobs.yaml.
CI runs `dart run fv_ingest:validate_jobs --remote`, which checks every
company's feed answers. Run it locally first if you can.
-->

## Company

| | |
|---|---|
| Name | |
| Hiring system | Greenhouse / Lever / Ashby |
| Job board URL | |
| Careers page (optional) | |

## Change

- [ ] Add a company
- [ ] Remove a company
- [ ] Fix a token, name or careers link

## Checklist

- [ ] The line follows the format in the header of `config/jobs.yaml` (`id`, `name`, `ats`, `token`).
- [ ] The company hires for Flutter or Dart, now or regularly.
- [ ] `dart run fv_ingest:validate_jobs --remote` passes.
