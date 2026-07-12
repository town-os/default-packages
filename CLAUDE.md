# Working in this repository

This repository holds Town OS package definitions: `packages/<name>/<version>.yaml`. The package format itself is documented in [README.md](README.md) -- read it before adding or changing a package.

## The info panel is for data, not instructions

The `notes` block is rendered as the package's info panel after install. It is a **key-value data panel**, not a place to write English.

A note value must be a piece of data the user needs to have: a URL, a hostname, a port, a token, a password, a username, a connection string.

```yaml
notes:
  URL:
    value: "https://@PACKAGE_DNS@/"
    type: url
  Admin token:
    value: "@admintoken@"
```

Never put instructions, prose, guidance, caveats, or explanations in a note value. No "open this and click X", no "set this to false once you have accounts", no "back this volume up", no sentences at all. If the user has to *read* it rather than *copy* it, it does not belong there.

The same goes for a question's `query`: it names the value being asked for. It is not a place for advice, so keep parenthetical instructions ("(set to false later)", "(generated)") out of it.

Explanation belongs in YAML comments, which are addressed to whoever edits the package next -- not to the person installing it. Put the reasoning, the failure modes, and the upstream quirks there, and be thorough about it.

## Versioning

Packages are versioned by filename and published versions are immutable: never edit a released `<version>.yaml` in place to change behavior. Add a new version file instead (`1.0.yaml` -> `1.1.yaml`), leaving the old one alone.

## Verify before claiming

These packages are run by people who trust them with their data. Before saying a package works, actually run it -- `podman run` the image with the same environment, ports, and volumes the package compiles to, and probe the endpoints. Do not assert behavior from an upstream README alone; upstream docs are frequently stale about image names, ports, and defaults.
