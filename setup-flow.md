# Setup flow — thiết lập lần đầu cho 1 repo

File này KHÔNG phải slash command (không đặt trong `commands/`) — chỉ được `commands/pr.md` đọc
bằng tool `Read` khi cần, và CHỈ khi cần (repo chưa từng thiết lập xong). Nếu repo đã thiết lập
xong, `pr.md` không đọc file này nữa, nội dung dưới đây không tốn context của lần review đó.

Toàn bộ thao tác dưới đây thao tác tại **root của repo đang được review** (pwd), KHÔNG PHẢI root
của plugin. Chỉ dùng `Read`/`Write`/`Edit`/`git` (qua Bash) — không dùng `mkdir`/`test`/`ls`/`echo`.

## Phần A — Bootstrap `notebooks/review/<short_name>/`

1. Dùng `Write` tạo `notebooks/review/<short_name>/memory.md` — khung index RỖNG:
   ```
   <!-- Index các bài học convention đã ghi nhận cho repo này. Mỗi dòng 1 lesson, format:
        - [tag-stack] Mô tả ngắn gọn lesson -> memories/<slug>.md
        Có thể gắn nhiều tag nếu lesson áp dụng nhiều stack, vd [rails][ruby].
        Một dòng cũng có thể là THAM CHIẾU tới convention có sẵn của dự án (xem Phần C — doctor)
        thay vì 1 lesson tự học, format: - [tag-stack] Xem convention dự án tại <path trong repo>
        (tham chiếu trực tiếp, không copy nội dung). -->
   ```
2. Dùng `Write` tạo `notebooks/review/<short_name>/memories/.gitkeep` (rỗng) — chỉ để vật lý hoá
   thư mục `memories/` (git không track thư mục rỗng).
3. Dùng `Write` tạo `notebooks/review/<short_name>/templates/.gitkeep` (rỗng) — thư mục này sẽ chứa
   bản LOCAL copy của (các) template stack đang dùng trong repo (xem Phần B), tạo sẵn thư mục trước.
4. Kiểm `notebooks/review/.git` đã tồn tại chưa (thử `Read` file `notebooks/review/.git/HEAD`):
   - **CHƯA tồn tại** → `git init notebooks/review` — 1 git repo DUY NHẤT, nested, độc lập hoàn
     toàn với git của repo chính đang review, bao trùm MỌI `<short_name>/` sẽ có sau này. TUYỆT ĐỐI
     KHÔNG set remote, KHÔNG push — chỉ auto-commit local. Sau đó
     `git -C notebooks/review add <short_name>` rồi
     `git -C notebooks/review commit -m "chore: init review memory for <short_name>"`
     (nếu môi trường chưa cấu hình `user.name`/`user.email` global và commit báo lỗi, dùng cờ
     `-c user.name="review-plugin" -c user.email="review-plugin@local"` CHỈ cho lần commit này,
     KHÔNG set global config).
   - **ĐÃ tồn tại** (đã từng review 1 repo khác trên cùng máy) → KHÔNG init lại. Chỉ
     `git -C notebooks/review add <short_name>` rồi
     `git -C notebooks/review commit -m "chore: add review memory for <short_name>"`.
5. Kiểm `.gitignore` ở root repo đang review (dùng `Read` tại `./.gitignore`):
   - Tồn tại và CHƯA có dòng `notebooks/review/` → dùng `Edit` append thêm dòng đó.
   - Chưa có `.gitignore` → dùng `Write` tạo mới chỉ chứa đúng 1 dòng `notebooks/review/`.
6. Ghi nhận `"bootstrapped": true` vào `notebooks/review/<short_name>/meta.json` (tạo file nếu
   chưa có, giữ nguyên các field khác nếu file đã tồn tại từ trước — xem Phần D cho schema đầy đủ).

## Phần B — Copy/tạo local template cho (các) stack hiện có trong PR đang review

Với MỖI stack đã detect được ở Bước 1 của `pr.md` mà CHƯA có trong `templates_copied` (mảng trong
`meta.json`, xem Phần D):

1. Kiểm `${CLAUDE_PLUGIN_ROOT}/templates/<stack>.md` có tồn tại không (plugin có sẵn template cho
   stack này chưa).
   - **Có sẵn** → `Read` nội dung file đó, `Write` y nguyên nội dung ra
     `notebooks/review/<short_name>/templates/<stack>.md` (bản LOCAL, repo có thể tự chỉnh sửa
     riêng sau này mà không ảnh hưởng plugin dùng chung cho repo khác).
   - **CHƯA có sẵn** (plugin chưa cover stack này) → tự soạn 1 template MỚI theo đúng khung 6 mục
     (1.Lỗi&logic 2.Bảo mật 3.Hiệu suất 4.Chất lượng code 5.Đặc thù framework/ngôn ngữ 6.Bảo trì&dễ
     đọc — tham khảo cách các file trong `${CLAUDE_PLUGIN_ROOT}/templates/` đang viết để giữ văn
     phong/độ chi tiết nhất quán, và nhớ KHÔNG lặp lại tiêu chí đã có trong baseline của
     `ALWAYS_RULE.md`, chỉ viết phần đặc thù), lưu trực tiếp vào
     `notebooks/review/<short_name>/templates/<stack>.md`. Báo cho user biết trong chat là đã tự
     tạo template mới cho stack này (để user biết mà review lại nếu muốn), và gợi ý: nếu thấy hợp
     lý, user có thể tự copy file này vào `${CLAUDE_PLUGIN_ROOT}/templates/` để dùng chung cho mọi
     repo khác sau này — plugin KHÔNG tự động làm việc đó (tránh mutate file dùng chung từ 1 phiên
     review của 1 repo cụ thể).
2. Thêm `<stack>` vào mảng `templates_copied` trong `meta.json`.
3. `git -C notebooks/review add <short_name>` + commit (local only) phần thay đổi này.

Từ lúc này trở đi, `pr.md` đọc rule đặc thù stack từ bản LOCAL
(`notebooks/review/<short_name>/templates/<stack>.md`), KHÔNG đọc trực tiếp từ
`${CLAUDE_PLUGIN_ROOT}/templates/` nữa — bản local mới là bản có hiệu lực cho repo này.

## Phần C — Doctor: khám phá convention có sẵn của dự án

Mục tiêu: nếu dự án đang review đã tự định nghĩa convention/coding rule riêng ở đâu đó (README,
CLAUDE.md, AGENTS.md, docs/, wiki, cursor/copilot rules...), review phải THAM CHIẾU tới đúng nguồn
đó thay vì đoán mò hoặc áp đặt rule ngoài không phù hợp.

1. Kiểm tra sự tồn tại (tại root repo đang review) của các nguồn convention phổ biến: `README.md`,
   `CLAUDE.md`, `AGENTS.md`, thư mục `docs/`, thư mục `wiki/` (nếu có sẵn local), `.cursorrules`
   hoặc `.cursor/rules/`, `.github/copilot-instructions.md`. Bỏ qua nguồn nào không tồn tại, không
   coi là lỗi.
2. Với mỗi nguồn tồn tại, đọc phần nội dung liên quan tới coding convention/tiêu chí review (bỏ qua
   phần không liên quan như giới thiệu sản phẩm, hướng dẫn cài đặt/deploy).
3. **KHÔNG copy nội dung đã đọc vào memory.** Với mỗi nguồn có convention rõ ràng, không mâu thuẫn
   với gì khác, chỉ thêm 1 dòng THAM CHIẾU vào `memory.md` trỏ thẳng tới path gốc trong repo, đúng
   format đã ghi ở khung comment Phần A: `- [tag nếu xác định được stack liên quan] Xem convention
   dự án tại <path> (tham chiếu trực tiếp, không copy nội dung)`. Khi review, agent tự đọc lại đúng
   file tại path đó lúc cần — không dựa vào bản copy có thể đã lỗi thời.
4. **Nếu phát hiện mâu thuẫn** — 2 nguồn nói khác nhau về cùng 1 vấn đề, HOẶC 1 nguồn tự mâu
   thuẫn/mơ hồ không rõ áp dụng thế nào, HOẶC nguồn đó xung đột với baseline/template của chính
   plugin (`ALWAYS_RULE.md`/template): tự phán đoán cách reconcile hợp lý nhất (ưu tiên nguồn viết
   riêng cho convention/AI-agent như `CLAUDE.md`/`AGENTS.md` hơn `README.md` giới thiệu chung; ưu
   tiên nguồn cụ thể/chi tiết hơn nguồn chung chung). Viết bản đã reconcile này thành 1 lesson bình
   thường vào `notebooks/review/<short_name>/memories/<lesson-slug>.md` (nội dung DO AGENT TỰ SOẠN
   để giải quyết mâu thuẫn, không phải copy nguyên văn 1 nguồn nào), ghi rõ nguồn nào mâu thuẫn với
   nguồn nào và vì sao chọn hướng này + thêm 1 dòng vào index `memory.md`.
5. Ghi nhận vào `meta.json`: `"doctored": true`, `"doctored_at": "<ngày giờ hiện tại>"`,
   `"project_docs_found": [<danh sách path đã tìm thấy ở bước 1, mảng rỗng nếu không có>]`.
6. `git -C notebooks/review add <short_name>` + commit (local only) phần thay đổi này.

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

## Khi user yêu cầu "doctor lại" / "quét lại convention dự án"

Sửa `doctored` trong `meta.json` thành `false` (hoặc xoá hẳn field đó) rồi thực hiện lại Phần C.
Có thể làm ngay trong chat, không cần đợi lần `/review:pr` kế tiếp.
