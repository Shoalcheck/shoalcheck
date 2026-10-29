# Shoalcheck — releases

Newest release: [v0.1.4](../../releases/tag/v0.1.4), 2026-10-29.

Shoalcheck reads a Kubernetes cluster read-only from your machine and tells you what stops the next change —
a node that cannot be drained, workloads with nowhere to go if a zone fails, what blocks the next upgrade. With a
licence, a reading is a report in which every figure carries what it rests on.

See it work: [a 74-second walkthrough](https://youtu.be/eyYNvSTE65E), filmed on the real product — the app, a
Jira ticket, a pull request gated in CI and Claude Code over MCP.

This repository holds **releases only**; the landing page is [shoalcheck.com](https://shoalcheck.com). Download the archive for your platform from
[the latest release](../../releases/latest); `shoalcheck version` names the one you have and
`shoalcheck upgrade --check` says whether there is a newer one:

| | Command line | Desktop app |
|---|---|---|
| macOS | `shoalcheck_<v>_darwin_<arch>.tar.gz` | `Shoalcheck_<v>_macos_universal.dmg` |
| Windows | `shoalcheck_<v>_windows_<arch>.zip` | `Shoalcheck_<v>_windows_<arch>_setup.exe`, or `shoalcheck-app_<v>_windows_<arch>.zip` |
| Linux | `shoalcheck_<v>_linux_<arch>.tar.gz` | `shoalcheck-app_<v>_linux_<arch>.tar.gz` |

The Windows installer is per user (no administrator): the app, `shoalcheck` and `kubectl-shoalcheck`, a Start menu
entry, the command line on your PATH, and an entry in Apps & features; `/S` installs silently. On Windows the app is
a native window (WebView2); on Linux it is an app window of Chrome, Chromium, Brave or Edge if one is installed, and
`install-desktop-entry.sh` in its archive adds it to the application menu. Without either, it opens in your browser
and says so.

Also: `kubectl-shoalcheck_<v>_<os>_<arch>` (a kubectl plugin) and `shoalcheck-mcp_<v>_<os>_<arch>` (an MCP
server for an assistant). Homebrew (macOS and Linux, the command line): `brew install shoalcheck/tap/shoalcheck`.

```
shoalcheck audit --show-permissions        # exactly what access it needs, before it connects
shoalcheck preflight drain node-1          # exit 0 nothing stops it · 2 something does · 1 partial
shoalcheck audit --context prod            # the size of the reading and its five most serious kinds, free
shoalcheck licence plans                   # what a licence adds; keys are sold at https://shop.shoalcheck.com/buy
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

From 0.1.0-rc.12 the macOS app and the macOS command-line binaries are signed with a Developer ID and checked by
Apple's notary service. Earlier releases are not, and no release is code-signed for Windows yet, so check the download first (above).
On macOS with an earlier release, when the app is stopped the first time, open System Settings → Privacy & Security
and choose Open Anyway. On Windows, SmartScreen asks once (More info → Run anyway).

There is no support desk. `shoalcheck support`, or Settings → Diagnostics in the app, writes a file that describes
an install and a reading without naming anything in the cluster.
