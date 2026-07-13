# Backlog: Memory System (notebooks/review/<repo>/)

Mục tiêu: định nghĩa format + hành vi bootstrap/idempotent của hệ thống memory theo từng repo đang
review, để `commands/pr.md` tham chiếu logic đã được task-hoá rõ ràng thay vì mô tả lại từ đầu. Đây
là state RUNTIME (được tạo khi CHẠY lệnh, không phải file build sẵn trong plugin).

## Task M1: Định nghĩa format `memory.md` (index file)
- Acceptance:
  - Mỗi dòng 1 lesson, có tag stack liên quan (vd `[rails]`, `[vue]`, `[python]`, có thể nhiều tag),
    link tới file trong `memories/`.
  - Ví dụ 1 dòng: `- [rails] Không dùng raw SQL string interpolation trong scope -> memories/no-raw-sql-in-scope.md`
  - File khởi tạo (khi CHƯA có) là khung rỗng + 1 dòng comment giải thích format trên.

## Task M2: Định nghĩa format 1 file `memories/<lesson>.md`
- Acceptance:
  - Nội dung tối thiểu: mô tả convention, ví dụ code trước/sau (nếu có), tag stack, ngày ghi nhận,
    nguồn gốc (link PR nơi phát hiện đồng thuận — optional).
  - Tên file `<lesson>.md` là slug ngắn gọn kebab-case, không dùng số thứ tự vô nghĩa.
- Dependency: M1 (đồng bộ cách link giữa index và file con).

## Task M3: Đặc tả logic existence-check + bootstrap (pr.md bước 4 tham chiếu)
- Acceptance, step-by-step không mơ hồ:
  1. `short_name_repository` = segment path giữa `github.com/<owner>/<repo>/pull/...` của PR URL.
  2. Check `notebooks/review/<short_name>/memory.md` tồn tại tại pwd (KHÔNG phải path trong plugin).
  3. Nếu CHƯA tồn tại:
     - Tạo `notebooks/review/<short_name>/memory.md` (format M1) + `notebooks/review/<short_name>/memories/`.
     - `git init` NGAY BÊN TRONG `notebooks/review/` (không phải bên trong `<short_name>/`) — 1 git
       repo DUY NHẤT bao trùm TẤT CẢ `<short_name>/` sau này (nested, độc lập git chính, KHÔNG push,
       chỉ auto-commit local). Nếu `notebooks/review/.git` đã tồn tại từ trước (đã review repo khác
       trên cùng máy) → KHÔNG init lại, chỉ thêm `<short_name>/` mới vào git đó và commit.
     - Kiểm `.gitignore` ở root repo-đang-review: nếu tồn tại và CHƯA có dòng `notebooks/review/` →
       append; nếu chưa có `.gitignore` → tạo mới chỉ chứa dòng đó.
  4. Nếu ĐÃ tồn tại: bỏ qua HOÀN TOÀN bước 3 (không tạo lại, không git init lại, không sửa
     .gitignore lại dù thiếu dòng), đi thẳng sang bước nạp rule/memory/template.
  - Test case bắt buộc: (a) lần đầu trên repo mới → đúng toàn bộ bước 3; (b) lần 2 cùng repo →
    không có bất kỳ ghi/sửa file nào ngoài nội dung review post lên GitHub; (c) repo thứ 2 (short_name
    khác) sau khi đã có `notebooks/review/.git` → không init lại, chỉ thêm `<short_name-2>/` mới.
- Dependency: M1, M2.

## Task M4: Đặc tả logic re-review / đề xuất lesson (pr.md bước 6 tham chiếu)
- Acceptance:
  - Luôn gọi `gh api repos/{owner}/{repo}/pulls/{pull_number}/comments` mỗi lần chạy (kể cả PR mới
    toanh — response rỗng không phải lỗi).
  - Chỉ xét reply chain của CHÍNH PR đang review (không quét PR khác).
  - Agent đọc tự nhiên nội dung comment + reply, tự phán đoán "đã đồng thuận" — KHÔNG dựa vào
    trạng thái resolved (chủ đích, không phải giới hạn kỹ thuật).
  - Nếu phát hiện đồng thuận → KHÔNG tự ghi ngay → đề xuất trong chat (nội dung lesson dự kiến, tag
    stack dự kiến) → chờ xác nhận → chỉ ghi `memories/<lesson>.md` (M2) + entry `memory.md` (M1) SAU
    KHI user xác nhận đồng ý.
- Dependency: M1, M2, M3.

## Thứ tự: M1 → M2 → M3 → M4
