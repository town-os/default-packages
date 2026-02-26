# Default Town OS Package Repository

**NOTE:** Until this notice is removed, we are experimenting with generating large numbers of packages using Claude. Feel free to try these packages -- they're pretty safe to launch -- but they may not actually work. Send pull requests if you want to shape them up! At some point, this notice will be removed and the rest of the terms around trust and reliability take more importance.

The official default package repository for [Town OS](https://github.com/town-os/town-os). This repository is included automatically on every Town OS installation and provides packages that have been reviewed by the Town OS maintainers. Packages in this repository are expected to be trustworthy, well-tested, and behave as described.

## Repository structure

```
packages/
  <package-name>/
    <version>.yaml
```

Each package is a directory under `packages/` containing one or more versioned YAML files. For example:

```
packages/
  nginx/
    1.0.yaml
    2.0.yaml
  postgres/
    1.0.yaml
```

## Package format

Package definitions are YAML files with the following fields:

```yaml
image: nginx:1.26-alpine
description: Lightweight high-performance web server and reverse proxy
supplies: ["http"]
command: ["optional", "command", "override"]
environment:
  NGINX_HOST: "@hostname@"
network:
  external:
    "@port@": "80"
  internal:
    "5432": "5432"
volumes:
  html:
    mountpoint: /usr/share/nginx/html
    quota: 2gb
    uid: 1000
    gid: 1000
  data:
    mountpoint: /data
    archive: seed-data.tar.gz
questions:
  hostname:
    query: "What hostname should nginx serve?"
    type: hostname
  port:
    query: "What external port should nginx listen on?"
    type: port
    default: "8080"
archives:
  - image: nginx:latest
    directory: /usr/share/nginx/html
    volume: html
notes:
  URL:
    value: "http://@hostname@:@port@"
    type: url
  Support:
    value: "+1 (555) 123-4567"
    type: phone
```

### Top-level fields

| Field         | Description                                                                                                                                   |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `image`       | **Required.** Container image reference (e.g. `nginx:1.26-alpine`). Short names are normalized to `docker.io/library/<name>:latest`.         |
| `description` | Short human-readable summary of the package.                                                                                                  |
| `supplies`    | List of semantic capability tags this package provides (e.g. `["database"]`, `["http"]`, `["cache", "database"]`).                            |
| `command`     | Optional command override for the container.                                                                                                  |
| `environment` | Environment variables passed to the container. Values may contain `@variable@` template markers that are substituted with question responses. |
| `network`     | Port mapping configuration (see below).                                                                                                       |
| `volumes`     | Named volumes with mount configuration (see below).                                                                                           |
| `questions`   | Interactive prompts shown during installation (see below).                                                                                    |
| `archives`    | List of archive extraction specs to pre-populate volumes from container images (see below).                                                   |
| `notes`       | Key-value metadata displayed after installation. Supports template substitution and optional type validation (see below).                     |

### Supplies tags

The `supplies` field declares what capabilities a package provides. This enables dependency resolution and filtering. Common tags:

| Tag          | Used for                                      | Examples                              |
| ------------ | --------------------------------------------- | ------------------------------------- |
| `http`       | Web servers, CMS platforms, web applications  | nginx, wordpress, gitea               |
| `database`   | Relational and NoSQL databases                | postgres, mysql, mongo, redis         |
| `cache`      | Caching and key-value stores                  | redis, memcached, valkey              |
| `search`     | Search and analytics engines                  | elasticsearch, opensearch, solr       |
| `messaging`  | Message brokers and queues                    | rabbitmq, nats, kafka, mosquitto      |
| `monitoring` | Metrics, alerting, and visualization          | prometheus, grafana, telegraf         |
| `storage`    | Object storage and file hosting               | minio, registry, nextcloud            |

### Network

| Field              | Description                                                            |
| ------------------ | ---------------------------------------------------------------------- |
| `network.external` | Port mappings exposed to the host. Keys and values are `"port"` strings. Both may contain `@variable@` templates. |
| `network.internal` | Port mappings available only between containers on the internal network. |

Omit `external` or `internal` entirely if unused (do not use `{}`).

### Volumes

| Field        | Description                                                                    |
| ------------ | ------------------------------------------------------------------------------ |
| `mountpoint` | **Required.** Absolute path inside the container where the volume is mounted.  |
| `quota`      | Optional size limit (e.g. `512mb`, `2gb`, `1tb`). May use `@variable@` templates. |
| `archive`    | Optional archive filename to pre-populate the volume with.                     |
| `uid`        | Optional numeric user ID for volume ownership.                                 |
| `gid`        | Optional numeric group ID for volume ownership.                                |

Omit `volumes` entirely if the package has none (do not use `{}`).

### Archives

The `archives` field is a list of specs for extracting files from container images into volumes:

```yaml
archives:
  - image: nginx:latest
    directory: /usr/share/nginx/html
    volume: html
```

| Field       | Description                                                              |
| ----------- | ------------------------------------------------------------------------ |
| `image`     | **Required.** Container image to extract files from.                     |
| `directory` | **Required.** Absolute path in the container image to extract.           |
| `volume`    | **Required.** Name of a volume defined in this package to extract into.  |

### Questions

Questions define interactive prompts shown during package installation. User responses replace `@name@` template markers throughout the package definition.

```yaml
questions:
  port:
    query: "What external port should nginx listen on?"
    type: port
    default: "8080"
```

| Field     | Description                                                        |
| --------- | ------------------------------------------------------------------ |
| `query`   | **Required.** The prompt text shown to the user.                   |
| `type`    | Optional validation type (see table below). Omit for free-form text. |
| `default` | Optional default value suggested to the user.                      |

#### Question types

| Type       | Validates                                                  |
| ---------- | ---------------------------------------------------------- |
| `hostname` | Lowercase alphanumeric with hyphens (no dots)              |
| `port`     | Integer 1-65535                                            |
| `bytes`    | Human-readable size (e.g. `512mb`, `2gb`, `1tb`)           |
| `volume`   | Alphanumeric with hyphens and underscores                  |
| `archive`  | Any non-empty string (archive filename)                    |
| `duration` | Human-readable duration (e.g. `30s`, `5m`, `2h`, `1d`)    |
| _(omitted)_ | Any string (no validation)                                |

Do not use empty `type:` or `type: string` -- simply omit the `type` field for untyped questions.

### Notes

Notes provide key-value metadata displayed after installation. Each note has a `value` and an optional `type` for validation.

```yaml
notes:
  URL:
    value: "http://localhost:@port@"
    type: url
  Info:
    value: "Default admin credentials are admin/admin"
```

| Field   | Description                                                                |
| ------- | -------------------------------------------------------------------------- |
| `value` | **Required.** The note text. Supports `@variable@` template substitution. |
| `type`  | Optional validation type (see table below). Omit for plain text.           |

#### Note types

| Type    | Validates                                                           |
| ------- | ------------------------------------------------------------------- |
| `url`   | Valid URL                                                           |
| `phone` | Phone number (digits, spaces, parentheses, dashes, optional leading `+`) |
| `email` | Email address (`user@domain.tld`)                                   |
| _(omitted)_ | No validation (plain text)                                     |

### Template system

Template variables use the `@variable@` syntax and are substituted during compilation. They can appear in:

- Environment variable values
- Network port mappings (both keys and values)
- Volume mountpoints, quotas, and archive fields
- Note values

Two built-in template variables are available without questions:

| Variable                | Description                                |
| ----------------------- | ------------------------------------------ |
| `@LOCAL_EXTERNAL_HOST@` | The external hostname of the Town OS host  |
| `@LOCAL_INTERNAL_HOST@` | The internal hostname of the Town OS host  |

### Style guidelines

When writing package definitions:

- Omit empty maps (`environment: {}`, `internal: {}`, `volumes: {}`) -- leave them out entirely.
- Omit `type` on questions that accept free-form text -- do not write `type:` with no value.
- Include `description` with a short summary of what the package is.
- Include `supplies` with relevant capability tags when the package provides a well-known service.
- Include `notes` with connection URLs and any important post-install information.

## Adding this repository

This repository is included by default on every Town OS installation. If it was removed and you need to re-add it, there are two ways to do so.

### Through the UI

1. Log in to your Town OS instance.
2. Navigate to **Packages** from the sidebar.
3. Switch to the **Repositories** tab.
4. Click the **Add Repository** button.
5. Enter a name (e.g. `default`) and the repository URL: `https://github.com/town-os/default-packages`
6. Click **Add**.
7. Click **Refresh** to pull the latest packages.

### By editing repositories.json

Town OS stores its repository list in a `repositories.json` file inside its package data directory -- this is automatically created at first boot with this repository, but if it exists in advance you can pre-program it with your own fork of this that's private to you. You can add this repository by editing that file directly. This file exists in the btrfs filesystem TownOS depends on.

The order is important -- packages in earlier members of the list are less important than later ones, allowing you to create your own repositories of packages.

The file contains a JSON array of `[name, url]` pairs. Add an entry like this:

```json
[
    ["default", "https://github.com/town-os/default-packages"]
]
```

After editing the file, restart Town OS or use the **Refresh** button on the Repositories tab for the changes to take effect.

If the repository is private, embed credentials in the URL or use the `TOWN_OS_REPO_USERNAME` and `TOWN_OS_REPO_PASSWORD` environment variables:

```json
[
    ["default", "https://user:token@github.com/town-os/default-packages"]
]
```

## Trust model

Packages in this repository are maintained by the Town OS project. They are reviewed before inclusion and are expected to:

- Use well-known, official container images
- Accurately describe their behavior in questions and notes
- Declare only the network ports and volumes they actually need
- Contain no unexpected or malicious behavior

Users can trust that packages from this repository do what they say they do. Third-party repositories added by users do not carry this guarantee.

## Contributing

To propose a new package or update an existing one, open a pull request with the package YAML file placed under `packages/<name>/<version>.yaml`. See existing packages for examples of the expected format and follow the style guidelines above.

## License

BSD-3-Clause -- see [LICENSE](LICENSE) for details.
