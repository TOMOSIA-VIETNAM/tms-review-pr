---
allowed-tools: Bash(gh:*), Bash(git:*), Read, Write, Edit
argument-hint: <GitHub PR URL>
description: Review 1 PR GitHub đa stack, học convention riêng theo repo qua memory, post kết quả qua gh api.
---

## Bước 0 — Validate ARGUMENTS

Nếu `ARGUMENTS` (hiển thị ở cuối trang này) bị trống hoặc KHÔNG match dạng
`https://github.com/<owner>/<repo>/pull/<number>` (regex tham khảo:
`^https://github\.com/[^/]+/[^/]+/pull/[0-9]+$`), chỉ xuất đúng thông báo lỗi sau và DỪNG LẠI,
không thực hiện bất kỳ bước nào khác bên dưới (kể cả khi các lệnh `gh` trong block "Ngữ cảnh" đã
tự chạy do cơ chế substitution của Claude Code — nếu ARGUMENTS không hợp lệ thì output của các lệnh
đó vô nghĩa/lỗi, bỏ qua hoàn toàn, không dùng để suy luận tiếp):

```
❌ Lỗi: Chưa cung cấp URL PR.
Cách dùng: /review:pr <GitHub PR URL>
Ví dụ: /review:pr https://github.com/org/repo/pull/123
```

Chỉ tiến hành các bước 1-9 bên dưới nếu `ARGUMENTS` là URL GitHub PR hợp lệ.

## Ngữ cảnh

- Thông tin PR: !`gh pr view $ARGUMENTS --json number,title,author,baseRefName,headRefName 2>/dev/null`
- Head commit sha (bắt buộc dùng ở Bước 8 khi post review): !`gh pr view $ARGUMENTS --json headRefOid --jq .headRefOid 2>/dev/null`
- Danh sách file thay đổi: !`gh pr diff $ARGUMENTS --name-only 2>/dev/null`
- Diff đầy đủ: !`gh pr diff $ARGUMENTS 2>/dev/null`
- Commits: !`gh pr view $ARGUMENTS --json commits --jq '.commits[].messageHeadline' 2>/dev/null`
- Review comments cũ của chính PR này (dùng ở Bước 5 — response rỗng là bình thường, không phải lỗi): !`gh api repos/$(echo $ARGUMENTS | sed -E 's#https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+).*#\1/\2#')/pulls/$(echo $ARGUMENTS | sed -E 's#.*/pull/([0-9]+).*#\1#')/comments 2>/dev/null`

**Parse `{owner}/{repo}/{pull_number}` từ ARGUMENTS:** URL dạng
`https://github.com/<owner>/<repo>/pull/<number>` → `owner` = segment sau `github.com/`, `repo` =
segment kế tiếp, `pull_number` = số sau `/pull/`. Ví dụ `.../acme/api/pull/42` → `owner=acme`,
`repo=api`, `pull_number=42`. Dùng lại cách parse này ở Bước 8 khi gọi `gh api`.

`short_name` (dùng từ Bước 2 trở đi) = segment `<repo>` (KHÔNG kèm owner), vd `api`. Hai repo khác
owner nhưng trùng tên repo sẽ dùng chung 1 thư mục memory — giới hạn đã biết, giữ nguyên
`short_name = <repo>`, không tự đổi schema sang `owner-repo`.

## Bước 1 — Detect stack cho từng file trong diff

Với MỖI file trong "Danh sách file thay đổi", xác định (các) stack áp dụng theo bảng mapping +
overlay rule trong `stack-detection.md` (đọc bằng `Read` tại
`"${CLAUDE_PLUGIN_ROOT}"/stack-detection.md`). Giữ danh sách cặp `(file, [stack áp dụng])` — dùng
lại ở Bước 3 (đảm bảo local template), Bước 4 (nạp template), Bước 5 và Bước 6 (áp đúng tiêu chí
cho đúng file).

## Bước 2 — Thiết lập lần đầu cho repo (nếu cần)

`Read` thử `notebooks/review/<short_name>/meta.json` tại pwd (root repo đang review, KHÔNG PHẢI
root plugin).

- **File không tồn tại, HOẶC `bootstrapped`/`doctored` chưa cùng `true`**: đọc
  `"${CLAUDE_PLUGIN_ROOT}"/setup-flow.md` và làm theo Phần A + Phần C (Phần B — copy template theo
  stack — xử lý ở Bước 3).
- **`bootstrapped: true` VÀ `doctored: true`**: bỏ qua bước này, KHÔNG đọc `setup-flow.md`, sang
  thẳng Bước 3.

Idempotent nghiêm ngặt: từ lần chạy thứ 2 trở đi (đã bootstrap + doctor), lệnh KHÔNG đụng bất kỳ
file nào trong `notebooks/review/` ngoài phần thêm ở Bước 3 (template stack chưa từng gặp) hoặc
Bước 5 (lesson, có xác nhận của user).

## Bước 3 — Đảm bảo có local template cho (các) stack của PR này

Với MỖI stack đã detect ở Bước 1: kiểm mảng `templates_copied` trong
`notebooks/review/<short_name>/meta.json`.

- **Chưa có** → đọc `"${CLAUDE_PLUGIN_ROOT}"/setup-flow.md` Phần B (nếu chưa đọc ở Bước 2) và làm
  theo.
- **Đã có** → dùng thẳng bản local `notebooks/review/<short_name>/templates/<stack>.md`.

Bước này CHẠY MỖI LẦN (tách khỏi gate "đã setup xong" của Bước 2): stack mới có thể xuất hiện ở PR
sau dù bootstrap/doctor đã xong từ trước.

## Bước 4 — Nạp rule + memory + template

1. Đọc `"${CLAUDE_PLUGIN_ROOT}"/ALWAYS_RULE.md` — rule chung của PLUGIN (áp dụng mọi repo), khác
   với convention riêng của repo đang review (nằm ở `notebooks/review/<short_name>/`). Lấy từ đây:
   ngôn ngữ output (default **English** nếu file không ghi rõ khác) + rule cứng khác nếu có + khung
   6 mục **baseline** (tiêu chí chung mọi stack — mục 1,2,3,4,6; mục 5 "Đặc thù framework/language"
   không có baseline, lấy 100% từ template ở mục 3 dưới). Danh sách tiêu chí là GỢI Ý MINH HỌA,
   không phải checklist đóng — giữ tinh thần đó khi review ở Bước 6.
2. Đọc `notebooks/review/<short_name>/memory.md` (index) + đọc từng `memories/<lesson>.md` được
   trỏ tới bởi các dòng có tag stack TRÙNG với (các) stack đã detect ở Bước 1 (bỏ qua lesson của
   stack không xuất hiện trong PR). Dòng dạng THAM CHIẾU (từ doctor, không phải lesson tự học) →
   đọc luôn nội dung tại path được trỏ tới trong repo đang review, coi là tiêu chí bổ sung có giá
   trị ngang lesson thường.
3. Đọc (các) file **LOCAL** trong `notebooks/review/<short_name>/templates/` tương ứng kết quả
   detect ở Bước 1 (gồm cả overlay nếu có, vd đọc cả `python.md` lẫn `lambda-common.md` khi PR có
   lambda). KHÔNG đọc trực tiếp từ `${CLAUDE_PLUGIN_ROOT}/templates/` — bản local mới là bản có
   hiệu lực cho repo này (có thể đã được team chỉnh sửa).

## Bước 5 — Đọc lại review comments cũ của chính PR này (re-review detection)

Dữ liệu đã lấy sẵn ở block "Ngữ cảnh" (`gh api .../pulls/{pull_number}/comments`) — luôn có mặt mỗi
lần chạy, kể cả PR mới toanh (response rỗng thì bỏ qua, KHÔNG coi là lỗi).

- Chỉ xét reply chain (`in_reply_to_id`) của CHÍNH PR đang review này — không quét PR khác.
- Đọc hiểu nội dung comment + các reply để phán đoán dev và reviewer đã ĐỒNG THUẬN về 1 convention
  nào chưa. **KHÔNG dựa vào trạng thái `resolved`** để quyết định — resolved chỉ là UI state, không
  phản ánh có đồng thuận thật hay không.
- Phát hiện đồng thuận → **KHÔNG tự ghi ngay**. Hiển thị đề xuất trong chat: nội dung lesson dự
  kiến (mô tả convention, ví dụ rút ra từ thread nếu có) + tag stack dự kiến. CHỜ user xác nhận
  (yes / no / sửa lại nội dung).
- CHỈ SAU KHI user đồng ý: ghi lesson theo Phần E của `"${CLAUDE_PLUGIN_ROOT}"/setup-flow.md` (đọc
  bằng `Read` nếu chưa nạp file này ở Bước 2/3).

## Bước 6 — Thực hiện review theo 6 mục

Áp dụng khung 6 mục sau, hợp nhất từ 2 nguồn đã nạp ở Bước 4: **baseline** trong `ALWAYS_RULE.md`
(mục 1,2,3,4,6 — áp dụng mọi PR bất kể stack) + **tiêu chí đặc thù** trong (các) template LOCAL của
stack tương ứng (bổ sung cho mục 1,2,3,4,6, và toàn bộ mục 5 vốn không có baseline):

1. Lỗi & vấn đề logic
2. Bảo mật
3. Hiệu suất
4. Chất lượng code
5. Đặc thù framework/ngôn ngữ (100% từ template stack tương ứng)
6. Khả năng bảo trì & dễ đọc

**Toàn bộ tiêu chí trên (baseline lẫn đặc thù) là GỢI Ý MINH HỌA để định hướng, KHÔNG PHẢI checklist
đóng/đầy đủ** — chủ động phát hiện thêm vấn đề khác ngoài danh sách nếu có, không tự giới hạn bản
thân chỉ tìm đúng những gì đã liệt kê trong `ALWAYS_RULE.md`/template.

Áp dụng thêm các lesson và tham chiếu convention dự án liên quan đã nạp từ `memory.md`/`memories/`
(Bước 4) như **tiêu chí bổ sung** cho 6 mục trên. Nếu 1 lesson/tham chiếu trong memory MÂU THUẪN với
`ALWAYS_RULE.md` → `ALWAYS_RULE.md` LUÔN THẮNG, bỏ qua phần mâu thuẫn đó.

Với MỖI finding phát hiện được, tự quyết định đây là finding cấp **FILE** (ví dụ minh hoạ, không
phải danh sách cứng: file thừa/không cần thiết, sai vị trí trong cấu trúc thư mục, thiếu 1 file bắt
buộc phải đi kèm...) hay cấp **LINE** (bug/logic/security/performance tại 1 đoạn code cụ thể). Đây
là phán đoán theo ngữ cảnh của agent lúc review, KHÔNG dùng enum/danh sách cố định để phân loại.

## Bước 7 — Định dạng kết quả

Giữ khung định dạng sau (ngôn ngữ lấy theo `ALWAYS_RULE.md` đã đọc ở Bước 4, default **English**
nếu file đó không ghi rõ khác):

```
### Nhận xét tổng quan
(2-3 câu đánh giá chung)

#### 🔴 Bắt buộc sửa (N vấn đề)
#### 🟡 Nên sửa (N vấn đề)
#### 🟢 Đề xuất (N vấn đề)
```

Đếm đúng số lượng finding thực tế theo từng mức. Nếu 1 mức không có finding nào, ghi rõ "Không có
vấn đề" (hoặc bản dịch tương ứng theo ngôn ngữ output đã chọn) thay vì bỏ trống mục đó.

## Bước 8 — Post review (ĐÚNG 1 LẦN GỌI API DUY NHẤT)

Không hardcode tên người review vào nội dung — `gh api` tự đăng dưới tài khoản `gh auth` đang
active trên máy chạy lệnh, không cần thêm field tên người review vào payload.

Dùng `owner`/`repo`/`pull_number` đã parse ở block "Ngữ cảnh", và `headRefOid` đã lấy sẵn ở đó làm
`commit_id`. `comments[]` PHẢI gồm **TẤT CẢ** finding ở **CẢ 3 MỨC** 🔴🟡🟢 từ Bước 6/7 — KHÔNG lọc
bớt mức nào. Vì JSON có thể lớn/phức tạp (nhiều phần tử `comments`), dùng `--input -` với heredoc
thay vì nhiều cờ `-f`/`-F` riêng lẻ, để tránh lỗi escaping qua command-line flags:

```bash
gh api -X POST repos/{owner}/{repo}/pulls/{pull_number}/reviews \
  --input - <<EOF
{
  "body": "<nội dung ### Nhận xét tổng quan + đếm 🔴🟡🟢 từ Bước 7>",
  "commit_id": "<headRefOid lấy từ block Ngữ cảnh>",
  "event": "COMMENT",
  "comments": [
    {"path": "<file>", "line": <số dòng>, "side": "RIGHT", "body": "<nội dung finding cấp LINE>"},
    {"path": "<file>", "body": "<nội dung finding cấp FILE, KHÔNG có field line>"}
  ]
}
EOF
```

- Finding cấp **LINE**: object gồm `path` + `line` + `"side": "RIGHT"` + `body`.
- Finding cấp **FILE**: object chỉ gồm `path` + `body`, KHÔNG có `line`/`side`.
- Thay `{owner}`, `{repo}`, `{pull_number}` bằng giá trị thật đã parse. Đây là lần gọi `gh api`
  POST DUY NHẤT của cả lệnh — không gọi thêm lần POST review nào khác.

## Bước 9 — Hành vi chung khi plugin "review" active (ngoài luồng `/review:pr`)

Áp dụng bất cứ khi nào plugin này active trong session, không riêng lúc chạy `/review:pr`:

- User trò chuyện bình thường (KHÔNG chạy `/review:pr`) và tự phát biểu một sửa đổi/góp ý convention
  cho repo đang có `notebooks/review/<short_name>/` (từ lần `/review:pr` trước) → KHÔNG tự ghi ngay.
  Hỏi xác nhận trước (như Bước 5); CHỈ SAU KHI user đồng ý mới ghi lesson theo Phần E của
  `"${CLAUDE_PLUGIN_ROOT}"/setup-flow.md`.
- User yêu cầu "doctor lại"/"quét lại convention dự án" → set `doctored: false` trong `meta.json`
  rồi thực hiện lại Phần C của `"${CLAUDE_PLUGIN_ROOT}"/setup-flow.md`, không cần đợi lần
  `/review:pr` kế tiếp.

---

ARGUMENTS: $ARGUMENTS
