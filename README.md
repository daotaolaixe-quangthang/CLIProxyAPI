# CLIProxyAPI Windows Toolkit

Thư mục này là bộ script Windows để chạy CLIProxyAPI, chọn account OAuth, xem quota và quản lý các bản binary liên quan.

## File `.bat` ở root

### `start-single-account.bat`

File chính nên dùng hằng ngày.

Chức năng:

- Chọn một hoặc nhiều account OAuth để chạy riêng.
- Start CLIProxyAPI ở port `8318`.
- Start `schema-filter.js` ở port `8317` để client gọi vào.
- Hiển thị TUI menu điều khiển server.
- Hiển thị quota dashboard live.
- Thêm account OAuth mới bằng phím `A`.

Menu khi server đang chạy:

```text
R    Reload server với account hiện tại
B    Tắt server và quay lại chọn account
A    Thêm account OAuth mới
S    Refresh quota ngay
Q    Tắt server và thoát hoàn toàn
```

Lưu ý: file này đang giữ logic force-kill port cũ. Khi khởi chạy, nó có thể dừng process đang chiếm port `8317` và `8318`.

### `show-quota-dashboard.bat`

Mở dashboard quota độc lập.

Dùng khi server đã chạy tại:

```text
http://127.0.0.1:8317
```

Có thể xem:

- Tất cả provider.
- Codex only.
- Gemini CLI only.
- Antigravity only.
- Grok / xAI only.
- Summary only.
- Export JSON.

### `show-codex-quota.bat`

Mở nhanh quota Codex.

Dùng khi chỉ cần kiểm tra quota Codex mà không mở dashboard đầy đủ.

## Thư mục chính

### `CLIProxyAPI\`

Chứa binary và script chính của CLIProxyAPI.

File quan trọng:

```text
cli-proxy-api.exe          Binary chính
start-proxy.bat           Chạy full proxy với toàn bộ account
schema-filter.js          Proxy lọc JSON Schema, dùng cho port 8317 -> 8318
oauth-clipboard.ps1       Helper OAuth, tự copy URL login vào clipboard
get-local-version.ps1     Helper đọc version local
login-codex.bat           Login Codex OAuth độc lập
login-gemini.bat          Login Gemini CLI OAuth độc lập
login-antigravity.bat     Login Antigravity OAuth độc lập
login-grok.bat            Login Grok / xAI OAuth độc lập
config.example.yaml       Config mẫu
management.key.example    Management key mẫu
README.md                 Tài liệu chi tiết hơn cho folder này
```

Nếu muốn chạy full proxy không chọn account, dùng:

```bat
CLIProxyAPI\start-proxy.bat
```

### `CLIProxyAPI-Linux\`

Chứa bản hoặc script liên quan đến môi trường Linux.

Dùng khi cần chạy CLIProxyAPI trên Linux hoặc tham khảo cấu hình Linux. Xem thêm tài liệu trong:

```text
CLIProxyAPI-Linux\README.md
```

### `CLIProxyAPI-Quota-Inspector\`

Chứa công cụ xem quota live.

File quan trọng:

```text
cpa-quota-inspector.exe
```

Các file `.bat` ở root như `show-quota-dashboard.bat`, `show-codex-quota.bat`, và TUI trong `start-single-account.bat` đều dùng binary này để lấy quota từ server đang chạy.

Xem thêm:

```text
CLIProxyAPI-Quota-Inspector\README.md
```

## Thư mục runtime trong user profile

CLIProxyAPI lưu account và config thật ở:

```text
%USERPROFILE%\.cli-proxy-api
```

Custom account mode dùng thư mục tạm:

```text
%USERPROFILE%\.cli-proxy-api-single
```

Không nên commit hoặc chia sẻ các file sau:

```text
*.json account OAuth thật
management.key thật
config.yaml có secret hoặc thông tin riêng
log có token hoặc request nhạy cảm
```

## Cách dùng nhanh

Chạy TUI chính:

```bat
E:\CLIProxyAPI\start-single-account.bat
```

Xem quota dashboard:

```bat
E:\CLIProxyAPI\show-quota-dashboard.bat
```

Chạy full proxy:

```bat
E:\CLIProxyAPI\CLIProxyAPI\start-proxy.bat
```

Login OAuth độc lập:

```bat
E:\CLIProxyAPI\CLIProxyAPI\login-codex.bat
E:\CLIProxyAPI\CLIProxyAPI\login-gemini.bat
E:\CLIProxyAPI\CLIProxyAPI\login-antigravity.bat
E:\CLIProxyAPI\CLIProxyAPI\login-grok.bat
```

## Maintain nhanh

- Giữ file `.bat`, `.ps1`, `.cmd`, `.vbs` ở dạng CRLF.
- Không để byte NUL trong script.
- Không chạy `start-single-account.bat` nếu đang có phiên quan trọng dùng port `8317` hoặc `8318`, trừ khi chấp nhận việc port đó có thể bị kill.
- Khi sửa OAuth Codex, phải giữ khả năng paste callback URL thủ công.
- Khi sửa quota dashboard, nhớ rằng full quota có thể mất 20 đến 30 giây để tải live.

Tài liệu chi tiết hơn nằm tại:

```text
E:\CLIProxyAPI\CLIProxyAPI\README.md
```
