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
    16.0.yaml
```

## Package format

Package definitions are YAML files with the following fields:

```yaml
image: nginx:1.26-alpine
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
questions:
    hostname:
        query: "What hostname should nginx serve?"
        type: hostname
    port:
        query: "What external port should nginx listen on?"
        type: port
notes:
    URL: "http://@hostname@:@port@"
```

| Field              | Description                                                                                                                                   |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `image`            | Container image reference (e.g. `nginx:1.26-alpine`)                                                                                          |
| `command`          | Optional command override for the container                                                                                                   |
| `environment`      | Environment variables passed to the container. Values may contain `@variable@` template markers that are substituted with question responses. |
| `network.external` | Port mappings exposed to the host (`host:container`)                                                                                          |
| `network.internal` | Port mappings available only between containers                                                                                               |
| `volumes`          | Named volumes with a `mountpoint` and optional `quota` (e.g. `2gb`)                                                                           |
| `questions`        | Interactive prompts shown during installation. Responses replace `@name@` markers.                                                            |
| `notes`            | Key-value metadata displayed after installation. Supports template substitution.                                                              |

### Question types

| Type       | Validates                                        |
| ---------- | ------------------------------------------------ |
| `hostname` | Lowercase alphanumeric with hyphens              |
| `port`     | Integer 1-65535                                  |
| `bytes`    | Human-readable size (e.g. `512mb`, `2gb`, `1tb`) |
| `volume`   | Alphanumeric with hyphens and underscores        |
| _(empty)_  | Any string                                       |

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

To propose a new package or update an existing one, open a pull request with the package YAML file placed under `packages/<name>/<version>.yaml`. See existing packages for examples of the expected format.

## License

BSD-3-Clause -- see [LICENSE](LICENSE) for details.
