# Default Town OS Package Repository

> **[Town OS](https://town-os.github.io): Your Cloud in Your Closet, easy enough for anyone.**
>
> **Home: [https://town-os.github.io](https://town-os.github.io)**

The official default package repository for [Town OS](https://town-os.github.io). This repository is included automatically on every Town OS installation.

**NOTE:** These packages are currently experimental. Many were generated using Claude and need testing and pull requests. Some packages -- such as gitea, plex, nginx, and many databases -- already work well, but others may not. They are safe to launch, but should not be relied on for production use yet. Send pull requests if you want to shape them up! At a later point, packages in this repository will be expected to be trustworthy, well-tested, and behave as described.

## Table of contents

- [Repository structure](#repository-structure)
  - [Featured packages](#featured-packages)
- [Package format](#package-format)
  - [Top-level fields](#top-level-fields)
  - [Image field](#image-field)
  - [VM packages](#vm-packages)
  - [Proton packages](#proton-packages)
  - [Supplies tags](#supplies-tags)
  - [Network](#network)
  - [Volumes](#volumes)
  - [Archives](#archives)
  - [Git sources](#git-sources)
  - [Questions](#questions)
  - [Notes](#notes)
  - [File templates](#file-templates)
  - [Template system](#template-system)
  - [Style guidelines](#style-guidelines)
- [Adding this repository](#adding-this-repository)
  - [Through the UI](#through-the-ui)
  - [By editing repositories.json](#by-editing-repositoriesjson)
- [Trust model](#trust-model)
- [Contributing](#contributing)
- [License](#license)

## Repository structure

```
featured.json
packages/
  <package-name>/
    <version>.yaml
```

Each package is a directory under `packages/` containing one or more versioned YAML files. The optional `featured.json` at the repository root lists packages to highlight in the UI.

For example:

```
featured.json
packages/
  nginx/
    1.0.yaml
    2.0.yaml
  postgres/
    1.0.yaml
```

### Featured packages

A repository can include a `featured.json` file at its root to highlight selected packages. The file contains a JSON array of package name strings:

```json
["wordpress", "nextcloud", "postgres"]
```

Packages listed here appear with `featured: true` in the API's package list response, allowing the UI to surface them prominently. The file is optional -- if absent, no packages are featured.

## Package format

Package definitions are YAML files with the following fields:

```yaml
image: nginx
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
  site:
    mountpoint: /srv/site
    git: https://github.com/example/my-site.git
questions:
  hostname:
    query: "What hostname should nginx serve?"
    type: hostname
  port:
    query: "What external port should nginx listen on?"
    type: port
    default: "8080"
archives:
  - image: nginx
    directory: /usr/share/nginx/html
    volume: html
git_sources:
  - url: https://github.com/example/config.git
    branch: main
    volume: config
templates:
  nginx-conf:
    volume: html
    path: default.conf
    content: |
      server {
          listen 80;
          server_name {{.Responses.hostname}};
          root /usr/share/nginx/html;
      }
notes:
  URL:
    value: "http://@hostname@:@port@"
    type: url
  Support:
    value: "+1 (555) 123-4567"
    type: phone
```

### Top-level fields

A package must specify exactly one runtime: `image` (container), `vm` (virtual machine), or `proton` (Windows app). Specifying more than one or none is a validation error.

| Field         | Description                                                                                                                                   |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `image`       | Container image reference (e.g. `nginx`, `nginx:1.26-alpine`). See [Image field](#image-field) for details.                                  |
| `vm`          | Virtual machine configuration. Mutually exclusive with `image` and `proton`. See [VM packages](#vm-packages).                                |
| `proton`      | Windows application configuration via Valve's Proton. Mutually exclusive with `image` and `vm`. See [Proton packages](#proton-packages).     |
| `description` | Short human-readable summary of the package.                                                                                                  |
| `supplies`    | List of semantic capability tags this package provides (e.g. `["database"]`, `["http"]`, `["cache", "database"]`).                            |
| `command`     | Optional command override for the container (container runtime only).                                                                         |
| `environment` | Environment variables passed to the container (container runtime only). Values may contain `@variable@` template markers that are substituted with question responses. |
| `network`     | Port mapping configuration (see below).                                                                                                       |
| `volumes`     | Named volumes with mount configuration (see below).                                                                                           |
| `questions`   | Interactive prompts shown during installation (see below).                                                                                    |
| `archives`    | List of archive extraction specs to pre-populate volumes from container images (container runtime only, see below).                           |
| `git_sources` | List of Git repositories to clone into volumes during installation (see below).                                                               |
| `templates`   | Named file templates rendered into volumes using Go `text/template` syntax (see below).                                                      |
| `notes`       | Key-value metadata displayed after installation. Supports template substitution and optional type validation (see below).                     |

### Image field

The `image` field specifies the container image for the package. It accepts two forms:

**Plain string (preferred):**

```yaml
image: nginx
```

**Structured form:**

```yaml
image:
  type: oci
  url: nginx
```

| Field  | Description                                                                 |
| ------ | --------------------------------------------------------------------------- |
| `type` | Image type. Currently only `oci` is supported. Defaults to `oci` if omitted. |
| `url`  | Image reference (same format as the plain string form).                      |

When a plain string is used, it is treated as an OCI image reference. Both forms are equivalent.

#### Image normalization

Image references are automatically normalized during compilation:

- `nginx` becomes `docker.io/library/nginx:latest`
- `user/app` becomes `docker.io/user/app:latest`
- `ghcr.io/org/app` becomes `ghcr.io/org/app:latest` (if no tag)
- `nginx:1.26-alpine` is preserved as-is (tag already present)

Because `:latest` is appended automatically to tagless references, prefer omitting it in package definitions. Write `image: nginx` rather than `image: nginx:latest`.

### VM packages

VM packages run a virtual machine using QEMU instead of a container. The `vm` field is mutually exclusive with `image` and `proton`.

```yaml
vm:
  image: https://example.com/ubuntu-22.04.qcow2
  memory: 2gb
  cpus: 2
description: Ubuntu 22.04 virtual machine
network:
  external:
    "2222": "22"
```

| Field    | Description                                                                                                        |
| -------- | ------------------------------------------------------------------------------------------------------------------ |
| `image`  | **Required.** VM disk image URL or local filename. Supports HTTP/HTTPS URLs and `@variable@` template substitution. |
| `memory` | VM memory as a human-readable byte string (e.g. `2gb`, `512mb`). Defaults to `1gb`. Supports `@variable@` templates. |
| `cpus`   | Number of virtual CPUs. Defaults to `1`.                                                                            |

Remote disk images are downloaded and converted to raw format via `qemu-img`. VMs run with KVM acceleration, virtio disk and network, and user-mode networking with port forwarding.

The `command`, `environment`, and `archives` fields are not applicable to VM packages.

### Proton packages

Proton packages run Windows applications using Valve's Proton compatibility layer. The `proton` field is mutually exclusive with `image` and `vm`.

```yaml
proton:
  app_image: myapp-container
  app_directory: /opt/myapp
  volume: appdata
  exe: MyApp.exe
  args: ["-fullscreen", "-config", "settings.ini"]
description: Windows application running via Proton
volumes:
  appdata:
    mountpoint: /data
```

| Field           | Description                                                              |
| --------------- | ------------------------------------------------------------------------ |
| `app_image`     | **Required.** Container image containing the application files.          |
| `app_directory` | **Required.** Path within the container image where application files are located. |
| `volume`        | **Required.** Name of a volume defined in this package for application data. |
| `exe`           | **Required.** Windows executable filename to run.                        |
| `args`          | Optional list of command-line arguments passed to the executable.        |

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
| `git`        | Optional Git repository URL to clone into the volume during installation (e.g. `https://github.com/user/repo.git`). Supported schemes: `http`, `https`, `ssh`, `git`, `file`. |
| `uid`        | Optional numeric user ID for volume ownership.                                 |
| `gid`        | Optional numeric group ID for volume ownership.                                |

Omit `volumes` entirely if the package has none (do not use `{}`).

### Archives

The `archives` field is a list of specs for extracting files from container images into volumes:

```yaml
archives:
  - image: nginx
    directory: /usr/share/nginx/html
    volume: html
```

| Field       | Description                                                              |
| ----------- | ------------------------------------------------------------------------ |
| `image`     | **Required.** Container image to extract files from.                     |
| `directory` | **Required.** Absolute path in the container image to extract.           |
| `volume`    | **Required.** Name of a volume defined in this package to extract into.  |

### Git sources

The `git_sources` field is a list of Git repositories to clone into volumes during installation. Unlike the per-volume `git` field, `git_sources` supports branch selection and can be rebuilt via the API.

```yaml
git_sources:
  - url: https://github.com/example/config.git
    branch: main
    volume: config
  - url: https://github.com/example/plugins.git
    branch: stable
    volume: plugins
```

| Field    | Description                                                                            |
| -------- | -------------------------------------------------------------------------------------- |
| `url`    | **Required.** Git repository URL to clone. Supports `@variable@` template substitution. |
| `branch` | Git branch to checkout. Supports `@variable@` template substitution.                   |
| `volume` | **Required.** Name of a volume defined in this package to clone into.                  |

The `POST /packages/rebuild-git` API endpoint pulls latest changes for each git-sourced volume and restarts the dependent service.

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

| Type       | Validates                                                  | Auto-generation                                              |
| ---------- | ---------------------------------------------------------- | ------------------------------------------------------------ |
| `hostname` | Lowercase alphanumeric with hyphens (no dots)              | `<package-name>-<4-char-hex>` (e.g. `nginx-a3f2`)           |
| `port`     | Integer 1-65535                                            | Random available port in range 10000-60000                   |
| `bytes`    | Human-readable size (e.g. `512mb`, `2gb`, `1tb`)           |                                                              |
| `volume`   | Alphanumeric with hyphens and underscores                  |                                                              |
| `archive`  | Any non-empty string (archive filename)                    |                                                              |
| `duration` | Human-readable duration (e.g. `30s`, `5m`, `2h`, `1d`)    |                                                              |
| `secret`   | Any non-empty string                                       | 256-bit hex string via `crypto/rand` (64 hex characters)     |
| _(omitted)_ | Any string (no validation)                                |                                                              |

Auto-generation is triggered when the user provides an empty response or `"auto"`. For `secret` questions, values are always auto-generated if not explicitly provided, making them suitable for passwords and encryption keys. For `port` questions, the auto-generated port is verified to not conflict with other installed packages.

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

### File templates

The `templates` field defines named file templates that are rendered into volumes using Go `text/template` syntax. Templates are applied after volume seeding (archives, git clones) but before the service starts. During reconciliation, templates are re-rendered but existing files are never overwritten.

```yaml
templates:
  nginx-conf:
    volume: config
    path: nginx.conf
    content: |
      server {
          listen 80;
          server_name {{.Responses.hostname}};
          root /usr/share/nginx/html;
      }
  env-file:
    volume: config
    path: .env
    content: |
      APP_NAME={{.Package.Name}}
      APP_VERSION={{.Package.Version}}
      HOSTNAME={{.System.Hostname}}
```

| Field     | Description                                                                                      |
| --------- | ------------------------------------------------------------------------------------------------ |
| `volume`  | **Required.** Name of a volume defined in this package. Supports `@variable@` substitution.      |
| `path`    | **Required.** Relative file path within the volume. Must not contain directory traversal (`..`).  |
| `content` | **Required.** Go `text/template` string rendered with the template data context (see below).     |

Template names (the YAML keys) must be alphanumeric with dots, dashes, and underscores.

#### Template data context

Templates have access to three namespaces:

| Namespace    | Fields                                                             |
| ------------ | ------------------------------------------------------------------ |
| `.Responses` | Question responses keyed by name (e.g. `{{.Responses.hostname}}`) |
| `.Package`   | `Name`, `Version`, `Repo`, `Image`, `Description`                 |
| `.System`    | `Hostname`, `ExternalIP`, `InternalIP`                             |

### Dependencies

Packages can declare dependencies on other packages. Dependencies share the parent's podman network, allowing direct communication by container name via podman's built-in DNS.

```yaml
dependencies:
  db:
    package: postgres
    responses:
      password: "@dbpass@"
      user: "mattermost"
      database: "mattermost"
      port: "5432"
```

Each dependency entry has:

| Field       | Description                                                                                   |
| ----------- | --------------------------------------------------------------------------------------------- |
| `package`   | **Required.** Name of the dependency package.                                                 |
| `repo`      | Repository containing the dependency. Defaults to the parent's repository.                    |
| `version`   | Version to install. Defaults to the latest available version.                                 |
| `responses` | Question responses for the dependency. Values support `@variable@` syntax from parent questions. |

Parent packages receive environment variables for each dependency at runtime:

- `TOWNOS_DEP_{KEY}_HOST` -- the dependency's container name (resolvable via podman DNS).
- `TOWNOS_DEP_{KEY}_PORT_{port}` -- the container-side port number.

Parent packages can also use `@dep_KEY_host@` and `@dep_KEY_port_N@` template variables in their environment values (see [Template system](#template-system)).

### Template system

Template variables use the `@variable@` syntax and are substituted during compilation. They can appear in:

- Environment variable values
- Network port mappings (both keys and values)
- Volume mountpoints, quotas, archive fields, and git URLs
- Git source URLs and branches
- Template volume and path fields
- Note values

Built-in template variables are available without questions:

| Variable                | Description                                                                      |
| ----------------------- | -------------------------------------------------------------------------------- |
| `@LOCAL_EXTERNAL_HOST@` | The external hostname of the Town OS host                                        |
| `@LOCAL_INTERNAL_HOST@` | The internal hostname of the Town OS host                                        |
| `@dep_KEY_host@`        | Container hostname for dependency KEY (resolvable via podman DNS on shared network) |
| `@dep_KEY_port_N@`      | Container port N for dependency KEY                                              |

Dependency template variables (`@dep_*@`) are only available when the package declares dependencies. KEY is the lowercase dependency key name (e.g., `db` from `dependencies: db:`), and N is the container port number.

### Style guidelines

When writing package definitions:

- Prefer tagless images -- write `image: nginx` rather than `image: nginx:latest`, since `:latest` is appended automatically during normalization.
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
