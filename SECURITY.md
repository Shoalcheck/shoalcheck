# Security policy

## Reporting a vulnerability

Report it privately, through GitHub's private vulnerability reporting on this repository:
https://github.com/Shoalcheck/shoalcheck/security/advisories/new — please do not open a public issue.
If you cannot use GitHub, e-mail security@shoalcheck.com instead.
There is no support desk and no response time is promised, but every report is read.

Most worth reporting, in order:

1. A path by which Shoalcheck writes to a cluster. It asks with `get` and `list` only.
2. A read outside the published role (`deploy/rbac.yaml` in the `shoalcheck` archive), such as a Secret, a
   ConfigMap's data or a pod's logs.
3. Anything about a cluster leaving the machine without being asked to. The one request a default build makes
   to anything but the cluster is the update check, to GitHub.
4. An identifier that survives `--redact`.
5. A release artifact that verifies but is not what was signed, or an update the desktop app or
   `shoalcheck upgrade` installs without its signature checking out.

## Checking a release

Every release carries `checksums.txt` and its cosign signature bundle. Take `cosign.pub` from this repository,
not from the release it vouches for:

    cosign verify-blob --key cosign.pub --bundle checksums.txt.sigstore.json checksums.txt
    shasum -a 256 --ignore-missing -c checksums.txt
