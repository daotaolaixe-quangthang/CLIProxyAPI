# CLIProxyAPI - Hướng dẫn sử dụng và maintain cho bộ script Windows

Tài liệu này mô tả cách dùng bộ CLIProxyAPI trong thư mục `E:\CLIProxyAPI`, gồm proxy chính, TUI chọn account, dashboard quota, OAuth login và các helper đi kèm.

Mục tiêu của project này là chạy CLIProxyAPI trên Windows theo 2 chế độ:

- Full multi-account mode: dùng toàn bộ account trong `%USERPROFILE%\.cli-proxy-api`.
- Custom account mode: chọn một hoặc nhiều account cụ thể rồi chạy proxy qua TUI.

## 1. Cấu trúc thư mục

```text
E:\CLIProxyAPI
  start-single-account.bat              File TUI chính để chọn account, chạy server, xem quota, thêm OAuth account
  start-single-account-old.bat          Bản cũ để fallback khi cần
  show-quota-dashboard.bat              Dashboard quota độc lập
  show-codex-quota.bat                  Dashboard quota Codex độc lập

  CLIProxyAPI\
    cli-proxy-api.exe                   Binary chính của CLIProxyAPI
    start-proxy.bat                     Chạy full proxy với config mặc định
    login-codex.bat                     Login Codex OAuth độc lập
    login-gemini.bat                    Login Gemini CLI OAuth độc lập
    login-antigravity.bat               Login Antigravity OAuth độc lập
    login-grok.bat                      Login Grok / xAI OAuth độc lập
    oauth-clipboard.ps1                 Helper OAuth, tự copy URL vào clipboard
    get-local-version.ps1               Helper đọc version local của cli-proxy-api.exe
    schema-filter.js                    Reverse proxy lọc JSON Schema không tương thích
    config.example.yaml                 File config mẫu
    management.key.example              File management key mẫu
    README.md                           Tài liệu này

  CLIProxyAPI-Quota-Inspector\
    cpa-quota-inspector.exe             Binary xem quota live từ CLIProxyAPI
```

## 2. Các thư mục runtime trong user profile

Các script không dùng trực tiếp config trong folder project để chạy production. Runtime chính nằm trong user profile:

```text
%USERPROFILE%\.cli-proxy-api
  config.yaml                           Config chính của CLIProxyAPI
  management.key                        Key dùng cho quota inspector và management API
  *.json                                OAuth account files

%USERPROFILE%\.cli-proxy-api-single
  config-single.yaml                    Config tạm cho custom account mode
  *.json                                Account đã chọn cho phiên single/custom mode
  cli-proxy-api.pid                     PID do TUI lưu lại
  schema-filter.pid                     PID do TUI lưu lại
  *.log                                 Log stdout/stderr của process nền
```

Nguyên tắc quan trọng:

- `%USERPROFILE%\.cli-proxy-api` là thư mục gốc chứa account thật.
- `%USERPROFILE%\.cli-proxy-api-single` là thư mục tạm cho TUI custom mode.
- `start-single-account.bat` copy account được chọn sang thư mục tạm, không sửa file JSON gốc.

## 3. Port sử dụng

Custom account mode dùng 2 port cố định:

```text
8317    Claude Code / client gọi vào schema-filter.js
8318    CLIProxyAPI thật chạy phía sau
```

Luồng request:

```text
Client -> 127.0.0.1:8317 -> schema-filter.js -> 127.0.0.1:8318 -> cli-proxy-api.exe
```

`schema-filter.js` có nhiệm vụ xóa một số JSON Schema keyword không tương thích với Gemini, Antigravity hoặc provider tương tự, ví dụ `propertyNames`, `patternProperties`, `$schema`, `$id`, `$defs`.

## 4. Entry point nên dùng

### 4.1 Custom account mode - khuyến nghị dùng hằng ngày

Chạy:

```bat
E:\CLIProxyAPI\start-single-account.bat
```

File này làm các việc chính:

- Kiểm tra update mới từ GitHub release của `router-for-me/CLIProxyAPI`.
- Force-kill process đang chiếm port `8317` và `8318` khi khởi chạy, theo logic cũ của project.
- Cho chọn account OAuth từ `%USERPROFILE%\.cli-proxy-api`.
- Copy account đã chọn sang `%USERPROFILE%\.cli-proxy-api-single`.
- Tạo `config-single.yaml` từ config gốc, ép:
  - `auth-dir: "~/.cli-proxy-api-single"`
  - `port: 8318`
- Start `cli-proxy-api.exe` nền trên port `8318`.
- Start `schema-filter.js` nền trên port `8317`.
- Hiển thị TUI điều khiển server và quota dashboard.

Menu TUI khi server đang chạy:

```text
R    Reload server với account hiện tại
B    Tắt server và quay lại chọn account
A    Thêm account OAuth mới
S    Refresh quota thủ công
Q    Tắt server và thoát hoàn toàn
```

Auto refresh quota chạy mỗi 15 phút bằng `choice /t 900 /d S`.

### 4.2 Full multi-account mode

Chạy:

```bat
E:\CLIProxyAPI\CLIProxyAPI\start-proxy.bat
```

Chế độ này chạy trực tiếp:

```bat
cli-proxy-api.exe --config "%USERPROFILE%\.cli-proxy-api\config.yaml"
```

Dùng khi muốn chạy toàn bộ account trong config gốc, không cần TUI chọn account.

### 4.3 Quota dashboard độc lập

Chạy:

```bat
E:\CLIProxyAPI\show-quota-dashboard.bat
```

Chức năng:

- Xem quota tất cả provider.
- Lọc Codex, Gemini CLI, Antigravity, Grok / xAI.
- Xem summary only.
- Export JSON ra Desktop.

Script này cần server đang chạy tại:

```text
http://127.0.0.1:8317
```

và cần management key tại:

```text
%USERPROFILE%\.cli-proxy-api\management.key
```

### 4.4 Codex quota độc lập

Chạy:

```bat
E:\CLIProxyAPI\show-codex-quota.bat
```

Dùng khi chỉ muốn xem quota Codex nhanh.

## 5. OAuth login account

Có 2 cách thêm account OAuth.

### 5.1 Thêm account từ TUI chính

Trong `start-single-account.bat`, bấm `A`.

Submenu:

```text
1    Antigravity
2    Codex
3    Gemini CLI
4    Grok / xAI
B    Quay lại
```

Sau khi OAuth xong, script hiển thị kết quả và yêu cầu nhấn Enter để quay lại màn hình chọn account.

### 5.2 Thêm account bằng file login độc lập

Các file độc lập nằm trong `E:\CLIProxyAPI\CLIProxyAPI`:

```bat
login-antigravity.bat
login-codex.bat
login-gemini.bat
login-grok.bat
```

Dùng khi chỉ cần login nhanh mà không mở TUI chính.

## 6. Chi tiết OAuth helper

File:

```text
E:\CLIProxyAPI\CLIProxyAPI\oauth-clipboard.ps1
```

Chức năng:

- Chạy `cli-proxy-api.exe` với login flag tương ứng.
- Bắt URL OAuth trong output.
- Copy URL vào clipboard bằng `Set-Clipboard`.
- Hiển thị thông báo để người dùng paste URL vào browser mong muốn.

Các flag đang dùng:

```text
--antigravity-login    Antigravity OAuth
--login                Gemini CLI OAuth
--xai-login            Grok / xAI OAuth
--codex-login          Codex OAuth
```

Codex dùng thêm chế độ:

```powershell
-InteractiveRelay
```

Lý do: Codex cần vừa auto-copy URL OAuth, vừa giữ khả năng nhập callback URL thủ công trong terminal nếu browser callback timeout hoặc chạy trên môi trường không tự callback được.

## 7. Quota dashboard trong TUI

Trong `start-single-account.bat`, quota được render bằng:

```bat
"%INSPECTOR%" --cpa-base-url "%BASE_URL%" -k "%MANAGEMENT_KEY%"
```

Trong đó:

```text
INSPECTOR       E:\CLIProxyAPI\CLIProxyAPI-Quota-Inspector\cpa-quota-inspector.exe
BASE_URL        http://127.0.0.1:8317
MANAGEMENT_KEY  Nội dung file %USERPROFILE%\.cli-proxy-api\management.key
```

Lưu ý về tốc độ:

- Full quota dashboard có thể mất 20 đến 30 giây vì phải gọi quota live cho từng account/provider.
- Trong lúc đó TUI không treo, nó đang chờ `cpa-quota-inspector.exe` chạy xong.
- Script đã in dòng `[INFO] Dang tai quota live, co the mat 20-30 giay...` trước khi gọi inspector.

Nếu muốn nhanh hơn nhưng ít chi tiết hơn, có thể đổi sang:

```bat
"%INSPECTOR%" --cpa-base-url "%BASE_URL%" -k "%MANAGEMENT_KEY%" --summary-only --no-progress
```

Hiện tại project đang ưu tiên hiển thị full table đẹp trong TUI.

## 8. Update CLIProxyAPI binary

`start-single-account.bat` có bước kiểm tra release mới từ GitHub:

```text
router-for-me/CLIProxyAPI
```

Luồng update:

- Đọc version local bằng `get-local-version.ps1`.
- Gọi GitHub API để lấy latest release tag.
- Tải file zip Windows amd64.
- Giải nén.
- Backup file cũ thành `cli-proxy-api.exe.backup`.
- Copy binary mới vào `CLIProxyAPI\cli-proxy-api.exe`.

Nếu update fail, script tiếp tục chạy với binary cũ.

## 9. Các file có thể gây nhầm lẫn

### 9.1 config.local.yaml

File này không phải runtime config chính nếu script đang dùng đường dẫn mặc định.

Runtime config chính là:

```text
%USERPROFILE%\.cli-proxy-api\config.yaml
```

Nếu `config.local.yaml` chứa cấu hình thật hoặc thông tin riêng, không nên commit hoặc chia sẻ file này.

### 9.2 start-proxy-hidden.vbs

File này có thể dùng cho shortcut hoặc Task Scheduler để chạy proxy ẩn.

Trong các script hiện tại, không có script nào gọi trực tiếp file này. Trước khi xóa, cần kiểm tra:

- Windows Startup folder.
- Task Scheduler.
- Shortcut trên Desktop hoặc Start Menu.
- File `.lnk` tự tạo trước đó.

### 9.3 start-single-account-old.bat

Đây là bản cũ của TUI custom account. Nên giữ tạm làm fallback. Khi bản mới ổn định đủ lâu, có thể archive hoặc xóa.

## 10. Quy tắc maintain

### 10.1 Không xóa file khi chưa xác nhận entrypoint

Nhiều file `.bat` có thể được người dùng chạy trực tiếp bằng Explorer, shortcut hoặc Task Scheduler. Việc không thấy reference trong code không có nghĩa là file không dùng.

Trước khi xóa file:

- Tìm reference bằng search trong repo.
- Kiểm tra shortcut/task ngoài repo nếu đó là file `.bat`, `.vbs`, `.ps1`.
- Nếu chưa chắc, đổi tên file thành `.bak` một thời gian trước khi xóa hẳn.

### 10.2 Giữ CRLF cho file Windows script

Các file sau nên giữ CRLF:

```text
*.bat
*.cmd
*.ps1
*.vbs
```

Lý do: `cmd.exe` có thể lỗi `The system cannot find the batch label specified` nếu file `.bat` bị lưu LF-only trong một số tình huống.

Có thể kiểm tra nhanh bằng Python:

```powershell
python - <<'PY'
from pathlib import Path
for name in ['start-single-account.bat', 'CLIProxyAPI/oauth-clipboard.ps1']:
    b = Path(name).read_bytes()
    print(name, 'CRLF', b.count(b'\r\n'), 'LF', b.count(b'\n'), 'NUL', b.count(b'\x00'))
PY
```

### 10.3 Không để byte NUL trong script

Nếu `grep` báo file binary hoặc `cmd.exe` chạy lỗi lạ, kiểm tra byte NUL:

```powershell
python - <<'PY'
from pathlib import Path
p = Path('start-single-account.bat')
b = p.read_bytes()
print(b.count(b'\x00'))
PY
```

Nếu có NUL, cần xóa byte đó và lưu lại file dạng text UTF-8 CRLF.

### 10.4 Cẩn thận với logic kill port

Theo yêu cầu hiện tại, `start-single-account.bat` giữ logic cũ:

- Khi khởi chạy: force-kill mọi PID đang chiếm port `8317` và `8318`.
- Khi shutdown: dùng `netstat` + `taskkill` cho port `8317`.

Điều này tiện khi muốn đảm bảo port sạch, nhưng có rủi ro kill nhầm server đang phục vụ phiên khác.

Không chạy `start-single-account.bat` trên máy đang có phiên quan trọng nếu chưa chấp nhận rủi ro port `8317` và `8318` bị dừng.

### 10.5 Khi sửa OAuth flow

Codex khác các flow còn lại vì cần giữ input callback thủ công. Nếu sửa `oauth-clipboard.ps1`, cần đảm bảo:

- URL OAuth vẫn được copy vào clipboard.
- Output vẫn hiện ra terminal.
- Người dùng vẫn paste callback URL vào terminal được.
- Không dùng pipeline đơn giản cho Codex nếu pipeline đó làm mất stdin tương tác.

### 10.6 Khi sửa quota dashboard

Quota dashboard chạy blocking. Nếu đổi sang background, cần thiết kế thêm:

- File cache output quota.
- Process refresh nền.
- Trạng thái đang tải.
- Cách tránh ghi đè output khi người dùng đang thao tác menu.

Hiện tại cách blocking đơn giản hơn và ổn định hơn.

## 11. Quy trình phát triển đề xuất

### 11.1 Trước khi sửa

- Kiểm tra `git status`.
- Đọc file liên quan trước khi edit.
- Nếu sửa `.bat`, luôn giữ CRLF.
- Không chạy script có thể start/stop server nếu chưa được xác nhận.

### 11.2 Sau khi sửa `.bat` hoặc `.ps1`

Chạy kiểm tra tĩnh:

```powershell
git diff --check -- start-single-account.bat CLIProxyAPI/oauth-clipboard.ps1
```

Kiểm tra line ending và NUL:

```powershell
python - <<'PY'
from pathlib import Path
for name in ['start-single-account.bat', 'CLIProxyAPI/oauth-clipboard.ps1']:
    p = Path(name)
    if p.exists():
        b = p.read_bytes()
        print(name, 'CRLF', b.count(b'\r\n'), 'LF', b.count(b'\n'), 'NUL', b.count(b'\x00'))
PY
```

Parse PowerShell helper:

```powershell
powershell -NoProfile -Command '$tokens=$null;$errors=$null;[System.Management.Automation.Language.Parser]::ParseFile("E:\CLIProxyAPI\CLIProxyAPI\oauth-clipboard.ps1",[ref]$tokens,[ref]$errors)>$null;if($errors){$errors|ForEach-Object{Write-Host $_.Message};exit 1}else{exit 0}'
```

### 11.3 Live test an toàn

Chỉ live test khi chấp nhận việc port `8317` và `8318` có thể bị kill.

Checklist live test cho `start-single-account.bat`:

- Start script.
- Chọn account.
- Xác nhận server chạy.
- Kiểm tra TUI hiện PID cho CLI và Filter.
- Đợi quota dashboard render xong.
- Bấm `S` refresh quota.
- Bấm `R` reload server.
- Bấm `A` thử OAuth submenu.
- Bấm `B` quay lại chọn account.
- Bấm `Q` tắt server và thoát.

## 12. Troubleshooting

### 12.1 Lỗi `The system cannot find the batch label specified`

Nguyên nhân thường gặp:

- File `.bat` bị lưu LF-only.
- File `.bat` có byte NUL hoặc ký tự control lạ.

Cách xử lý:

- Chuyển file sang UTF-8 CRLF.
- Xóa byte NUL nếu có.

### 12.2 TUI đứng lâu ở `QUOTA DASHBOARD`

Không phải treo. Đây là lúc `cpa-quota-inspector.exe` đang fetch quota live.

Thời gian quan sát thực tế có thể khoảng 20 đến 30 giây cho 3 account Codex.

### 12.3 Quota không hiện

Kiểm tra:

- Server đang chạy tại `http://127.0.0.1:8317`.
- `schema-filter.js` đang chạy.
- `management.key` tồn tại tại `%USERPROFILE%\.cli-proxy-api\management.key`.
- Key đúng với config `remote-management.secret-key`.

### 12.4 OAuth Codex không callback được

Nếu browser không tự callback về port local, copy callback URL từ browser và paste vào terminal khi CLIProxyAPI hỏi.

Flow TUI `A -> 2 Codex` dùng `oauth-clipboard.ps1 -InteractiveRelay`, nên vẫn giữ stdin để nhập callback thủ công.

### 12.5 Port bị chiếm

`start-single-account.bat` sẽ force-kill process đang chiếm `8317` và `8318` khi khởi chạy. Nếu không muốn behavior này, cần sửa lại `:force_free_start_ports` thành chỉ cảnh báo, không kill.

## 13. Gợi ý tối ưu sau này

Các cải tiến nên cân nhắc:

- Chuẩn hóa `login-codex.bat` để cũng dùng `oauth-clipboard.ps1 -InteractiveRelay` giống TUI.
- Thêm chế độ quota cache để TUI hiện menu ngay, còn quota refresh nền.
- Tách phần PowerShell dài trong `.bat` ra file `.ps1` riêng để dễ maintain.
- Thêm script `verify-local.ps1` chỉ chạy static check, không start/stop server.
- Thêm cấu hình cho phép chọn port thay vì hard-code `8317` và `8318`.

## 14. Nguyên tắc an toàn khi commit

Không commit các file chứa dữ liệu riêng:

- Account OAuth JSON thật.
- `management.key` thật.
- Config local có secret hoặc thông tin cá nhân.
- Log có token hoặc request nhạy cảm.

Các file nên được coi là template hoặc public:

- `config.example.yaml`
- `management.key.example`
- Script `.bat`, `.ps1`, `.js` đã được kiểm tra không chứa secret.

## 15. Tóm tắt nhanh

Dùng hằng ngày:

```bat
E:\CLIProxyAPI\start-single-account.bat
```

Dùng full proxy không chọn account:

```bat
E:\CLIProxyAPI\CLIProxyAPI\start-proxy.bat
```

Xem quota độc lập:

```bat
E:\CLIProxyAPI\show-quota-dashboard.bat
```

Thêm OAuth account độc lập:

```bat
E:\CLIProxyAPI\CLIProxyAPI\login-codex.bat
E:\CLIProxyAPI\CLIProxyAPI\login-gemini.bat
E:\CLIProxyAPI\CLIProxyAPI\login-antigravity.bat
E:\CLIProxyAPI\CLIProxyAPI\login-grok.bat
```

File quan trọng nhất để maintain TUI hiện tại:

```text
E:\CLIProxyAPI\start-single-account.bat
E:\CLIProxyAPI\CLIProxyAPI\oauth-clipboard.ps1
E:\CLIProxyAPI\CLIProxyAPI\schema-filter.js
E:\CLIProxyAPI\CLIProxyAPI\get-local-version.ps1
E:\CLIProxyAPI\CLIProxyAPI-Quota-Inspector\cpa-quota-inspector.exe
```
