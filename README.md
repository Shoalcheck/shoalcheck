# Shoalcheck — releases

Shoalcheck reads a Kubernetes cluster read-only from your machine and tells you what stops the next change —
a node that cannot be drained, workloads with nowhere to go if a zone fails, what blocks the next upgrade. With a
licence, a reading is a report in which every figure carries what it rests on.

This repository holds **releases only**; the landing page is [shoalcheck.github.io](https://shoalcheck.github.io). Download the archive for your platform from
[the latest release](../../releases/latest):

| | Command line | Desktop app |
|---|---|---|
| macOS | `shoalcheck_<v>_darwin_<arch>.tar.gz` | `Shoalcheck_<v>_macos_universal.dmg` |
| Windows | `shoalcheck_<v>_windows_<arch>.zip` | `shoalcheck-app_<v>_windows_<arch>.zip` |
| Linux | `shoalcheck_<v>_linux_<arch>.tar.gz` | `shoalcheck-app_<v>_linux_<arch>.tar.gz` |

Also: `kubectl-shoalcheck_<v>_<os>_<arch>` (a kubectl plugin) and `shoalcheck-mcp_<v>_<os>_<arch>` (an MCP
server for an assistant). Homebrew, from the first stable release: `brew install shoalcheck/tap/shoalcheck`.

```
shoalcheck audit --show-permissions        # exactly what access it needs, before it connects
shoalcheck preflight drain node-1          # exit 0 nothing stops it · 2 something does · 1 partial
shoalcheck audit --context prod            # the size of the reading and its five most serious kinds, free
shoalcheck licence plans                   # what a licence adds; keys are not on sale yet
```

**Verify what you downloaded.** Every release publishes `checksums.txt` and its signature bundle
`checksums.txt.sigstore.json`, signed with the key whose public half is [`cosign.pub`](cosign.pub) in this
repository:

```
cosign verify-blob --key cosign.pub --bundle checksums.txt.sigstore.json checksums.txt
shasum -a 256 --ignore-missing -c checksums.txt
```

cosign publishes no Windows arm64 build; on Windows on Arm its x64 build (`cosign-windows-amd64.exe`) runs under
the system's emulation, and that is what release-smoke checks there.

The first releases are not notarized by Apple or code-signed for Windows yet. On macOS, when the app is stopped the
first time, open System Settings → Privacy & Security and choose Open Anyway, or remove the quarantine flag
yourself: `xattr -dr com.apple.quarantine /Applications/Shoalcheck.app`. On Windows, SmartScreen asks once
(More info → Run anyway).

There is no support desk. `shoalcheck support`, or Settings → Diagnostics in the app, writes a file that describes
an install and a reading without naming anything in the cluster.
