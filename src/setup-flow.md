# Setup flow — thiết lập lần đầu cho 1 repo

Không phải slash command (nằm ngoài `commands/`); `commands/pr.md` nạp bằng `Read` khi repo chưa
thiết lập xong.

Toàn bộ thao tác dưới đây chạy tại **ĐÚNG pwd hiện tại của phiên** — thư mục mà lệnh `/review:pr`
được gọi. TUYỆT ĐỐI KHÔNG `cd` sang thư mục khác, KHÔNG tự dò tìm "git root"/"thư mục repo thật
sự", KHÔNG dùng basename của bất kỳ thư mục nào để suy ra đường dẫn hay tên repo. Tên thư mục memory
`<repo>` LUÔN là segment `<repo>` đã parse từ PR URL (xem block "Ngữ cảnh" của `pr.md`), KHÔNG suy
từ pwd/thư mục con/git remote. Đứng ở đâu tạo ở đó — không ngoại lệ.

Công cụ được phép: `Read`/`Write`/`Edit`, `git`/`cp`/`mkdir` (qua Bash), và `Agent` (chỉ ở Phần C —
spawn subagent quét convention song song). Dùng `cp` để copy nguyên bản file (không Read+Write lại
qua context — tốn token); `mkdir -p` để tạo thư mục.

## Phần A — Bootstrap `notebooks/review/<repo>/`

1. Dùng `Write` tạo `notebooks/review/<repo>/memory.md` — khung index RỖNG:
   ```
   <!-- Index. Mỗi dòng 1 entry, ngắn gọn, không lặp từ:
        - [tag] [nhãn ngắn](path) — hook 1 dòng
        `path` trỏ tới memories/<slug>.md (lesson tự học, xem Phần E) HOẶC thẳng path trong repo
        (tham chiếu convention có sẵn của dự án, xem Phần C — doctor; KHÔNG copy nội dung, chỉ trỏ
        path). Nhiều tag nếu áp dụng nhiều stack, vd [rails][ruby]. Giữ mỗi dòng dưới 1 câu, gộp ý
        trùng lặp, không diễn giải lại "xem convention tại..." — bản thân link đã nói điều đó. -->
   ```
2. Dùng `Write` tạo `notebooks/review/<repo>/memories/.gitkeep` (rỗng) — chỉ để vật lý hoá
   thư mục `memories/` (git không track thư mục rỗng).
3. Dùng `Write` tạo `notebooks/review/<repo>/templates/.gitkeep` (rỗng) — thư mục này sẽ chứa
   bản LOCAL copy của (các) template stack đang dùng trong repo (xem Phần B), tạo sẵn thư mục trước.
4. Kiểm `notebooks/review/.gitignore` đã tồn tại chưa (`Read` thử) — file RIÊNG của git nested
   `notebooks/review/.git` (khác `.gitignore` của repo chính ở bước 8 dưới), cần có để worktree
   ephemeral chứa code PR checkout (Bước 1 của `pr.md`, dưới
   `notebooks/review/<repo>/worktrees/...`) KHÔNG bao giờ lọt vào git nested này — nested repo chỉ
   nên chứa memory/template/rule, không phải code PR đang review:
   - Chưa tồn tại → `Write` tạo mới `notebooks/review/.gitignore` chỉ chứa đúng 1 dòng `worktrees/`.
   - Tồn tại nhưng CHƯA có dòng `worktrees/` (repo nested có thể đã tạo từ trước Task P11) → `Edit`
     append thêm dòng đó.
   - Đã có đủ → bỏ qua.
5. Copy `ALWAYS_RULE.md` từ plugin vào bản LOCAL của repo bằng `cp` (KHÔNG Read+Write qua context):
   `cp "${CLAUDE_PLUGIN_ROOT}/src/ALWAYS_RULE.md" "notebooks/review/<repo>/ALWAYS_RULE.md"`. Từ
   đây về sau `pr.md` (Bước 5) đọc BẢN LOCAL này — team có thể mở/chỉnh sửa ngay trong repo của họ
   theo dự án, không cần vào tận plugin. Bản trong plugin chỉ là "seed" mặc định lúc bootstrap.
6. Hỏi user 3 câu trong 1 lượt, ngay trong chat (câu hỏi tự nhiên là đủ, không bắt buộc tool cụ
   thể): (1) ngôn ngữ output cho review — vi/en/ja; (2) `auto_submit_review` true/false (mặc định
   **false** nếu user không có ý kiến); (3) `auto_resolve_fixed_findings` true/false (mặc định
   **false**). Xử lý câu trả lời:
   - **Ngôn ngữ** → `Edit` bản LOCAL vừa copy ở bước 5, thay đúng dòng
     `<!-- Chưa set — đang dùng mặc định English. Ví dụ ghi đè: "Luôn output tiếng Việt". -->`
     bằng câu lệnh ngôn ngữ tương ứng, theo đúng định dạng ví dụ có sẵn — vd chọn tiếng Việt:
     `Luôn output tiếng Việt.`; tiếng Anh: `Luôn output tiếng Anh.`; tiếng Nhật: `Luôn output tiếng
     Nhật.`. KHÔNG thêm field riêng vào `meta.json` cho câu này — "đã hỏi ngôn ngữ chưa" tự suy ra
     từ việc dòng comment này còn nguyên văn mặc định hay đã bị ghi đè, không lưu trạng thái ở nơi
     khác.
   - **`auto_submit_review` / `auto_resolve_fixed_findings`** → ghi nhớ 2 giá trị boolean, đưa vào
     `meta.json` cùng lúc với `bootstrapped: true` ở bước 9 dưới đây (schema đầy đủ ở Phần D).
7. Kiểm `notebooks/review/.git` đã tồn tại chưa (thử `Read` file `notebooks/review/.git/HEAD`):
   - **CHƯA tồn tại** → `git init notebooks/review` — 1 git repo DUY NHẤT, nested, độc lập hoàn
     toàn với git của repo chính đang review, bao trùm MỌI `<repo>/` sẽ có sau này. TUYỆT ĐỐI
     KHÔNG set remote, KHÔNG push — chỉ auto-commit local. Sau đó
     `git -C notebooks/review add <repo>` (kèm `notebooks/review/.gitignore` mới tạo ở bước 4 nếu
     có) rồi `git -C notebooks/review commit -m "chore: init review memory for <repo>"`
     — xem cách xác định `user.name`/`user.email` cho commit này ngay dưới đây.
   - **ĐÃ tồn tại** (đã từng review 1 repo khác trên cùng máy) → KHÔNG init lại. Chỉ
     `git -C notebooks/review add <repo>` (kèm `notebooks/review/.gitignore` nếu bước 4 vừa
     tạo/sửa) rồi `git -C notebooks/review commit -m "chore: add review memory for <repo>"`.

   **Danh tính commit** (áp dụng cho mọi commit vào `notebooks/review/.git`, ở đây và ở Phần B/C/E):
   thử `git config user.name` / `git config user.email` tại pwd (root repo CHÍNH đang review — lệnh
   `git config` không kèm `--local`/`--global` tự resolve local (project) trước rồi global, đúng thứ
   tự ưu tiên cần dùng). Nếu có kết quả → dùng giá trị đó cho commit vào `notebooks/review/.git`
   bằng cờ `-c user.name="<giá trị>" -c user.email="<giá trị>"` NGAY SAU `-C notebooks/review` (tức
   `git -C notebooks/review -c user.name="..." -c user.email="..." commit -m "..."` — giữ đúng thứ
   tự này để khớp `allowed-tools`, KHÔNG đặt `-c` trước `-C`). Nếu CẢ project lẫn global đều không
   có `user.name`/`user.email` nào (commit báo lỗi thiếu identity) → mới dùng fallback
   `-c user.name="review-plugin" -c user.email="review-plugin@local"`. KHÔNG set global config của
   máy trong bất kỳ trường hợp nào.
8. Kiểm `.gitignore` tại pwd hiện tại (dùng `Read` tại `./.gitignore`):
   - Tồn tại và CHƯA có dòng `notebooks/review/` → dùng `Edit` append thêm dòng đó.
   - Chưa có `.gitignore` → dùng `Write` tạo mới chỉ chứa đúng 1 dòng `notebooks/review/`.
9. Ghi nhận vào `notebooks/review/<repo>/meta.json` (tạo file nếu chưa có, giữ nguyên các field
   khác nếu file đã tồn tại từ trước — xem Phần D cho schema đầy đủ): `"bootstrapped": true`,
   `"auto_submit_review": <giá trị đã hỏi ở bước 6>`, `"auto_resolve_fixed_findings": <giá trị đã
   hỏi ở bước 6>`.

## Phần B — Copy/tạo local template cho (các) stack hiện có trong PR đang review

Với MỖI stack đã detect được ở Bước 2 của `pr.md` mà CHƯA có trong `templates_copied` (mảng trong
`meta.json`, xem Phần D):

1. Kiểm `${CLAUDE_PLUGIN_ROOT}/src/templates/<stack>.md` có tồn tại không (plugin có sẵn template cho
   stack này chưa).
   - **Có sẵn** → copy nguyên bản bằng `cp` (KHÔNG Read+Write qua context — tốn token với file dài):
     `cp "${CLAUDE_PLUGIN_ROOT}/src/templates/<stack>.md" "notebooks/review/<repo>/templates/<stack>.md"`
     (bản LOCAL, repo có thể tự chỉnh sửa riêng sau này mà không ảnh hưởng plugin dùng chung cho
     repo khác).
   - **CHƯA có sẵn** (plugin chưa cover stack này) → tự soạn 1 template MỚI theo đúng khung 6 mục
     (1.Lỗi&logic 2.Bảo mật 3.Hiệu suất 4.Chất lượng code 5.Đặc thù framework/ngôn ngữ 6.Bảo trì&dễ
     đọc — tham khảo các file trong `${CLAUDE_PLUGIN_ROOT}/src/templates/` để giữ văn phong/độ chi tiết
     nhất quán, KHÔNG lặp tiêu chí đã có trong baseline `ALWAYS_RULE.md`, chỉ viết phần đặc thù),
     lưu vào `notebooks/review/<repo>/templates/<stack>.md`. Báo cho user biết trong chat là
     đã tự tạo template mới cho stack này, kèm gợi ý: user có thể tự copy file này vào
     `${CLAUDE_PLUGIN_ROOT}/src/templates/` để dùng chung cho repo khác — plugin KHÔNG tự động làm (tránh
     mutate file dùng chung từ 1 phiên review của 1 repo cụ thể).
2. Thêm `<stack>` vào mảng `templates_copied` trong `meta.json`.
3. `git -C notebooks/review add <repo>` + commit (local only) phần thay đổi này.

## Phần C — Doctor: khám phá convention có sẵn của dự án

Mục tiêu: nếu dự án đang review đã tự định nghĩa convention/coding rule riêng ở đâu đó (README,
CLAUDE.md, AGENTS.md, docs/, wiki, cursor/copilot rules...), review phải THAM CHIẾU tới đúng nguồn
đó thay vì đoán mò hoặc áp đặt rule ngoài không phù hợp.

Doctor CHỈ CHẠY 1 LẦN DUY NHẤT cho mỗi repo (gate `doctored` trong `meta.json`) và KHÔNG tự chạy
lại — vì vậy phải làm THẬT KỸ, quét TOÀN BỘ repo, không giới hạn theo stack/tính năng của PR hiện
tại. (Chỉ chạy lại khi user CHỦ ĐỘNG yêu cầu "doctor lại" — xem cuối file.)

1. **Quét ĐỆ QUY toàn bộ cây thư mục repo tại pwd** (KHÔNG chỉ root) để tìm HẾT mọi nguồn convention
   — dự án thật thường rải nhiều file ở subfolder, vd `app/operation/AGENTS.md`,
   `app/serializers/AGENTS.md`, không chỉ 1 file gốc. Tìm: `README.md`, `CLAUDE.md`, `AGENTS.md`,
   `GEMINI.md` (và biến thể tương tự như `.md` hướng-dẫn-agent khác), thư mục `docs/`, `wiki/`,
   `.cursorrules` / `.cursor/rules/`, `.github/copilot-instructions.md` — bất kể nằm ở subfolder
   nào. Bỏ qua nguồn không tồn tại, không coi là lỗi.
   **Dùng `Agent` để chạy SONG SONG cho nhanh trên repo lớn** (đã có trong `allowed-tools` của
   `pr.md`): 1 subagent quét toàn cây thư mục (glob/grep) trả về DANH SÁCH path các file convention;
   rồi spawn NHIỀU subagent song song (mỗi subagent 1 file hoặc 1 nhóm file) để đọc + tóm tắt +
   phát hiện convention/mâu thuẫn — thay vì main agent đọc tuần tự từng file (chậm). Không giới hạn
   loại subagent cụ thể (portable qua các môi trường team cấu hình tên subagent khác nhau).

   **Cùng lượt quét này (KHÔNG thêm bước riêng), kiểm tra thêm sự tồn tại của PR template của dự
   án** — khác `project_docs_found` ở trên (nguồn convention chung), đây là 1 field riêng dùng ở
   `pr.md` Bước 7 để đối chiếu checklist PR template với description thật của PR. Kiểm các path phổ
   biến: `.github/PULL_REQUEST_TEMPLATE.md`, `.github/pull_request_template.md`,
   `.github/PULL_REQUEST_TEMPLATE/*.md` (GitHub hỗ trợ 1 thư mục nhiều template, chọn qua query
   param), `PULL_REQUEST_TEMPLATE.md` (root), `docs/PULL_REQUEST_TEMPLATE.md`. Giữ lại danh sách
   path THỰC SỰ tồn tại (mảng rỗng nếu không path nào có) để ghi vào `meta.json` ở bước 6 dưới đây.
2. Với mỗi nguồn tìm được, đọc phần nội dung liên quan tới coding convention/tiêu chí review (bỏ qua
   phần không liên quan như giới thiệu sản phẩm, hướng dẫn cài đặt/deploy).
3. **KHÔNG copy nội dung đã đọc vào memory.** Với mỗi nguồn có convention rõ ràng, không mâu thuẫn
   với gì khác, chỉ thêm 1 dòng THAM CHIẾU vào `memory.md`, đúng format đã ghi ở khung comment Phần
   A: `- [tag nếu xác định được stack liên quan] [nhãn ngắn](path) — hook 1 dòng tóm tắt convention`
   — vd `- [rails] [Controllers](app/controllers/AGENTS.md) — mỏng, không params.permit`. Hook phải
   NGẮN, cô đọng đúng ý chính, không lặp lại cụm "xem convention dự án tại" (bản thân link đã trỏ
   rồi). Khi review, agent tự đọc lại đúng file tại path đó lúc cần — không dựa vào bản copy có thể
   đã lỗi thời.
4. **Nếu phát hiện mâu thuẫn** — 2 nguồn nói khác nhau về cùng 1 vấn đề, HOẶC 1 nguồn tự mâu
   thuẫn/mơ hồ, HOẶC nguồn đó xung đột với baseline/template của plugin (`ALWAYS_RULE.md`/template):
   tự phán đoán cách reconcile hợp lý nhất (ưu tiên nguồn viết riêng cho convention/AI-agent như
   `CLAUDE.md`/`AGENTS.md` hơn `README.md` giới thiệu chung; ưu tiên nguồn cụ thể/chi tiết hơn nguồn
   chung chung). Ghi bản đã reconcile thành 1 lesson theo Phần E (nội dung do agent tự soạn để giải
   quyết mâu thuẫn, không copy nguyên văn 1 nguồn nào), nêu rõ nguồn nào mâu thuẫn với nguồn nào và
   vì sao chọn hướng này. Đây là trường hợp DUY NHẤT ghi lesson mà không cần xác nhận user (agent tự
   soạn trong lúc doctor).
5. **Detect submodule** (chạy đúng 1 lần, cùng lúc doctor — KHÔNG dò lại mỗi lần review): kiểm file
   `.gitmodules` có tồn tại tại root repo (pwd) không (`Read` thử). Có → `has_submodules: true`;
   không → `has_submodules: false`.
6. Ghi nhận vào `meta.json`: `"doctored": true`, `"doctored_at": "<ngày giờ hiện tại>"`,
   `"project_docs_found": [<danh sách path đã tìm thấy ở bước 1, mảng rỗng nếu không có>]`,
   `"has_submodules": <kết quả bước 5>`,
   `"pr_template_paths": [<danh sách path PR template đã tìm thấy ở bước 1, mảng rỗng nếu không có>]`.
7. `git -C notebooks/review add <repo>` + commit (local only) phần thay đổi này.

## Phần D — Schema `meta.json`

```json
{
  "bootstrapped": true,
  "doctored": true,
  "doctored_at": "2026-07-13T10:00:00Z",
  "project_docs_found": ["README.md", "CLAUDE.md"],
  "templates_copied": ["rails", "vue"],
  "auto_submit_review": false,
  "auto_resolve_fixed_findings": false,
  "has_submodules": false,
  "pr_template_paths": [".github/PULL_REQUEST_TEMPLATE.md"]
}
```

`pr.md` coi repo là "đã thiết lập xong" khi `bootstrapped: true` VÀ `doctored: true` — 2 field này
chỉ cần đạt 1 LẦN DUY NHẤT. `templates_copied` thì KHÔNG nằm trong điều kiện "đã xong" đó — nó được
kiểm tra riêng, mỗi lần chạy, cho từng stack detect được trong PR (Phần B luôn có thể chạy lại một
phần nếu PR mới đụng tới stack chưa từng gặp ở repo này, kể cả khi `bootstrapped`/`doctored` đã
`true` từ lâu).

`has_submodules` detect đúng 1 lần lúc doctor (Phần C bước 5, check `.gitmodules` tại root repo),
KHÔNG dò lại mỗi lần review. `pr.md` (Bước 1 mục 5) đọc field này để quyết định có đọc
`src/cases/submodule-review.md` hay không.

`auto_submit_review`/`auto_resolve_fixed_findings` được hỏi + ghi đúng 1 lần lúc bootstrap (Phần A
bước 6/9), mặc định `false` nếu user không có ý kiến khác. `pr.md` đọc lại 2 field này ở Bước 3 và
dùng ở Bước 6 (`auto_resolve_fixed_findings`) và Bước 9 (`auto_submit_review`).

`pr_template_paths` (mảng string, mặc định mảng rỗng) được ghi 1 lần lúc doctor (Phần C bước 1/6) —
danh sách path PR template của dự án tìm thấy (rỗng nếu dự án không có). `pr.md` đọc lại field này ở
Bước 3, dùng ở Bước 7 để đối chiếu checklist PR template với description thật của PR.

## Phần E — Ghi 1 lesson vào memory

Quy trình mechanical dùng chung cho: đồng thuận phát hiện ở Bước 6 của `pr.md`, góp ý convention
user phát biểu trong chat (Bước 10 của `pr.md`), và mâu thuẫn reconcile ở Phần C. Gate xác nhận user
do nơi gọi xử lý (Bước 6 / Bước 10 hỏi trước; Phần C không cần hỏi) — Phần E chỉ mô tả thao tác ghi.

1. Tạo `notebooks/review/<repo>/memories/<lesson-slug>.md` (slug kebab-case ngắn gọn, không
   dùng số thứ tự vô nghĩa). Nội dung tối thiểu: mô tả convention; ví dụ code trước/sau (nếu có);
   tag stack; ngày ghi nhận; nguồn (link PR liên quan nếu có).
2. Thêm 1 dòng vào index `notebooks/review/<repo>/memory.md`, đúng format đã ghi ở khung comment
   Phần A: `- [tag-stack] [nhãn ngắn](memories/<lesson-slug>.md) — hook 1 dòng` (nhiều tag nếu áp
   dụng nhiều stack). Hook ngắn gọn, không lặp từ, không diễn giải dài dòng — chi tiết đã có trong
   file `memories/<lesson-slug>.md`, index chỉ cần đủ để nhận ra lesson là gì.
3. `git -C notebooks/review add <repo>` + commit (local only, không push; nếu commit lỗi thiếu
   `user.name`/`user.email`, dùng cờ `-c` như Phần A).

## Khi user yêu cầu "doctor lại" / "quét lại convention dự án"

Sửa `doctored` trong `meta.json` thành `false` (hoặc xoá hẳn field đó) rồi thực hiện lại Phần C.
Có thể làm ngay trong chat, không cần đợi lần `/review:pr` kế tiếp.
