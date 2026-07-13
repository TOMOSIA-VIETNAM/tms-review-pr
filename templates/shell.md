Shell script (bash/sh)

#### 1. Lỗi & Vấn đề logic

- Có bug rõ ràng hoặc lỗi logic nào không?
- Script có `set -euo pipefail` ở đầu không (dừng ngay khi có lệnh lỗi, biến chưa khai báo, hoặc lỗi trong pipeline)?
- Kiểm tra exit code của lệnh con quan trọng có đầy đủ không (không bỏ qua `$?` khi cần biết lệnh trước có thành công không)?
- Có nhánh điều kiện nào bị thiếu (file không tồn tại, biến rỗng) không?

#### 2. Bảo mật

- Có input từ bên ngoài (argument, env var, output lệnh khác) được đưa thẳng vào lệnh thực thi (`eval`, `bash -c`) mà không kiểm tra không?
- Có hardcode secret/credential trong script không?
- Có dùng quyền `sudo`/chạy với quyền cao hơn cần thiết không?

#### 3. Hiệu suất

- Có gọi lệnh con lặp lại không cần thiết trong loop (nên gom lại) không?
- Có xử lý file lớn theo cách tốn tài nguyên (đọc hết vào biến thay vì stream) không?

#### 4. Chất lượng code

- Quoting biến có đúng không (`"$var"` thay vì `$var` trần, tránh word splitting/glob không mong muốn)?
- Dùng `[[ ]]` thay `[ ]` khi có thể (bash) để tránh lỗi parsing/so sánh không mong muốn không?
- Có tránh parse output của `ls` (nên dùng glob hoặc `find` trực tiếp) không?
- Có code bị lặp không (nguyên tắc DRY) — nên tách function không?

#### 5. Đặc thù Shell

- Script có shellcheck-clean không (không có warning nghiêm trọng)?
- Xử lý path có khoảng trắng/ký tự đặc biệt có đúng không (quoting, `IFS`, `find ... -print0` + `xargs -0` khi cần)?
- Idempotency khi script chạy lại nhiều lần có được đảm bảo không (không tạo lỗi/side-effect kép nếu chạy 2 lần)?

#### 6. Khả năng bảo trì & Dễ đọc

- Tên biến/hàm có rõ ràng không?
- Có comment giải thích ở những đoạn logic không rõ ràng không?
- Thiết kế có đủ linh hoạt để đáp ứng thay đổi trong tương lai không?
