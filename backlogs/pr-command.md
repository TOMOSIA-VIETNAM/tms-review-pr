# Backlog: Command /review:pr (commands/pr.md)

Mục tiêu: encode toàn bộ luồng review vào 1 file lệnh DUY NHẤT. Vertical slice: dựng bản chạy được
review đơn-stack trước, rồi mới layer thêm memory + re-review + multi-stack + overlay (lambda/laravel/wordpress).

**Cập nhật kiến trúc (sau khi P1-P8 đã build xong lần đầu):** phần thiết lập lần đầu (bootstrap +
doctor) đã tách ra file riêng `setup-flow.md` (ngoài `commands/`, không phải slash command), để
`pr.md` chỉ chứa logic review thuần — xem Task P9. `pr.md` chỉ `Read` `setup-flow.md` khi
`meta.json` cho thấy repo CHƯA thiết lập xong, không dùng bash `!`...`` để gate có điều kiện (bash
chạy trước khi model thấy prompt, không thể điều kiện theo kết quả suy luận của model).

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

## Task P9: Tách setup-flow.md khỏi pr.md + local template copy per-stack
- Acceptance:
  - `setup-flow.md` chứa Phần A (bootstrap, = nội dung cũ Task P4) + Phần B (copy/tự soạn local
    template, = Task M6) + Phần C (doctor, = nội dung cũ Task P5's bootstrap-adjacent phần) + Phần
    D (schema `meta.json` đầy đủ: `bootstrapped`, `doctored`, `doctored_at`, `project_docs_found`,
    `templates_copied`).
  - `pr.md` Bước 2 (thiết lập lần đầu): `Read meta.json` → nếu thiếu `bootstrapped`/`doctored` →
    `Read setup-flow.md`, làm theo Phần A+C; nếu đã đủ → bỏ qua hoàn toàn, KHÔNG `Read` file đó.
  - `pr.md` Bước 3 (đảm bảo local template): chạy MỖI LẦN cho từng stack detect ở Bước 1, kiểm
    `templates_copied` — thiếu thì `Read setup-flow.md` Phần B rồi làm theo. Test: PR sau thêm stack
    mới ở repo đã setup xong từ lâu vẫn tự copy đúng template mới, không bị bỏ qua nhầm.
  - `pr.md` Bước 4 (nạp template) đọc từ `notebooks/review/<short_name>/templates/<stack>.md` (bản
    LOCAL), không đọc trực tiếp `${CLAUDE_PLUGIN_ROOT}/templates/` nữa.
  - Test bắt buộc: review 1 PR trên repo ĐÃ setup xong từ trước → transcript KHÔNG có tool call
    `Read setup-flow.md` nào (trừ khi PR đó đụng stack mới, khi đó chỉ đọc Phần B, không đọc lại
    Phần A/C).
- Dependency: P4 (thay thế nội dung), M6.

## Task P10: Config theo repo (ngôn ngữ/auto-submit/auto-resolve) + fix side LEFT/RIGHT + văn phong (nhánh `main`)

Bối cảnh: grill lại `pr.md` (2026-07-13) phát hiện loạt gap — xem chi tiết quyết định trong lịch sử
chat, tóm tắt acceptance dưới đây. Làm trực tiếp trên `main`, KHÔNG cần branch riêng (không phụ
thuộc P11).

- **Setup hỏi 1 lần lúc bootstrap** (`setup-flow.md` Phần A, ngay sau bước copy `ALWAYS_RULE.md`):
  hỏi user 3 câu trong 1 lượt — (1) ngôn ngữ output vi/en/ja, (2) `auto_submit_review` true/false
  (default **false**), (3) `auto_resolve_fixed_findings` true/false (default **false**).
  - Câu (1) — KHÔNG lưu vào `meta.json` (tránh 2 nguồn sự thật trùng lặp): ghi thẳng vào khối
    override có sẵn trong `notebooks/review/<repo>/ALWAYS_RULE.md` (đúng chỗ comment
    `<!-- Chưa set — đang dùng mặc định English... -->` → thay bằng câu lệnh ngôn ngữ tương ứng, vd
    "Luôn output tiếng Việt."). Điều kiện "đã hỏi chưa" = tự suy ra từ việc comment mặc định đó còn
    y nguyên hay đã bị thay — KHÔNG thêm cờ riêng trong `meta.json` cho việc này.
  - Câu (2), (3) — lưu trực tiếp `meta.json` (`auto_submit_review`, `auto_resolve_fixed_findings`),
    field mới trong Phần D.
  - Vì repo chưa public, KHÔNG cần xử lý backfill cho repo đã bootstrap từ trước — chỉ áp dụng từ
    bootstrap mới trở đi.
- **Bước 9 của `pr.md`** rẽ theo `auto_submit_review`:
  - `true` (giữ hành vi cũ): payload luôn có `"event": "COMMENT"`.
  - `false`: payload KHÔNG có field `event` (review dừng ở PENDING, chỉ user thấy). Đoạn verify cuối
    Bước 9 hiện đang tự động submit khi thấy `state: PENDING` (coi là lỗi) phải sửa: khi
    `auto_submit_review = false`, PENDING là CHỦ Ý — verify chỉ báo cho user "đã tạo review nháp,
    vào GitHub tự submit khi sẵn sàng", KHÔNG gọi API submit.
- **Bước 6 của `pr.md`** (nhánh "đã fix" — không phải nhánh học convention mới, nhánh đó giữ nguyên
  luôn phải hỏi xác nhận) rẽ theo `auto_resolve_fixed_findings`:
  - `true` (giữ hành vi cũ): reply "đã fix" + gọi GraphQL resolve thread.
  - `false`: CHỈ reply "đã fix", KHÔNG gọi resolve thread.
- **Fix side LEFT/RIGHT** (bug thật, không phải preference): Bước 7 lúc phân loại finding cấp LINE
  phải tự xác định `side` theo diff — dòng bị XOÁ (nằm ở nửa cũ của diff) → `"side": "LEFT"`; dòng
  THÊM/GIỮ (nửa mới) → `"side": "RIGHT"`. Bước 9 bỏ hardcode `"side": "RIGHT"` trong ví dụ payload,
  thay bằng mô tả rẽ nhánh theo side đã xác định ở Bước 7.
- **Văn phong**: viết lại `pr.md` súc tích hơn ở những đoạn giải thích dài dòng/lặp ý (không đổi
  logic, không cắt bớt rule an toàn/rigor) — mục tiêu dễ theo dõi hơn cho người đọc lẫn agent thực
  thi, tránh over-explain.
- Acceptance: bootstrap 1 repo test mới → agent hỏi đúng 3 câu 1 lượt, ghi đúng chỗ (ngôn ngữ vào
  `ALWAYS_RULE.md` local, 2 field còn lại vào `meta.json`); review test có finding trên dòng bị xoá
  → payload đúng `side: LEFT`; review lần 2 với `auto_submit_review=false` → review ở trạng thái
  PENDING, verify KHÔNG tự submit.
- Dependency: P9 (đã có sẵn kiến trúc setup-flow.md tách biệt).

## Task P11: Worktree thay checkout thẳng + review submodule PR (nhánh `feature/pr-review-worktree`)

Tạo branch riêng từ `main` (SAU khi P10 đã merge/commit xong) để user tự thử nghiệm trước khi merge
— thay đổi kiến trúc lớn, rủi ro cao hơn P10.

- **Bước 1 của `pr.md` viết lại hoàn toàn** — bỏ checkout thẳng lên working tree hiện tại, bỏ gate
  "chặn nếu working tree bẩn" (không còn lý do tồn tại), bỏ đoạn "ghi nhớ + khôi phục branch cũ".
  Thay bằng:
  1. Mỗi lần review tạo 1 worktree TÊN RANDOM, KHÔNG tái sử dụng, KHÔNG pool/lock (đã cân nhắc pool
     nhưng chọn đơn giản hơn — cleanup để sau, ngoài phạm vi task này):
     `git worktree add "notebooks/review/<repo>/worktrees/review-pr<pull_number>-$RANDOM" ...`.
  2. Mọi lệnh `gh pr checkout`/`gh pr view`/`gh pr diff` dùng cờ `-R owner/repo` tường minh (owner/repo
     đã parse sẵn ở block Ngữ cảnh) thay vì dựa gh tự đoán remote qua config local — tránh lỗi khi
     repo có nhiều remote hoặc không remote nào. `gh pr checkout` cụ thể cần chạy trong đúng thư mục
     worktree vừa tạo — dùng subshell `(cd "notebooks/review/<repo>/worktrees/<tên>" && gh pr checkout
     <n> -R owner/repo)`, KHÔNG dùng `cd` trần (không đổi cwd của phiên chính — rule "cấm cd" ở đầu
     file chỉ áp dụng cho pwd chính, ghi rõ ngoại lệ này).
  3. Sau checkout, LUÔN chạy `git -C "<worktree>" submodule update --init --recursive` (kể cả khi
     PR không đụng submodule — vô hại, đảm bảo submodule sẵn sàng nếu Bước review cần).
  4. Không còn bước khôi phục branch cuối cùng (main tree chưa từng đổi branch).
- **`allowed-tools` cập nhật**:
  - Thêm: `Bash(git worktree add notebooks/review/*/worktrees/*)` (neo path, không cho tạo worktree
    ngoài `notebooks/review/`), `Bash(cd notebooks/review/*/worktrees/* && gh pr checkout:*)`,
    `Bash(git -C notebooks/review/*/worktrees/* submodule update:*)`.
  - Bỏ: `Bash(git branch:*)`, `Bash(git checkout:*)` (bare, ngoài `-C notebooks/review`) — không
    còn dùng sau khi bỏ đồng bộ branch main tree.
- **`.gitignore` của git nested** (`notebooks/review/.gitignore`, tạo lúc bootstrap Phần A — file
  này hiện CHƯA có, cần thêm bước tạo nếu chưa tồn tại) — thêm dòng `worktrees/` để code PR (nằm
  trong worktree) không lọt vào git nested vốn chỉ nên chứa memory/template/rule.
- **File mới `src/submodule-review.md`** (tách khỏi `pr.md`, theo đúng pattern
  `setup-flow.md`/`stack-detection.md` — không nhét case đặc thù vào file lệnh chính):
  - `pr.md` chỉ có 1 điều kiện ngắn ở Bước 1 (sau khi checkout xong): nếu
    `meta.json.has_submodules == true` VÀ diff PR hiện tại có dòng `Subproject commit` (submodule
    pointer đổi) → `Read` file này và làm theo.
  - Nội dung file: diff cho thấy submodule bump nhưng KHÔNG tìm thấy link PR submodule nào trong PR
    description → hỏi user cung cấp link PR submodule đó (không tự đoán/bỏ qua).
  - Sau khi có link: TÁI DÙNG đúng thư mục submodule đã có sẵn trong worktree (từ bước submodule
    update ở trên, path `<worktree>/<đường-dẫn-submodule>/`) — KHÔNG tạo worktree thứ 2. Chạy
    `(cd "<worktree>/<đường-dẫn-submodule>" && gh pr checkout <n-submodule> -R
    <owner-submodule>/<repo-submodule>)` để lấy code PR submodule vào đúng đó.
  - Review PR submodule ĐẦY ĐỦ như PR chính (áp dụng lại Bước 2 → Bước 8 của `pr.md` cho phần diff
    submodule — stack detect riêng, dùng CHUNG memory/template của repo CHÍNH, không tạo
    `notebooks/review/<tên-submodule-repo>/` riêng). Output phân biệt rõ 2 phần: review PR chính vs
    review PR submodule.
  - KHÔNG xử lý submodule-lồng-submodule (2 tầng) — edge case hiếm, chấp nhận bỏ qua.
  - Vì gh CLI thường dùng chung 1 tài khoản auth cho cả repo chính lẫn submodule (theo xác nhận
    thực tế của user), KHÔNG cần thêm cơ chế auth riêng cho submodule.
- **`meta.json` schema (Phần D) thêm field**: `has_submodules` (boolean) — detect ở Phần C (doctor,
  check tồn tại file `.gitmodules` tại root repo), chỉ chạy 1 lần cùng lúc doctor, KHÔNG dò lại mỗi
  review.
- **Cô lập khi chạy đồng thời nhiều review** (đã xác nhận với user): vì worktree đặt tên random mỗi
  lần, KHÔNG tái sử dụng — 2 phiên review chạy song song (cùng PR hay khác PR, cùng repo) luôn có
  thư mục worktree vật lý riêng biệt, submodule bên trong cũng theo đó tách biệt tự nhiên, không cần
  thêm cơ chế lock nào. Rủi ro còn lại DUY NHẤT: `meta.json`/`memory.md` là file dùng chung có thể
  mất 1 write nếu 2 phiên cùng ghi đồng thời (race hiếm — chỉ xảy ra lúc setup/thêm template mới,
  KHÔNG mỗi lần review) — user đã xác nhận chấp nhận, không xây lock.
- Acceptance: review 2 PR cùng repo (kể cả cùng PR số) chạy // → mỗi cái có worktree riêng, không
  đụng nhau; review PR có bump submodule + link trong description → review cả 2 phần rõ ràng; review
  PR có bump submodule nhưng KHÔNG có link → agent hỏi user cung cấp; repo không `.gitmodules` →
  không bao giờ đọc `submodule-review.md`.
- Dependency: P10 (branch tạo từ `main` sau khi P10 xong).

## Thứ tự: P1 → P2 → P3 → P4 → P5 → P6 → P7 → P8 → P9 → P10 → P11
(P1 là vertical-slice nên test thật càng sớm càng tốt khi có PR test — xem testing.md. P10 làm trên
`main`; P11 tạo branch `feature/pr-review-worktree` riêng sau khi P10 xong, để user tự thử nghiệm
trước khi merge.)
