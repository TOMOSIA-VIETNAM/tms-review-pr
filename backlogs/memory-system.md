# Backlog: Memory System (notebooks/review/<repo>/)

Mục tiêu: định nghĩa format + hành vi bootstrap/idempotent của hệ thống memory theo từng repo đang
review, để `commands/pr.md` tham chiếu logic đã được task-hoá rõ ràng thay vì mô tả lại từ đầu. Đây
là state RUNTIME (được tạo khi CHẠY lệnh, không phải file build sẵn trong plugin).

## Task M1: Định nghĩa format `memory.md` (index file)
- Acceptance:
  - Mỗi dòng 1 lesson, có tag stack liên quan (vd `[rails]`, `[vue]`, `[python]`, có thể nhiều tag),
    link tới file trong `memories/`.
  - Ví dụ 1 dòng (lesson tự học qua re-review): `- [rails] Không dùng raw SQL string interpolation trong scope -> memories/no-raw-sql-in-scope.md`
  - Ví dụ 1 dòng khác (THAM CHIẾU convention có sẵn của dự án, từ Task M5 doctor — KHÔNG copy nội
    dung, chỉ trỏ path): `- [vue] Xem convention dự án tại docs/frontend-conventions.md (tham chiếu trực tiếp, không copy nội dung)`
  - File khởi tạo (khi CHƯA có) là khung rỗng + 1 dòng comment giải thích cả 2 format trên.

## Task M2: Định nghĩa format 1 file `memories/<lesson>.md`
- Acceptance:
  - Nội dung tối thiểu: mô tả convention, ví dụ code trước/sau (nếu có), tag stack, ngày ghi nhận,
    nguồn gốc (link PR nơi phát hiện đồng thuận — optional).
  - Tên file `<lesson>.md` là slug ngắn gọn kebab-case, không dùng số thứ tự vô nghĩa.
- Dependency: M1 (đồng bộ cách link giữa index và file con).

## Task M3: Đặc tả logic existence-check + bootstrap (`setup-flow.md` Phần A, gọi từ pr.md Bước 2)
- Acceptance, step-by-step không mơ hồ:
  1. `short_name_repository` = segment path giữa `github.com/<owner>/<repo>/pull/...` của PR URL.
  2. Check `notebooks/review/<short_name>/meta.json` tồn tại (và có `bootstrapped`/`doctored` đều
     `true`) tại pwd (KHÔNG phải path trong plugin) — đây là điều kiện `pr.md` Bước 2 dùng để quyết
     định có cần `Read` `setup-flow.md` hay không.
  3. Nếu CHƯA (thiết lập lần đầu):
     - Tạo `notebooks/review/<short_name>/memory.md` (format M1) + `notebooks/review/<short_name>/memories/`
       + `notebooks/review/<short_name>/templates/` (rỗng, chứa local template copy — xem M6).
     - `git init` NGAY BÊN TRONG `notebooks/review/` (không phải bên trong `<short_name>/`) — 1 git
       repo DUY NHẤT bao trùm TẤT CẢ `<short_name>/` sau này (nested, độc lập git chính, KHÔNG push,
       chỉ auto-commit local). Nếu `notebooks/review/.git` đã tồn tại từ trước (đã review repo khác
       trên cùng máy) → KHÔNG init lại, chỉ thêm `<short_name>/` mới vào git đó và commit.
     - Kiểm `.gitignore` ở root repo-đang-review: nếu tồn tại và CHƯA có dòng `notebooks/review/` →
       append; nếu chưa có `.gitignore` → tạo mới chỉ chứa dòng đó.
     - Ghi `"bootstrapped": true` vào `meta.json`.
  4. Nếu ĐÃ `bootstrapped`+`doctored`: `pr.md` Bước 2 bỏ qua HOÀN TOÀN, KHÔNG `Read` `setup-flow.md`
     nữa (khác với thiết kế cũ — không chỉ "bỏ qua thao tác" mà còn "không nạp cả nội dung hướng dẫn
     vào context", tiết kiệm token mỗi lần review sau khi đã setup xong).
  - Test case bắt buộc: (a) lần đầu trên repo mới → đúng toàn bộ mục 3; (b) lần 2 cùng repo →
    không có bất kỳ ghi/sửa file nào ngoài nội dung review post lên GitHub, và KHÔNG có tool call
    `Read setup-flow.md` nào trong transcript; (c) repo thứ 2 (short_name khác) sau khi đã có
    `notebooks/review/.git` → không init lại, chỉ thêm `<short_name-2>/` mới.
- Dependency: M1, M2.

## Task M4: Đặc tả logic re-review / đề xuất lesson (pr.md Bước 5 tham chiếu)
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

## Task M5: Đặc tả logic doctor — khám phá convention có sẵn của dự án (`setup-flow.md` Phần C, gọi từ pr.md Bước 2)
- Mục tiêu: nếu dự án đã tự định nghĩa convention ở README/CLAUDE.md/AGENTS.md/docs/wiki/cursor
  rules/copilot instructions, review phải THAM CHIẾU tới đúng nguồn đó thay vì áp rule ngoài không
  phù hợp — nhưng chỉ quét 1 lần (tốn effort), không lặp lại mỗi lần chạy lệnh.
- Acceptance:
  - Trạng thái "đã doctor chưa" theo dõi qua `notebooks/review/<short_name>/meta.json`
    (`{"doctored": bool, "doctored_at": "...", "project_docs_found": [...]}`) — KHÔNG lồng vào
    `memory.md` để tách bạch rõ "đã quét nguồn dự án chưa" khỏi "danh sách lesson".
  - Nếu `doctored` khác `true`: quét sự tồn tại của `README.md`, `CLAUDE.md`, `AGENTS.md`, `docs/`,
    `wiki/`, `.cursorrules`/`.cursor/rules/`, `.github/copilot-instructions.md` tại root repo đang
    review — bỏ qua nguồn không tồn tại, không phải lỗi.
  - Với mỗi nguồn có convention rõ ràng, KHÔNG COPY nội dung — chỉ ghi 1 dòng THAM CHIẾU vào
    `memory.md` trỏ path gốc (định dạng ở Task M1), để agent tự đọc lại bản gốc mỗi lần cần (tránh
    bản copy bị stale khi dự án tự cập nhật docs).
  - Nếu phát hiện MÂU THUẪN (2 nguồn nói khác nhau, 1 nguồn tự mâu thuẫn, hoặc nguồn xung đột với
    `ALWAYS_RULE.md`/`templates/*.md` của plugin): agent tự phán đoán cách reconcile hợp lý (ưu
    tiên nguồn viết riêng cho convention/AI-agent như CLAUDE.md/AGENTS.md hơn README chung chung),
    viết bản đã reconcile thành 1 lesson bình thường vào `memories/<lesson>.md` (nội dung DO AGENT
    TỰ SOẠN, không phải copy 1 nguồn nào) + ghi rõ nguồn nào mâu thuẫn với nguồn nào trong lesson đó.
  - Sau khi xong, ghi `meta.json` với `doctored: true` (kể cả khi không tìm thấy nguồn nào — mảng
    `project_docs_found` rỗng) để lần chạy sau bỏ qua hoàn toàn bước này.
  - User có thể yêu cầu "doctor lại" bất kỳ lúc nào (trong chat, không cần đợi lần `/review:pr` kế
    tiếp) → set `doctored: false` (hoặc xoá `meta.json`) rồi chạy lại quy trình.
  - Test case bắt buộc: (a) repo có sẵn CLAUDE.md rõ ràng → tạo đúng 1 dòng tham chiếu, không copy
    nội dung CLAUDE.md vào memory.md; (b) repo có README và CLAUDE.md mâu thuẫn nhau về cùng 1 vấn
    đề → tạo 1 lesson reconciled + ghi rõ lý do chọn hướng nào; (c) chạy lần 2 → không quét lại,
    không đụng `meta.json`/`memory.md` liên quan tới doctor nữa.
- Dependency: M1, M2, M3.

## Task M6: Đặc tả logic local template copy (`setup-flow.md` Phần B, gọi từ pr.md Bước 3)
- Mục tiêu: repo chỉ nên có bản LOCAL của (các) template stack THỰC SỰ đang dùng, không copy toàn
  bộ 11 template có sẵn trong plugin — và nếu plugin chưa cover 1 stack nào đó, agent tự soạn mới
  thay vì báo lỗi/bỏ qua. Đây cũng là cơ chế "tự cải thiện" của plugin (mở rộng theo nhu cầu thực
  tế từng repo) thay vì bộ template cố định.
- Acceptance:
  - Chạy cho TỪNG stack đã detect ở pr.md Bước 1, kiểm qua mảng `templates_copied` trong
    `meta.json` — KHÔNG gộp chung điều kiện với `bootstrapped`/`doctored` (khác biệt quan trọng: 1
    repo có thể lần đầu chỉ có PR Rails, PR sau mới xuất hiện Vue — lúc đó vẫn phải copy template
    Vue dù bootstrap/doctor đã xong từ lâu).
  - Stack đã có sẵn trong `${CLAUDE_PLUGIN_ROOT}/templates/<stack>.md` → đọc rồi ghi y nguyên ra
    `notebooks/review/<short_name>/templates/<stack>.md`.
  - Stack CHƯA có trong plugin → agent tự soạn 1 template mới theo đúng khung 6 mục + convention
    baseline/delta (không lặp `ALWAYS_RULE.md`), lưu trực tiếp vào bản local, báo cho user trong
    chat là đã tự tạo template mới (không tự động ghi ngược vào `${CLAUDE_PLUGIN_ROOT}/templates/` —
    đó là thao tác thủ công user tự làm nếu muốn dùng chung cho repo khác).
  - Sau khi copy/tạo xong, thêm tên stack vào `templates_copied`, commit (local, git nested).
  - Từ đây trở đi, `pr.md` Bước 4 đọc rule đặc thù stack từ bản LOCAL, không đọc trực tiếp từ
    `${CLAUDE_PLUGIN_ROOT}/templates/` nữa.
  - Test case bắt buộc: (a) PR đầu tiên của repo dùng Rails → chỉ có `templates/rails.md` local,
    KHÔNG có 10 file còn lại; (b) PR sau đó của CÙNG repo có thêm file Vue → tự động copy thêm
    `templates/vue.md` local dù bootstrap/doctor đã xong; (c) PR dùng 1 stack lạ (vd Elixir) chưa
    có trong plugin → agent tự soạn `templates/elixir.md` local + báo cho user.
- Dependency: M3 (cần thư mục `templates/` đã tạo ở bootstrap).

## Thứ tự: M1 → M2 → M3 → M4 → M5 → M6 (M4, M5, M6 độc lập nhau, có thể làm song song sau M3)
