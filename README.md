# cgsf-name-format

A [Discourse](https://www.discourse.org/) plugin for [Connect St. Francis](https://connectstfrancis.com) that enforces the community's display-name convention: **first name + last initial** (e.g. "Maria G.").

Neighbors should know they're talking to a real person — never a full last name on the public internet.

## What it does

- Validates the **Name** field on signup and profile changes against the "First L." pattern.
- Accepts: `Maria G.`, `Adam F`, `Mary Jo K.`, `D'Angelo R.`, `Anne-Marie B.`
- Rejects: full last names, lone first names, lowercase.
- Existing users are grandfathered — only *changed* names are validated.
- System/bot accounts are exempt.

## Settings

| Setting | Default | Purpose |
|---|---|---|
| `cgsf_name_format_enabled` | `true` | Master switch for the validation |

## Install

Add to your `app.yml` under `hooks / after_code / exec / cmd`:

```yaml
- git clone https://github.com/adamfollmer/cgsf-name-format.git
```

then `./launcher rebuild app`.

## Development

Specs: `LOAD_PLUGINS=1 bundle exec rspec plugins/cgsf-name-format/spec`
