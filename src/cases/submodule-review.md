# Submodule review — review PR submodule khi phát hiện bump

Không phải slash command (nằm ngoài `commands/`); `commands/review-pr.md` nạp file này bằng `Read` CHỈ khi
(Bước 1 mục 5) `meta.json.has_submodules == true` VÀ "Diff đầy đủ" của PR chính chứa dòng
`Subproject commit` (submodule pointer đổi). Repo không có `.gitmodules` → `has_submodules` luôn
`false` → KHÔNG BAO GIỜ đọc file này.

Tới đây, code PR chính đã checkout xong trong 1 worktree ephemeral (`review-pr.md` Bước 1 mục 1-2), và
`git submodule update --init --recursive` đã chạy VÔ ĐIỀU KIỆN trên worktree đó (Bước 1 mục 4) —
mọi thư mục submodule (kể cả submodule không đổi trong PR này) đã sẵn sàng trên đĩa tại
`<worktree>/<submodule-path>/`. File này KHÔNG tạo worktree thứ 2 — chỉ tái dùng đúng thư mục đó.

Nếu diff có NHIỀU submodule bump trong CÙNG 1 PR chính, lặp lại toàn bộ quy trình A→F dưới đây cho
TỪNG submodule path phát hiện được (hỏi link riêng cho từng cái nếu cần), output tách riêng từng
phần theo Bước "Trình bày output" cuối file.

## Bước A — Xác định path submodule đã bump

Trong "Diff đầy đủ" (đã lấy 1 lần ở block Ngữ cảnh của `review-pr.md`, không fetch lại), tìm đoạn dạng:

```
diff --git a/<path> b/<path>
index <old-sha>..<new-sha> 160000
--- a/<path>
+++ b/<path>
@@ -1 +1 @@
-Subproject commit <old-sha>
+Subproject commit <new-sha>
```

`<path>` ngay sau `diff --git a/` là đường dẫn submodule trong repo chính, vd `vendor/mylib`. Dùng
lại giá trị này ở các bước dưới dưới dạng `<submodule-path>`.

## Bước B — Lấy link PR submodule

Tìm trong `body` (description) của PR CHÍNH đã lấy ở block Ngữ cảnh của `review-pr.md` xem có link PR
GitHub nào trỏ tới đúng repo submodule không (pattern `https://github.com/<owner>/<repo>/pull/<number>`
với `<owner>/<repo>` KHÁC owner/repo của PR chính).

- **Tìm thấy** → dùng link đó, parse ra `<owner-submodule>/<repo-submodule>/<n-submodule>` (cùng
  cách parse owner/repo/pull_number đã dùng cho PR chính ở `review-pr.md`).
- **KHÔNG tìm thấy** → HỎI user ngay trong chat, nêu rõ path submodule đã bump (Bước A) để user dễ
  xác định đúng PR nào cần link. KHÔNG tự đoán hay bỏ qua submodule này — dừng lại chờ user cung cấp
  link trước khi tiếp tục Bước C.

## Bước C — Checkout code PR submodule

TÁI DÙNG đúng thư mục submodule đã có sẵn trong worktree (từ `git submodule update --init --recursive`
ở `review-pr.md` Bước 1 mục 4) — KHÔNG gọi `git worktree add` lần nữa cho submodule:

```bash
(cd "<worktree>/<submodule-path>" && gh pr checkout <n-submodule> -R "<owner-submodule>/<repo-submodule>")
```

Cùng ngoại lệ "cấm `cd`" đã nêu ở `review-pr.md` Bước 1 mục 2 — subshell neo cứng đúng thư mục con này
trong worktree do chính lệnh quản lý, không đổi cwd của phiên chính.

## Bước D — Lấy ngữ cảnh riêng cho PR submodule

Tương tự block "Ngữ cảnh" của `review-pr.md` nhưng nhắm vào PR submodule — chạy các lệnh sau qua tool
`Bash` thật (không phải cơ chế `!`...`` — file này được `Read` giữa phiên, không phải frontmatter):

- `gh pr view "<link PR submodule>" -R "<owner-submodule>/<repo-submodule>" --json number,title,body,author,baseRefName,headRefName`
- `gh pr view "<link PR submodule>" -R "<owner-submodule>/<repo-submodule>" --json headRefOid --jq .headRefOid`
- `gh pr diff "<link PR submodule>" -R "<owner-submodule>/<repo-submodule>" --name-only`
- `gh pr diff "<link PR submodule>" -R "<owner-submodule>/<repo-submodule>"`
- `gh api repos/<owner-submodule>/<repo-submodule>/pulls/<n-submodule>/comments` (dùng ở Bước E cho
  re-review detection của CHÍNH PR submodule — response rỗng không phải lỗi)

## Bước E — Review PR submodule đầy đủ

Áp dụng lại đúng Bước 2 → Bước 8 của `review-pr.md` cho diff submodule vừa lấy ở Bước D, với 2 khác biệt
duy nhất:

- Stack detect riêng theo `stack-detection.md`, áp cho các file trong diff submodule (độc lập với
  stack detect của PR chính).
- Memory/template dùng CHUNG thư mục của repo CHÍNH — `notebooks/review/<repo>/` (repo = tên đã
  parse từ PR URL gốc ở đầu `review-pr.md`). TUYỆT ĐỐI KHÔNG tạo `notebooks/review/<repo-submodule>/`
  riêng — bootstrap/doctor/`meta.json` chỉ có 1 bộ duy nhất cho repo chính, kể cả khi review PR
  submodule. Bước 4 (đảm bảo local template) vẫn kiểm `templates_copied` trong CHÍNH `meta.json` đó
  — stack submodule chưa có template local thì copy/tự soạn như bình thường, lưu vào
  `notebooks/review/<repo>/templates/`.

Bước 6 (re-review detection) của phần này dùng data đã fetch riêng ở Bước D (comments của CHÍNH PR
submodule, không phải comments của PR chính).

## Bước F — Post kết quả PR submodule (1 lần POST riêng)

Đúng 1 lần gọi `gh api -X POST repos/<owner-submodule>/<repo-submodule>/pulls/<n-submodule>/reviews`,
theo đúng schema/quy tắc Bước 9 của `review-pr.md` (payload `body`/`commit_id`/`comments[]`, xử lý lỗi 422,
verify sau post) — chỉ khác chỗ:

- `commit_id` = `headRefOid` của PR SUBMODULE (lấy ở Bước D), không phải của PR chính.
- `auto_submit_review`/`auto_resolve_fixed_findings` đọc từ CÙNG `meta.json` của repo chính (đã đọc
  ở Bước 3 của `review-pr.md`) — không hỏi lại, không có bộ cấu hình riêng cho submodule.

Đây là lần POST RIÊNG, KHÔNG tính vào ràng buộc "1 lần POST duy nhất" của Bước 9 `review-pr.md` (đó là ràng
buộc cho PR CHÍNH) — nhưng bản thân lần POST này cũng CHỈ ĐÚNG 1 LẦN cho PR submodule, không lặp.

## Trình bày output

Vì đây thực chất là 2 review được post lên 2 PR khác nhau (có thể 2 repo khác nhau), hiển thị trong
chat VÀ trong nội dung tóm tắt cuối cùng TÁCH RÕ 2 phần, gọi tên bằng SỐ PR — KHÔNG dùng nhãn tương
đối "PR chính"/"PR phụ":

```
### Bên PR #<n-chính> (<owner>/<repo>)
(tóm tắt kết quả Bước 8-9 của review-pr.md cho PR chính, kèm link)

### Bên PR #<n-submodule> (<owner-submodule>/<repo-submodule>)
(tóm tắt kết quả Bước E-F ở trên cho PR submodule, kèm link)
```

## Giới hạn đã biết (chấp nhận, không xử lý)

- **KHÔNG xử lý submodule lồng submodule (2 tầng).** Nếu diff của CHÍNH PR submodule (lấy ở Bước D)
  lại chứa dòng `Subproject commit` — tức submodule này có submodule riêng của nó — DỪNG LẠI, không
  đệ quy tiếp vào tầng thứ 2. Chỉ ghi chú trong phần "Review PR submodule" ở output rằng đã phát
  hiện submodule lồng nhau, ngoài phạm vi hỗ trợ hiện tại, không review phần đó.
- **Không cần cơ chế auth riêng.** `gh` CLI thường dùng chung 1 tài khoản cho cả repo chính lẫn
  submodule. Nếu 1 lệnh `gh` ở trên lỗi vì tài khoản hiện tại thiếu quyền trên repo submodule (vd
  private repo khác tổ chức) — xử lý như lỗi thông thường ở Bước F (đọc lỗi, báo lại cho user),
  KHÔNG tự ý thử thêm cách khác hay chuyển tài khoản.
