# cgsf-name-format

A [Discourse](https://www.discourse.org/) plugin for [Connect St. Francis](https://connectstfrancis.com) that enforces the community's display-name convention: **first name + last initial** (e.g. "Maria G.").

Neighbors should know they're talking to a real person — never a full last name on the public internet.

## What it does

- **Shapes** what people type into the convention before saving: `maria garcia` → `Maria G.`, `Mary Jo Kowalski` → `Mary Jo K.`. The full last name is never stored.
- Validates the **Name** field on signup and profile changes against the "First L." pattern.
- Accepts: `Maria G.`, `Adam F`, `Mary Jo K.`, `D'Angelo R.`, `Anne-Marie B.`
- Rejects what it can't shape: lone first names, more than two given names.
- On the code-login signup/invite form (which has no plugin outlet at these fields), `api-initializers/cgsf-signup-name-fields.js` splits the name into **First name + Last name** boxes and writes only the shaped "Maria G." into core's hidden name input, so the full last name never leaves the browser. The username step gets a "usernames are public" note and a live preview. Keyed on core ids `code-login-name` / `code-login-username`; if core renames them, the stock form shows.
- On the legacy invite form: tells members their username is public and shows a live preview, "Neighbors will see you as: **Maria G.** @mariag". Usernames are the member's free choice. Preview text is editable in Admin → Customize → Text (`cgsf_name_format`).
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
