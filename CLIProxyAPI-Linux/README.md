# CLIProxyAPI-Linux

One-command Linux installer bundle for:

- `router-for-me/CLIProxyAPI`
- `AllenReder/CLIProxyAPI-Quota-Inspector`

It installs into the current user account, so it works well on:

- Ubuntu WSL
- Ubuntu VPS
- most standard Linux shells with `curl`, `tar`, `python3`, and `openssl`

## Install

From a local checkout:

```bash
bash install.sh
```

From GitHub raw after you publish this folder:

```bash
curl -fsSL https://raw.githubusercontent.com/daotaolaixe-quangthang/CLIProxyAPI/<branch>/CLIProxyAPI-Linux/install.sh | bash
```

If you publish this folder on `main`, the direct command becomes:

```bash
curl -fsSL https://raw.githubusercontent.com/daotaolaixe-quangthang/CLIProxyAPI/main/CLIProxyAPI-Linux/install.sh | bash
```

## What it installs

- `cliproxyapi`
- `cliproxyapi-start`
- `cliproxyapi-codex-login`
- `cliproxyapi-claude-login`
- `cliproxyapi-antigravity-login`
- `cliproxyapi-gemini-login`
- `cpaq`
- `cliproxyapi-service-install`
- `cliproxyapi-service-uninstall`
- `cliproxyapi-service-start`
- `cliproxyapi-service-stop`
- `cliproxyapi-service-restart`
- `cliproxyapi-service-status`
- `cliproxyapi-service-logs`

Installed files:

- app binaries: `~/.local/share/cliproxyapi/app`
- config template: `~/.local/share/cliproxyapi/app/config.yaml`
- oauth/auth files: `~/.cli-proxy-api`
- shell commands: `~/.local/bin`

## Defaults

- API bind: `127.0.0.1:8318`
- API key: `sk-my-secret-key`
- management key: auto-generated into `~/.cli-proxy-api/management.key`
- auth dir: `~/.cli-proxy-api`

## Common usage

Start server:

```bash
cliproxyapi-start
```

OAuth login:

```bash
cliproxyapi-codex-login
cliproxyapi-claude-login
cliproxyapi-antigravity-login
cliproxyapi-gemini-login
```

Check models:

```bash
curl http://127.0.0.1:8318/v1/models \
  -H 'Authorization: Bearer sk-my-secret-key'
```

Check quota:

```bash
cpaq
```

Enable background service with `systemd --user`:

```bash
cliproxyapi-service-install
cliproxyapi-service-status
cliproxyapi-service-logs
```

Manual service controls:

```bash
cliproxyapi-service-uninstall
cliproxyapi-service-start
cliproxyapi-service-stop
cliproxyapi-service-restart
cliproxyapi-service-status
cliproxyapi-service-logs
```

## Service Commands

These commands are created by `install.sh` in `~/.local/bin`.

`cliproxyapi-service-install`

- Reloads `systemd --user`
- Enables the service
- Starts the service immediately
- Best command to run the first time after installation

```bash
cliproxyapi-service-install
```

`cliproxyapi-service-uninstall`

- Stops the user service
- Disables auto-start for the user service
- Keeps the installed binaries and config files
- Useful when you want to stop using the background service but keep the app installed

```bash
cliproxyapi-service-uninstall
```

`cliproxyapi-service-start`

- Starts the background service now
- Does not change whether the service is enabled on login unless it was already enabled

```bash
cliproxyapi-service-start
```

`cliproxyapi-service-stop`

- Stops the running background service

```bash
cliproxyapi-service-stop
```

`cliproxyapi-service-restart`

- Restarts the service
- Use this after editing `config.yaml` or after OAuth/account file changes when you want a clean reload

```bash
cliproxyapi-service-restart
```

`cliproxyapi-service-status`

- Shows current service status
- Good for checking whether the process is active, failed, or restarting

```bash
cliproxyapi-service-status
```

`cliproxyapi-service-logs`

- Follows service logs from `journalctl --user`
- Best command for debugging startup issues, config mistakes, or OAuth runtime errors

```bash
cliproxyapi-service-logs
```

## Service Workflow

Typical first-time setup:

```bash
curl -fsSL https://raw.githubusercontent.com/daotaolaixe-quangthang/CLIProxyAPI/main/CLIProxyAPI-Linux/install.sh | bash
cliproxyapi-service-install
cliproxyapi-service-status
```

After editing config:

```bash
cliproxyapi-service-restart
cliproxyapi-service-status
```

When debugging:

```bash
cliproxyapi-service-logs
```

When you want to stop background mode temporarily:

```bash
cliproxyapi-service-stop
```

When you want to remove only the service integration:

```bash
cliproxyapi-service-uninstall
```

When you want to run foreground mode manually instead of `systemd`:

```bash
cliproxyapi-start
```

If you are on WSL and `systemd` is not enabled yet, add this to `/etc/wsl.conf` and restart WSL:

```ini
[boot]
systemd=true
```

Then run:

```powershell
wsl --shutdown
```

## WSL Systemd

Use this section when you install on `Windows 11 + WSL Ubuntu` and want `CLIProxyAPI` to run in the background through `systemd --user`.

1. Check whether `systemd` is already active inside WSL:

```bash
ps -p 1 -o comm=
systemctl --user is-system-running
```

If the first command prints `systemd`, you can skip the enable steps below.

2. Enable `systemd` for WSL by editing `/etc/wsl.conf`:

```bash
sudo nano /etc/wsl.conf
```

Put this content in the file:

```ini
[boot]
systemd=true
```

3. From Windows PowerShell, fully restart WSL:

```powershell
wsl --shutdown
```

4. Open Ubuntu again and verify:

```bash
ps -p 1 -o comm=
systemctl --user --version
systemctl --user is-system-running
```

5. After running the installer, enable the background service:

```bash
cliproxyapi-service-install
cliproxyapi-service-status
```

6. View logs any time:

```bash
cliproxyapi-service-logs
```

Useful notes:

- `cliproxyapi-service-install` runs `systemctl --user enable --now cliproxyapi.service`
- `cliproxyapi-service-uninstall` stops and disables the user service only
- the service file is created at `~/.config/systemd/user/cliproxyapi.service`
- if `systemctl --user` says the user bus is unavailable, close the WSL shell, run `wsl --shutdown`, and open Ubuntu again
- on older WSL setups without `systemd`, you can still run `cliproxyapi-start` manually without using the service commands

## Uninstall

Remove installed binaries, wrappers, and the user service:

```bash
bash uninstall.sh
```

Also remove OAuth/config data under `~/.cli-proxy-api`:

```bash
CLIPROXYAPI_PURGE_CONFIG=1 bash uninstall.sh
```

## Environment overrides

You can override install defaults at install time:

```bash
CLIPROXYAPI_PORT=8319 \
CLIPROXYAPI_API_KEY='sk-demo-key' \
CLIPROXYAPI_FORCE_CONFIG=1 \
bash install.sh
```

Supported variables:

- `CLIPROXYAPI_INSTALL_ROOT`
- `CLIPROXYAPI_BIN_DIR`
- `CLIPROXYAPI_CONFIG_DIR`
- `CLIPROXYAPI_APP_CONFIG_PATH`
- `CLIPROXYAPI_PORT`
- `CLIPROXYAPI_API_KEY`
- `CLIPROXYAPI_MANAGEMENT_KEY`
- `CLIPROXYAPI_FORCE_CONFIG`
- `CPAQ_BASE_URL`
- `CPAQ_MANAGEMENT_KEY_FILE`
- `CPAQ_CONFIG_PATH`
- `CLIPROXYAPI_PURGE_CONFIG`
