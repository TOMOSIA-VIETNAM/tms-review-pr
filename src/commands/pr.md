---
allowed-tools: Bash(gh:*), Bash(git:*), Bash(cp:*), Bash(mkdir:*), Agent, Read, Write, Edit
argument-hint: <GitHub PR URL>
description: Review 1 PR GitHub đa stack, học convention riêng theo repo qua memory, post kết quả qua gh api.
---

## Bước 0 — Validate ARGUMENTS

Nhận diện PR bằng NĂNG LỰC, không máy móc theo 1 regex cứng: `ARGUMENTS` (hiển thị ở cuối trang
này) được coi là hợp lệ khi nó CHỨA 1 tham chiếu PR GitHub dạng
`github.com/<owner>/<repo>/pull/<number>`, BẤT KỂ có thêm phần đuôi nào theo sau (path như
`/changes`, `/files`, `/commits`; query string `?...`; fragment `#...`). Chỉ trích xuất đúng
`owner`/`repo`/`pull_number` từ phần khớp, BỎ QUA phần dư phía sau. Ví dụ đều hợp lệ:
`https://github.com/org/repo/pull/1415`, `.../pull/1415/changes`, `.../pull/1415/files?w=1`.

CHỈ khi `ARGUMENTS` bị trống HOẶC thực sự KHÔNG tìm thấy pattern `github.com/<owner>/<repo>/pull/<number>`
ở bất kỳ đâu trong chuỗi, mới xuất đúng thông báo lỗi sau và DỪNG LẠI, không thực hiện bất kỳ bước
nào khác bên dưới (kể cả khi các lệnh `gh` trong block "Ngữ cảnh" đã tự chạy do cơ chế substitution
của Claude Code — nếu ARGUMENTS không hợp lệ thì output của các lệnh đó vô nghĩa/lỗi, bỏ qua hoàn
toàn, không dùng để suy luận tiếp):

```
❌ Lỗi: Chưa cung cấp URL PR.
Cách dùng: /review:pr <GitHub PR URL>
Ví dụ: /review:pr https://github.com/org/repo/pull/123
```

Chỉ tiến hành các bước 1-9 bên dưới nếu `ARGUMENTS` chứa 1 tham chiếu PR GitHub hợp lệ.

## Ngữ cảnh

Các lệnh dưới đây trước tiên trích PR URL "sạch" (canonical `https://github.com/<owner>/<repo>/pull/<number>`,
CẮT BỎ mọi phần đuôi như `/changes`/`/files`/query/fragment) từ `$ARGUMENTS` bằng
`grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+'`, để `gh` không bị lỗi khi URL có đuôi:

- Thông tin PR (bao gồm `body` = description — dùng ở Bước 6 để đánh giá title/description có thể
  hiện rõ business không): !`gh pr view "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" --json number,title,body,author,baseRefName,headRefName 2>/dev/null`
- Head commit sha (bắt buộc dùng ở Bước 8 khi post review): !`gh pr view "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" --json headRefOid --jq .headRefOid 2>/dev/null`
- Danh sách file thay đổi: !`gh pr diff "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" --name-only 2>/dev/null`
- Diff đầy đủ: !`gh pr diff "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" 2>/dev/null`
- Commits: !`gh pr view "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" --json commits --jq '.commits[].messageHeadline' 2>/dev/null`
- Review comments cũ của chính PR này (dùng ở Bước 5 — response rỗng là bình thường, không phải lỗi): !`gh api repos/$(echo $ARGUMENTS | sed -E 's#.*github\.com/([^/]+)/([^/]+)/pull/([0-9]+).*#\1/\2#')/pulls/$(echo $ARGUMENTS | sed -E 's#.*/pull/([0-9]+).*#\1#')/comments 2>/dev/null`

**Parse `{owner}/{repo}/{pull_number}` từ ARGUMENTS:** từ phần khớp
`github.com/<owner>/<repo>/pull/<number>` → `owner` = segment sau `github.com/`, `repo` = segment
kế tiếp, `pull_number` = số sau `/pull/` (bỏ qua mọi phần đuôi sau số này). Ví dụ
`.../acme/api/pull/42/files` → `owner=acme`, `repo=api`, `pull_number=42`. Dùng lại cách parse này
ở Bước 8 khi gọi `gh api`.

**Tên repo (`repo name`, dùng làm tên thư mục memory từ Bước 2 trở đi) = CHÍNH segment `<repo>` cắt
ra từ PR URL ở trên** (KHÔNG kèm owner), vd `api`. Đây là ĐỊNH NGHĨA DUY NHẤT, không có nhánh rẽ
nào khác: TUYỆT ĐỐI KHÔNG suy tên repo từ basename của pwd, của thư mục con, của git remote, hay
bất kỳ nguồn nào ngoài PR URL. Nhờ vậy 2 PR khác nhau của CÙNG 1 repo luôn map về CÙNG 1 thư mục
`notebooks/review/<repo>/`. (Hai repo khác owner nhưng trùng tên repo sẽ dùng chung 1 thư mục
memory — giới hạn đã biết, giữ nguyên `repo name = <repo>`, không tự đổi schema sang `owner-repo`.)

**Mọi thao tác filesystem PHẢI thực hiện tại ĐÚNG pwd hiện tại của phiên** (thư mục mà lệnh
`/review:pr` được gọi). TUYỆT ĐỐI KHÔNG `cd` sang thư mục khác, KHÔNG tự dò tìm "git root" hay
"thư mục repo thật sự", KHÔNG dùng basename của bất kỳ thư mục nào để suy ra đường dẫn hay tên.
Đứng ở đâu tạo ở đó — không ngoại lệ, không tự "thông minh" điều hướng. Trước khi tạo/ghi bất kỳ
file nào dưới `notebooks/review/...`, hiển thị rõ trong chat: pwd đang đứng + tên repo đã parse từ
URL, để dễ phát hiện sai sót.

## Bước 1 — Detect stack cho từng file trong diff

Với MỖI file trong "Danh sách file thay đổi", xác định (các) stack áp dụng theo bảng mapping +
overlay rule trong `stack-detection.md` (đọc bằng `Read` tại
`"${CLAUDE_PLUGIN_ROOT}"/src/stack-detection.md`). Giữ danh sách cặp `(file, [stack áp dụng])` — dùng
lại ở Bước 3 (đảm bảo local template), Bước 4 (nạp template), Bước 5 và Bước 6 (áp đúng tiêu chí
cho đúng file).

## Bước 2 — Thiết lập lần đầu cho repo (nếu cần)

`Read` thử `notebooks/review/<repo>/meta.json` tại pwd (root repo đang review, KHÔNG PHẢI
root plugin).

- **File không tồn tại, HOẶC `bootstrapped`/`doctored` chưa cùng `true`**: đọc
  `"${CLAUDE_PLUGIN_ROOT}"/src/setup-flow.md` và làm theo Phần A + Phần C (Phần B — copy template theo
  stack — xử lý ở Bước 3).
- **`bootstrapped: true` VÀ `doctored: true`**: bỏ qua bước này, KHÔNG đọc `setup-flow.md`, sang
  thẳng Bước 3.

Idempotent nghiêm ngặt: từ lần chạy thứ 2 trở đi (đã bootstrap + doctor), lệnh KHÔNG đụng bất kỳ
file nào trong `notebooks/review/` ngoài phần thêm ở Bước 3 (template stack chưa từng gặp) hoặc
Bước 5 (lesson, có xác nhận của user).

## Bước 3 — Đảm bảo có local template cho (các) stack của PR này

Với MỖI stack đã detect ở Bước 1: kiểm mảng `templates_copied` trong
`notebooks/review/<repo>/meta.json`.

- **Chưa có** → đọc `"${CLAUDE_PLUGIN_ROOT}"/src/setup-flow.md` Phần B (nếu chưa đọc ở Bước 2) và làm
  theo.
- **Đã có** → dùng thẳng bản local `notebooks/review/<repo>/templates/<stack>.md`.

Bước này CHẠY MỖI LẦN (tách khỏi gate "đã setup xong" của Bước 2): stack mới có thể xuất hiện ở PR
sau dù bootstrap/doctor đã xong từ trước.

## Bước 4 — Nạp rule + memory + template

1. Đọc bản **LOCAL** `notebooks/review/<repo>/ALWAYS_RULE.md` (được copy từ plugin lúc bootstrap —
   xem Phần A của `setup-flow.md`; team có thể đã tự chỉnh sửa bản local này cho dự án). KHÔNG đọc
   trực tiếp `${CLAUDE_PLUGIN_ROOT}/src/ALWAYS_RULE.md` — bản trong plugin chỉ là "seed" mặc định lúc
   bootstrap, bản local mới là bản có hiệu lực cho repo này (giống cách mục 3 dưới đọc template
   LOCAL thay vì template global). Đây là rule chung áp dụng mọi repo, khác với convention riêng của
   repo đang review (lesson trong `notebooks/review/<repo>/memory.md`). Lấy từ đây:
   ngôn ngữ output (default **English** nếu file không ghi rõ khác) + rule cứng khác nếu có + khung
   6 mục **baseline** (tiêu chí chung mọi stack — mục 1,2,3,4,6; mục 5 "Đặc thù framework/language"
   không có baseline, lấy 100% từ template ở mục 3 dưới). Danh sách tiêu chí là GỢI Ý MINH HỌA,
   không phải checklist đóng — giữ tinh thần đó khi review ở Bước 6.
2. Đọc `notebooks/review/<repo>/memory.md` (index) + đọc từng `memories/<lesson>.md` được
   trỏ tới bởi các dòng có tag stack TRÙNG với (các) stack đã detect ở Bước 1 (bỏ qua lesson của
   stack không xuất hiện trong PR). Dòng dạng THAM CHIẾU (từ doctor, không phải lesson tự học) →
   đọc luôn nội dung tại path được trỏ tới trong repo đang review, coi là tiêu chí bổ sung có giá
   trị ngang lesson thường.
3. Đọc (các) file **LOCAL** trong `notebooks/review/<repo>/templates/` tương ứng kết quả
   detect ở Bước 1 (gồm cả overlay nếu có, vd đọc cả `python.md` lẫn `lambda-common.md` khi PR có
   lambda). KHÔNG đọc trực tiếp từ `${CLAUDE_PLUGIN_ROOT}/src/templates/` — bản local mới là bản có
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
- CHỈ SAU KHI user đồng ý: ghi lesson theo Phần E của `"${CLAUDE_PLUGIN_ROOT}"/src/setup-flow.md` (đọc
  bằng `Read` nếu chưa nạp file này ở Bước 2/3).

## Bước 6 — Thực hiện review theo 6 mục

**Kiểm tra title & description PR trước (cấp độ tổng quan, không phải finding cấp file/line):**

- Đọc `title` + `body` (description) của PR đã lấy ở block Ngữ cảnh. Đánh giá: title + description
  có thể hiện rõ được BUSINESS/mục đích của thay đổi không (người đọc hiểu PR làm gì, giải quyết vấn
  đề gì, KHÔNG cần đọc code mới hiểu)? Nếu mập mờ/thiếu (title chung chung kiểu "fix bug", "update",
  description rỗng hoặc không giải thích được lý do thay đổi) → ghi rõ trong phần tổng quan ở Bước 7
  (ưu tiên cao, nêu ngay đầu đoạn) rằng title/description chưa thể hiện đủ business, ĐỀ NGHỊ dev tự
  bổ sung — KHÔNG tự viết sẵn nội dung title/description thay cho dev, chỉ nêu vấn đề cần cải thiện.
- Kiểm tra prefix theo branch: nếu `headRefName` (tên branch) chứa dạng mã backlog/ticket (vd
  `PROJ-123`, `JIRA-456`, hoặc số ticket rõ ràng trong tên branch) NHƯNG title PR KHÔNG mang prefix
  tương ứng → cũng ghi trong phần tổng quan, đề nghị thêm prefix cho nhất quán. Nếu tên branch KHÔNG
  chứa dạng mã ticket nào → BỎ QUA HOÀN TOÀN kiểm tra này, không ép buộc phải có prefix.
- 2 mục trên là nhận xét ở phần TỔNG QUAN — KHÔNG tính vào 3 mức nghiêm trọng của Bước 7 (những mức
  đó dành cho finding cấp file/line), KHÔNG đưa vào `comments[]` ở Bước 8 vì không gắn được với 1
  file/dòng cụ thể trong diff.

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

**Nguyên tắc phạm vi (in-scope) & mức độ:**

- **Tập trung vào phần THAY ĐỔI của PR (in-scope).** Ưu tiên review đúng những gì PR này thêm/sửa.
  Nếu phát hiện vấn đề KHÔNG liên quan trực tiếp tới thay đổi của PR (code cũ có sẵn, ngoài phạm vi)
  — vẫn có thể nêu nhưng phải TÁCH RIÊNG rõ ràng, gắn nhãn "ngoài phạm vi PR này" (out-of-scope):
  KHÔNG tính vào các mức bắt buộc/nên sửa, KHÔNG ép fix trong PR này.
- **KHÔNG dùng source thư viện/framework như thói quen.** Dựa vào kiến thức chung sẵn có về
  framework/ngôn ngữ trước. CHỈ tra cứu source code của thư viện/framework bên ngoài (vendor,
  `node_modules`, gem source, package cài sẵn...) khi THỰC SỰ không chắc chắn về 1 hành vi cụ thể
  không thể suy ra từ kiến thức chung — không chủ động/mặc định cat/đọc source thư viện (tốn token).
- **Không bới finding vụn vặt để lấp chỗ trống.** KHÔNG cố tạo finding nhỏ nhặt chỉ để "có nội dung
  comment"; không có ngưỡng tối thiểu N finding. Nếu PR thực sự tốt, không có vấn đề đáng kể → tóm
  tắt chỉ cần "LGTM" (hoặc bản dịch tương ứng theo ngôn ngữ output đã chọn), 3 mức đều "Không có
  vấn đề". Chất lượng hơn số lượng.

**Định dạng nội dung mỗi finding** (áp dụng cho `body` của MỌI finding, cả cấp FILE lẫn LINE, dùng ở
Bước 8) — 2-3 dòng theo đúng khung sau, nhãn dịch theo ngôn ngữ output đã chọn (tiếng Việt dưới đây,
tiếng Anh: `**Issue**` / `**Fix**` / `*(if needed)* because ...`):

```
**Vấn đề** — <mô tả ngắn gọn lỗi/code thừa/inconsistent>.
**Cách fix** — <hành động cụ thể cần làm>.
*(chỉ thêm nếu cần)* vì <lý do ngắn gọn trong 1 câu>.
```

Dòng lý do là TÙY CHỌN — chỉ thêm khi lý do không hiển nhiên từ mô tả vấn đề/cách fix.

## Bước 7 — Định dạng kết quả

Giữ khung định dạng sau (ngôn ngữ lấy theo `ALWAYS_RULE.md` đã đọc ở Bước 4, default **English**
nếu file đó không ghi rõ khác):

```
### Nhận xét tổng quan
(2-3 câu đánh giá chung; nếu PR tốt, không có vấn đề đáng kể → chỉ cần "LGTM")
(nếu có, thêm ngay ở đây nhận xét về title/description theo Bước 6 — không tính vào 3 mức bên dưới,
không đưa vào comments[] ở Bước 8, vì không gắn với 1 file/dòng cụ thể)

#### [Bắt buộc sửa] (N vấn đề)
#### [Nên sửa] (N vấn đề)
#### [Đề xuất] (N vấn đề)
```

Dùng nhãn TEXT thuần cho 3 mức nghiêm trọng (KHÔNG dùng emoji/ký hiệu màu). Nhãn dịch theo ngôn ngữ
output đã chọn — ví dụ tiếng Anh: `[MUST FIX]` / `[SHOULD FIX]` / `[SUGGESTION]`; tiếng Việt như
trên. Đếm đúng số lượng finding thực tế theo từng mức. Nếu 1 mức không có finding nào, ghi rõ
"Không có vấn đề" (hoặc bản dịch tương ứng) thay vì bỏ trống mục đó.

## Bước 8 — Post review (ĐÚNG 1 LẦN GỌI API DUY NHẤT)

Không hardcode tên người review vào nội dung — `gh api` tự đăng dưới tài khoản `gh auth` đang
active trên máy chạy lệnh, không cần thêm field tên người review vào payload.

Dùng `owner`/`repo`/`pull_number` đã parse ở block "Ngữ cảnh", và `headRefOid` đã lấy sẵn ở đó làm
`commit_id`. `comments[]` PHẢI gồm **TẤT CẢ** finding ở **CẢ 3 MỨC** (Bắt buộc sửa / Nên sửa / Đề
xuất) từ Bước 6/7 — KHÔNG lọc
bớt mức nào. Vì JSON có thể lớn/phức tạp (nhiều phần tử `comments`), dùng `--input -` với heredoc
thay vì nhiều cờ `-f`/`-F` riêng lẻ, để tránh lỗi escaping qua command-line flags:

```bash
gh api -X POST repos/{owner}/{repo}/pulls/{pull_number}/reviews \
  --input - <<EOF
{
  "body": "<nội dung ### Nhận xét tổng quan + đếm 3 mức nhãn text từ Bước 7>",
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

**Field `"event"` BẮT BUỘC có mặt trong payload trên** (`"COMMENT"` ở ví dụ) — thiếu field này khiến
GitHub tạo review ở trạng thái **PENDING** (chỉ người review tự thấy, dev KHÔNG thấy comment nào cho
tới khi có người bấm submit thủ công trên UI — đây là nguyên nhân review "biến mất" nếu bị thiếu).
KHÔNG dùng `gh pr review --comment` hay POST riêng lẻ từng comment qua
`/pulls/{pull_number}/comments` — cả 2 cách này đều KHÔNG đảm bảo review được submit kèm comment,
CHỈ dùng đúng 1 lệnh `POST .../pulls/{pull_number}/reviews` có `event` như trên.

**Verify ngay sau khi post** (bắt buộc, không bỏ qua): gọi
`gh api repos/{owner}/{repo}/pulls/{pull_number}/reviews --jq '.[-1] | {id, state}'` để lấy review
vừa tạo. Nếu `state` là `"PENDING"` (nghĩa là lần POST ở trên vì lý do nào đó không submit được) →
submit ngay bằng `gh api -X POST repos/{owner}/{repo}/pulls/{pull_number}/reviews/{review_id}/events
-f event="COMMENT"` (thay `{review_id}` bằng `id` vừa lấy được). KHÔNG coi lệnh post ở Bước 8 là
hoàn tất cho tới khi xác nhận `state` KHÁC `"PENDING"` (vd `"COMMENTED"`).

## Bước 9 — Hành vi chung khi plugin "review" active (ngoài luồng `/review:pr`)

Áp dụng bất cứ khi nào plugin này active trong session, không riêng lúc chạy `/review:pr`:

- User trò chuyện bình thường (KHÔNG chạy `/review:pr`) và tự phát biểu một sửa đổi/góp ý convention
  cho repo đang có `notebooks/review/<repo>/` (từ lần `/review:pr` trước) → KHÔNG tự ghi ngay.
  Hỏi xác nhận trước (như Bước 5); CHỈ SAU KHI user đồng ý mới ghi lesson theo Phần E của
  `"${CLAUDE_PLUGIN_ROOT}"/src/setup-flow.md`.
- User yêu cầu "doctor lại"/"quét lại convention dự án" → set `doctored: false` trong `meta.json`
  rồi thực hiện lại Phần C của `"${CLAUDE_PLUGIN_ROOT}"/src/setup-flow.md`, không cần đợi lần
  `/review:pr` kế tiếp.

---

ARGUMENTS: $ARGUMENTS
