# Backlog: Command /review:pr (commands/pr.md)

Mục tiêu: encode toàn bộ luồng review vào 1 file lệnh DUY NHẤT. Vertical slice: dựng bản chạy được
review đơn-stack trước, rồi mới layer thêm memory + re-review + multi-stack + overlay (lambda/laravel/wordpress).

## Task P1 (Slice 1): Khung command + validate + context + post review đơn giản
- Lưu ý danh tính: review post lên PR không hardcode tên người review — `gh api` tự đăng bằng tài
  khoản `gh auth` đang active trên máy chạy lệnh (khác với `author.name` trong plugin.json, vốn là
  tên người BUILD plugin = "Minh Tang Q.", xem plugin-scaffold.md task S2). Không cần thêm field
  tên người review vào payload.
- Acceptance:
  - Frontmatter đúng (`argument-hint`, `description`, `allowed-tools` gồm `Bash(gh:*)` tối thiểu).
  - Block `## Ngữ cảnh` gồm đủ gh command (view info, headRefOid, diff --name-only, diff, commits)
    đúng cú pháp `!\`...\`` như 2 file tham khảo.
  - Validate ARGUMENTS: rỗng hoặc không match `^https://github\.com/.+/.+/pull/[0-9]+` → in đúng
    format lỗi (đổi tên lệnh thành `/review:pr`) → dừng.
  - CHƯA cần detect stack đa dạng — review 1 file bằng 1 template (rails.md hoặc vue.md) để verify
    luồng end-to-end sớm.
  - Post: `gh api -X POST repos/{owner}/{repo}/pulls/{pull_number}/reviews -f body=... -f
    commit_id=... -f event="COMMENT" -F comments:='<json>'`. `{owner}/{repo}/{pull_number}` parse
    từ chính PR URL trong ARGUMENTS.
- Dependency: Task T1 hoặc T2 (templates.md), Task S4 (ALWAYS_RULE.md).

## Task P2: Detect stack đầy đủ + xử lý mixed-stack trong 1 PR
- Acceptance: bảng mapping đuôi/path → template đúng kiến trúc (rb/erb/haml→rails, vue→vue,
  jsx/tsx+heuristic→react, py→python, js/ts còn lại→nodejs, sh/bash→shell, Makefile/*.mk→makefile,
  php→php). PR có ≥2 stack → áp dụng ĐÚNG template cho ĐÚNG file.
- Dependency: P1.

## Task P3: Overlay templates (lambda-common, laravel, wordpress)
- Acceptance:
  - lambda: path chứa `lambda`/`lambdas`/`functions/`, HOẶC có `serverless.yml`/`template.yaml`/
    `sam.yaml`, HOẶC filename `handler.py`/`handler.js`/`index.py`/`index.js` cạnh config trên →
    overlay lambda-common.md lên python.md/nodejs.md.
  - laravel: có `artisan`, `composer.json` chứa `laravel/framework`, hoặc path `app/Http/Controllers`,
    `resources/views/*.blade.php` → overlay laravel.md lên php.md.
  - wordpress: có `wp-config.php`, path `wp-content/plugins/`, `wp-content/themes/`, hoặc
    `style.css` theme header → overlay wordpress.md lên php.md.
  - Test: overlay không thay thế mất tiêu chí nền, chỉ cộng thêm.
- Dependency: P2, Task T6/T10/T11 (templates.md).

## Task P4: Tích hợp memory system (bootstrap + load + apply)
- Acceptance:
  - Bước existence-check/bootstrap khớp CHÍNH XÁC đặc tả Task M3 (memory-system.md).
  - Nạp memory: đọc `memory.md` + lọc `memories/<lesson>.md` có tag stack trùng stack detect được (P2).
  - Test: lần 1 trên repo mới → `notebooks/review/<repo>/` tạo đúng cấu trúc + git nested. Lần 2
    cùng repo → không thao tác tạo/sửa nào lặp lại.
- Dependency: P2, Task M3.

## Task P5: Tích hợp re-review detection + đề xuất lesson có xác nhận
- Acceptance: khớp đặc tả Task M4. Test bằng PR có sẵn thread đồng thuận → agent ĐỀ XUẤT, KHÔNG tự
  ghi, chỉ ghi sau khi user xác nhận. PR không có comment nào → chạy không lỗi, không đề xuất gì.
- Dependency: P4, Task M4.

## Task P6: Hoàn thiện bước review 6-mục + phân loại file-level/line-level
- Acceptance:
  - Áp dụng common 6-mục (template) + memory (bổ sung, KHÔNG override ALWAYS_RULE — test case mâu
    thuẫn, ALWAYS_RULE thắng).
  - Hướng dẫn "agent tự quyết định file-level vs line-level theo bản chất finding" KHÔNG kèm danh
    sách cứng/enum.
  - Format tổng quan giữ "### Nhận xét tổng quan" + đếm 🔴🟡🟢.
- Dependency: P4.

## Task P7: Hoàn thiện schema post review
- Acceptance:
  - `comments[]` gồm CẢ 🔴🟡🟢 (không lọc bớt).
  - Line-level: `path`, `line`, `side: "RIGHT"`, `body`. File-level: chỉ `path`, `body`.
  - Đúng 1 lần gọi `gh api -X POST .../reviews` cho toàn bộ.
  - JSON dài/phức tạp → dùng `--input -` với heredoc.
- Dependency: P6.

## Task P8: Ghi hành vi chung "xác nhận trước khi ghi memory" trong chat thường
- Acceptance: 1 đoạn trong pr.md mô tả: dùng plugin trong chat bình thường (không qua PR), nếu user
  tự phát biểu convention → agent hỏi xác nhận trước khi ghi memory. Không tạo command riêng.
- Dependency: P4.

## Thứ tự: P1 → P2 → P3 → P4 → P5 → P6 → P7 → P8
(P1 là vertical-slice nên test thật càng sớm càng tốt khi có PR test — xem testing.md)
