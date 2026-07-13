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
   <!-- Index các bài học convention đã ghi nhận cho repo này. Mỗi dòng 1 lesson, format:
        - [tag-stack] Mô tả ngắn gọn lesson -> memories/<slug>.md
        Có thể gắn nhiều tag nếu lesson áp dụng nhiều stack, vd [rails][ruby].
        Một dòng cũng có thể là THAM CHIẾU tới convention có sẵn của dự án (xem Phần C — doctor)
        thay vì 1 lesson tự học, format: - [tag-stack] Xem convention dự án tại <path trong repo>
        (tham chiếu trực tiếp, không copy nội dung). -->
   ```
2. Dùng `Write` tạo `notebooks/review/<repo>/memories/.gitkeep` (rỗng) — chỉ để vật lý hoá
   thư mục `memories/` (git không track thư mục rỗng).
3. Dùng `Write` tạo `notebooks/review/<repo>/templates/.gitkeep` (rỗng) — thư mục này sẽ chứa
   bản LOCAL copy của (các) template stack đang dùng trong repo (xem Phần B), tạo sẵn thư mục trước.
4. Copy `ALWAYS_RULE.md` từ plugin vào bản LOCAL của repo bằng `cp` (KHÔNG Read+Write qua context):
   `cp "${CLAUDE_PLUGIN_ROOT}/ALWAYS_RULE.md" "notebooks/review/<repo>/ALWAYS_RULE.md"`. Từ
   đây về sau `pr.md` (Bước 4) đọc BẢN LOCAL này — team có thể mở/chỉnh sửa ngay trong repo của họ
   theo dự án, không cần vào tận plugin. Bản trong plugin chỉ là "seed" mặc định lúc bootstrap.
5. Kiểm `notebooks/review/.git` đã tồn tại chưa (thử `Read` file `notebooks/review/.git/HEAD`):
   - **CHƯA tồn tại** → `git init notebooks/review` — 1 git repo DUY NHẤT, nested, độc lập hoàn
     toàn với git của repo chính đang review, bao trùm MỌI `<repo>/` sẽ có sau này. TUYỆT ĐỐI
     KHÔNG set remote, KHÔNG push — chỉ auto-commit local. Sau đó
     `git -C notebooks/review add <repo>` rồi
     `git -C notebooks/review commit -m "chore: init review memory for <repo>"`
     (nếu môi trường chưa cấu hình `user.name`/`user.email` global và commit báo lỗi, dùng cờ
     `-c user.name="review-plugin" -c user.email="review-plugin@local"` CHỈ cho lần commit này,
     KHÔNG set global config).
   - **ĐÃ tồn tại** (đã từng review 1 repo khác trên cùng máy) → KHÔNG init lại. Chỉ
     `git -C notebooks/review add <repo>` rồi
     `git -C notebooks/review commit -m "chore: add review memory for <repo>"`.
6. Kiểm `.gitignore` tại pwd hiện tại (dùng `Read` tại `./.gitignore`):
   - Tồn tại và CHƯA có dòng `notebooks/review/` → dùng `Edit` append thêm dòng đó.
   - Chưa có `.gitignore` → dùng `Write` tạo mới chỉ chứa đúng 1 dòng `notebooks/review/`.
7. Ghi nhận `"bootstrapped": true` vào `notebooks/review/<repo>/meta.json` (tạo file nếu
   chưa có, giữ nguyên các field khác nếu file đã tồn tại từ trước — xem Phần D cho schema đầy đủ).

## Phần B — Copy/tạo local template cho (các) stack hiện có trong PR đang review

Với MỖI stack đã detect được ở Bước 1 của `pr.md` mà CHƯA có trong `templates_copied` (mảng trong
`meta.json`, xem Phần D):

1. Kiểm `${CLAUDE_PLUGIN_ROOT}/templates/<stack>.md` có tồn tại không (plugin có sẵn template cho
   stack này chưa).
   - **Có sẵn** → copy nguyên bản bằng `cp` (KHÔNG Read+Write qua context — tốn token với file dài):
     `cp "${CLAUDE_PLUGIN_ROOT}/templates/<stack>.md" "notebooks/review/<repo>/templates/<stack>.md"`
     (bản LOCAL, repo có thể tự chỉnh sửa riêng sau này mà không ảnh hưởng plugin dùng chung cho
     repo khác).
   - **CHƯA có sẵn** (plugin chưa cover stack này) → tự soạn 1 template MỚI theo đúng khung 6 mục
     (1.Lỗi&logic 2.Bảo mật 3.Hiệu suất 4.Chất lượng code 5.Đặc thù framework/ngôn ngữ 6.Bảo trì&dễ
     đọc — tham khảo các file trong `${CLAUDE_PLUGIN_ROOT}/templates/` để giữ văn phong/độ chi tiết
     nhất quán, KHÔNG lặp tiêu chí đã có trong baseline `ALWAYS_RULE.md`, chỉ viết phần đặc thù),
     lưu vào `notebooks/review/<repo>/templates/<stack>.md`. Báo cho user biết trong chat là
     đã tự tạo template mới cho stack này, kèm gợi ý: user có thể tự copy file này vào
     `${CLAUDE_PLUGIN_ROOT}/templates/` để dùng chung cho repo khác — plugin KHÔNG tự động làm (tránh
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
2. Với mỗi nguồn tìm được, đọc phần nội dung liên quan tới coding convention/tiêu chí review (bỏ qua
   phần không liên quan như giới thiệu sản phẩm, hướng dẫn cài đặt/deploy).
3. **KHÔNG copy nội dung đã đọc vào memory.** Với mỗi nguồn có convention rõ ràng, không mâu thuẫn
   với gì khác, chỉ thêm 1 dòng THAM CHIẾU vào `memory.md` trỏ thẳng tới path gốc trong repo, đúng
   format đã ghi ở khung comment Phần A: `- [tag nếu xác định được stack liên quan] Xem convention
   dự án tại <path> (tham chiếu trực tiếp, không copy nội dung)`. Khi review, agent tự đọc lại đúng
   file tại path đó lúc cần — không dựa vào bản copy có thể đã lỗi thời.
4. **Nếu phát hiện mâu thuẫn** — 2 nguồn nói khác nhau về cùng 1 vấn đề, HOẶC 1 nguồn tự mâu
   thuẫn/mơ hồ, HOẶC nguồn đó xung đột với baseline/template của plugin (`ALWAYS_RULE.md`/template):
   tự phán đoán cách reconcile hợp lý nhất (ưu tiên nguồn viết riêng cho convention/AI-agent như
   `CLAUDE.md`/`AGENTS.md` hơn `README.md` giới thiệu chung; ưu tiên nguồn cụ thể/chi tiết hơn nguồn
   chung chung). Ghi bản đã reconcile thành 1 lesson theo Phần E (nội dung do agent tự soạn để giải
   quyết mâu thuẫn, không copy nguyên văn 1 nguồn nào), nêu rõ nguồn nào mâu thuẫn với nguồn nào và
   vì sao chọn hướng này. Đây là trường hợp DUY NHẤT ghi lesson mà không cần xác nhận user (agent tự
   soạn trong lúc doctor).
5. Ghi nhận vào `meta.json`: `"doctored": true`, `"doctored_at": "<ngày giờ hiện tại>"`,
   `"project_docs_found": [<danh sách path đã tìm thấy ở bước 1, mảng rỗng nếu không có>]`.
6. `git -C notebooks/review add <repo>` + commit (local only) phần thay đổi này.

## Phần D — Schema `meta.json`

```json
{
  "bootstrapped": true,
  "doctored": true,
  "doctored_at": "2026-07-13T10:00:00Z",
  "project_docs_found": ["README.md", "CLAUDE.md"],
  "templates_copied": ["rails", "vue"]
}
```

`pr.md` coi repo là "đã thiết lập xong" khi `bootstrapped: true` VÀ `doctored: true` — 2 field này
chỉ cần đạt 1 LẦN DUY NHẤT. `templates_copied` thì KHÔNG nằm trong điều kiện "đã xong" đó — nó được
kiểm tra riêng, mỗi lần chạy, cho từng stack detect được trong PR (Phần B luôn có thể chạy lại một
phần nếu PR mới đụng tới stack chưa từng gặp ở repo này, kể cả khi `bootstrapped`/`doctored` đã
`true` từ lâu).

## Phần E — Ghi 1 lesson vào memory

Quy trình mechanical dùng chung cho: đồng thuận phát hiện ở Bước 5 của `pr.md`, góp ý convention
user phát biểu trong chat (Bước 9 của `pr.md`), và mâu thuẫn reconcile ở Phần C. Gate xác nhận user
do nơi gọi xử lý (Bước 5 / Bước 9 hỏi trước; Phần C không cần hỏi) — Phần E chỉ mô tả thao tác ghi.

1. Tạo `notebooks/review/<repo>/memories/<lesson-slug>.md` (slug kebab-case ngắn gọn, không
   dùng số thứ tự vô nghĩa). Nội dung tối thiểu: mô tả convention; ví dụ code trước/sau (nếu có);
   tag stack; ngày ghi nhận; nguồn (link PR liên quan nếu có).
2. Thêm 1 dòng vào index `notebooks/review/<repo>/memory.md`, format:
   `- [tag-stack] Mô tả ngắn gọn -> memories/<lesson-slug>.md` (nhiều tag nếu áp dụng nhiều stack).
3. `git -C notebooks/review add <repo>` + commit (local only, không push; nếu commit lỗi thiếu
   `user.name`/`user.email`, dùng cờ `-c` như Phần A).

## Khi user yêu cầu "doctor lại" / "quét lại convention dự án"

Sửa `doctored` trong `meta.json` thành `false` (hoặc xoá hẳn field đó) rồi thực hiện lại Phần C.
Có thể làm ngay trong chat, không cần đợi lần `/review:pr` kế tiếp.
