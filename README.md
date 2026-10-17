# Shoalcheck — releases

Shoalcheck reads a Kubernetes cluster read-only from your machine and tells you what stops the next change —
a node that cannot be drained, workloads with nowhere to go if a zone fails, what blocks the next upgrade — and
writes one signed report in which every figure carries what it rests on.

This repository holds **releases only**. Download the archive for your platform from
[the latest release](../../releases/latest):

| | Command line | Desktop app |
|---|---|---|
| macOS | `shoalcheck_<v>_darwin_<arch>.tar.gz` | `Shoalcheck_<v>_macos_universal.dmg` |
| Windows | `shoalcheck_<v>_windows_<arch>.zip` | `shoalcheck-app_<v>_windows_<arch>.zip` |
| Linux | `shoalcheck_<v>_linux_<arch>.tar.gz` | `shoalcheck-app_<v>_linux_<arch>.tar.gz` |

Also: `kubectl-shoalcheck_<v>_<os>_<arch>` (a kubectl plugin) and `shoalcheck-mcp_<v>_<os>_<arch>` (an MCP
server for an assistant). Homebrew, from the first stable release: `brew install ilya776/tap/shoalcheck`.

```
shoalcheck audit --show-permissions        # exactly what access it needs, before it connects
shoalcheck preflight drain node-1          # exit 0 nothing stops it · 2 something does · 1 partial
shoalcheck audit --context prod            # the opening and the top five problems, free
shoalcheck licence plans                   # what a licence adds
```

**Verify what you downloaded.** Every release publishes `checksums.txt` and its signature bundle
`checksums.txt.sigstore.json`, signed with the key whose public half is [`cosign.pub`](cosign.pub) in this
repository:

```
cosign verify-blob --key cosign.pub --bundle checksums.txt.sigstore.json checksums.txt
shasum -a 256 --ignore-missing -c checksums.txt
```

The first releases are not notarized by Apple or code-signed for Windows yet: on macOS Control-click the app
and choose Open the first time; on Windows, SmartScreen asks once (More info → Run anyway).
