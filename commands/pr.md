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
- Review comments cũ của chính PR này (dùng ở Bước 6 — response rỗng là bình thường, không phải lỗi): !`gh api repos/$(echo $ARGUMENTS | sed -E 's#https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+).*#\1/\2#')/pulls/$(echo $ARGUMENTS | sed -E 's#.*/pull/([0-9]+).*#\1#')/comments 2>/dev/null`

**Cách suy ra `{owner}/{repo}/{pull_number}` từ ARGUMENTS** (dùng lại nhiều lần ở các bước sau, ghi
nhớ cách parse này thay vì suy diễn lại mỗi lần):
`ARGUMENTS` có dạng `https://github.com/<owner>/<repo>/pull/<number>`. Cắt segment ngay sau
`github.com/` là `owner`, segment kế tiếp là `repo`, số ngay sau `/pull/` là `pull_number`. Ví dụ
`https://github.com/acme/api/pull/42` → `owner=acme`, `repo=api`, `pull_number=42`. Lệnh
`gh api repos/{owner}/{repo}/pulls/{pull_number}/comments` ở trên đã tự parse bằng `sed` cho lần
gọi đầu; ở các bước dưới đây (đặc biệt Bước 8) khi cần gọi `gh api` lại, dùng lại đúng cách parse
này với `owner`, `repo`, `pull_number` cụ thể của PR đang review.

`short_name` (dùng từ Bước 2 trở đi) = đúng segment `<repo>` ở trên (KHÔNG kèm owner). Ví dụ URL
trên → `short_name = api`. Lưu ý biết trước: nếu trên cùng máy từng review 2 PR của 2 repo khác
owner nhưng trùng tên repo, `short_name` sẽ trùng nhau và dùng chung 1 thư mục memory — đây là giới
hạn đã biết của thiết kế hiện tại (không tự ý đổi sang `owner-repo` để né, vì đó là quyết định đổi
schema cần user duyệt riêng), cứ theo đúng `short_name = <repo>` như trên.

## Bước 1 — Detect stack cho từng file trong diff

Với MỖI file trong "Danh sách file thay đổi" ở trên, map theo bảng sau để biết stack nào áp dụng.
Một PR có thể trộn nhiều stack — giữ một danh sách cặp `(file, [stack áp dụng])`, KHÔNG dùng chung
1 stack cho cả PR nếu các file thuộc stack khác nhau.

| Điều kiện file | Stack |
|---|---|
| `.rb`, `.erb`, `.haml` | `rails` |
| `.vue` | `vue` |
| `.jsx`, `.tsx` (không phải `.vue`; heuristic hỗ trợ: path chứa `src/components`, `pages/`, hoặc file có import `react`) | `react` |
| `.py` | `python` |
| `.js`, `.ts` còn lại (không thuộc `.vue` / `.jsx` / `.tsx` / thư mục FE nêu trên) | `nodejs` |
| `.sh`, `.bash` | `shell` |
| `Makefile`, `makefile`, `*.mk` | `makefile` |
| `.php` (không rơi vào overlay Laravel/WordPress bên dưới) | `php` |

**Overlay (CỘNG THÊM lên stack nền, KHÔNG thay thế):**

- **Lambda** — nếu path chứa `lambda`/`lambdas`/`functions/`, HOẶC repo có `serverless.yml` /
  `template.yaml` / `sam.yaml`, HOẶC filename là `handler.py`/`handler.js`/`index.py`/`index.js`
  nằm cạnh một trong các file config trên → cộng thêm stack `lambda-common` lên `python` (nếu file
  `.py`) hoặc `nodejs` (nếu file `.js`/`.ts`) tương ứng.
- **Laravel** — nếu repo có `artisan`, `composer.json` chứa `laravel/framework`, hoặc path
  `app/Http/Controllers`, `resources/views/*.blade.php` → cộng thêm stack `laravel` lên `php`.
- **WordPress** — nếu repo có `wp-config.php`, path `wp-content/plugins/` hoặc
  `wp-content/themes/`, hoặc `style.css` có theme header → cộng thêm stack `wordpress` lên `php`.

Ghi lại kết quả detect này (file → (các) stack) — dùng ở Bước 3 (đảm bảo có local template) và
Bước 5 (áp đúng tiêu chí cho đúng file).

## Bước 2 — Thiết lập lần đầu cho repo (nếu cần)

Dùng `Read` thử đọc `notebooks/review/<short_name>/meta.json` tại pwd (root repo đang review,
KHÔNG PHẢI root plugin).

- **Nếu file không tồn tại, HOẶC tồn tại nhưng `bootstrapped`/`doctored` không phải cả hai đều
  `true`**: dùng `Read` đọc `"${CLAUDE_PLUGIN_ROOT}"/setup-flow.md` (biến môi trường chuẩn của
  Claude Code, tự trỏ đúng root plugin bất kể cài ở máy nào — KHÔNG hardcode path tuyệt đối của 1
  máy cụ thể) và làm theo TOÀN BỘ Phần A + Phần C của file đó (Phần B — copy template theo stack —
  xử lý riêng ở Bước 3, không làm ở đây).
- **Nếu `bootstrapped: true` VÀ `doctored: true` rồi**: BỎ QUA HOÀN TOÀN bước này, KHÔNG đọc
  `setup-flow.md` (để không tốn context của lần review này cho nội dung thiết lập không còn cần
  thiết) — đi thẳng sang Bước 3.

**Đây PHẢI là behavior idempotent nghiêm ngặt**: từ lần chạy thứ 2 trở đi (khi đã bootstrapped +
doctored), lệnh này KHÔNG được đụng tới bất kỳ file nào trong `notebooks/review/` ngoại trừ nội
dung được thêm ở Bước 3 (template mới cho stack chưa từng gặp) hoặc Bước 6 (đề xuất lesson, có xác
nhận của user).

## Bước 3 — Đảm bảo có local template cho (các) stack của PR này

Với MỖI stack đã detect ở Bước 1: kiểm `notebooks/review/<short_name>/meta.json` xem tên stack đó
đã có trong mảng `templates_copied` chưa.

- **Chưa có** → dùng `Read` đọc `"${CLAUDE_PLUGIN_ROOT}"/setup-flow.md` Phần B (nếu chưa đọc file
  này ở Bước 2) và làm theo — copy (hoặc tự soạn mới nếu plugin chưa có) template cho stack đó vào
  `notebooks/review/<short_name>/templates/<stack>.md`, rồi thêm tên stack vào `templates_copied`.
- **Đã có rồi** → BỎ QUA, dùng thẳng bản local đã có tại
  `notebooks/review/<short_name>/templates/<stack>.md`.

Bước này CHẠY MỖI LẦN (không gộp vào điều kiện "đã setup xong" của Bước 2), vì 1 repo có thể lần
đầu chỉ có PR Rails, rồi PR sau mới xuất hiện file Vue — lúc đó vẫn cần tạo local template cho Vue
dù bootstrap/doctor đã xong từ trước.

## Bước 4 — Nạp rule + memory + template

1. Đọc `"${CLAUDE_PLUGIN_ROOT}"/ALWAYS_RULE.md` — rule chung của PLUGIN (áp dụng mọi repo), khác
   với convention riêng của repo đang review (nằm ở `notebooks/review/<short_name>/`). Lấy từ đây:
   ngôn ngữ output (default **English** nếu file không ghi rõ khác) + rule cứng khác nếu có + khung
   6 mục **baseline** (tiêu chí chung áp dụng MỌI stack — mục 1,2,3,4,6; riêng mục 5 "Đặc thù
   framework/language" không có baseline, luôn lấy 100% từ template ở mục 3 dưới). File này ghi rõ:
   toàn bộ danh sách tiêu chí (cả ở đây lẫn trong template) là GỢI Ý MINH HỌA, KHÔNG PHẢI checklist
   đóng — giữ đúng tinh thần đó khi review ở Bước 5, không tự giới hạn chỉ tìm đúng những gì được
   liệt kê.
2. Đọc `notebooks/review/<short_name>/memory.md` (index) + đọc từng `memories/<lesson>.md` được
   trỏ tới bởi các dòng có tag stack TRÙNG với (các) stack đã detect ở Bước 1 cho PR này (bỏ qua
   lesson của stack không xuất hiện trong PR). Với dòng dạng THAM CHIẾU (từ doctor, không phải
   lesson tự học) → đọc luôn nội dung tại path được trỏ tới trong repo đang review, coi đó là tiêu
   chí bổ sung có giá trị ngang lesson thường.
3. Đọc (các) file **LOCAL** trong `notebooks/review/<short_name>/templates/` tương ứng với kết quả
   detect ở Bước 1 (bao gồm cả overlay nếu có, vd đọc cả `python.md` lẫn `lambda-common.md` nếu PR
   có lambda) — KHÔNG đọc trực tiếp từ `${CLAUDE_PLUGIN_ROOT}/templates/` nữa, vì Bước 3 đã đảm bảo
   bản local tồn tại và đó mới là bản có hiệu lực cho repo này (có thể đã được team tự chỉnh sửa).

## Bước 5 — Đọc lại review comments cũ của chính PR này (re-review detection)

Dữ liệu đã lấy sẵn ở block "Ngữ cảnh" (`gh api .../pulls/{pull_number}/comments`) — luôn gọi mỗi
lần chạy lệnh, kể cả PR mới toanh (response rỗng thì bỏ qua, KHÔNG coi là lỗi).

- Chỉ xét reply chain (`in_reply_to_id`) của CHÍNH PR đang review này — không quét PR khác.
- Tự đọc hiểu ngôn ngữ tự nhiên trong nội dung comment + các reply, tự phán đoán xem dev và
  reviewer đã đi đến ĐỒNG THUẬN về 1 convention nào chưa. **KHÔNG dựa vào trạng thái `resolved`**
  của comment để quyết định (chủ đích thiết kế, không phải giới hạn kỹ thuật — resolved chỉ là
  UI state, không phản ánh có đồng thuận thật hay không).
- Nếu phát hiện đồng thuận → **KHÔNG tự ý ghi ngay**. Hiển thị đề xuất trong chat gồm: nội dung
  lesson dự kiến (mô tả convention, ví dụ nếu rút ra được từ thread) + tag stack dự kiến. CHỜ user
  xác nhận (yes / no / sửa lại nội dung).
- CHỈ SAU KHI user đồng ý mới:
  - Tạo `notebooks/review/<short_name>/memories/<lesson-slug>.md` (slug kebab-case ngắn gọn, không
    dùng số thứ tự vô nghĩa) với nội dung tối thiểu: mô tả convention, ví dụ code trước/sau (nếu
    có), tag stack, ngày ghi nhận, nguồn (link PR đang review này).
  - Thêm 1 dòng vào index `memory.md` theo đúng format ở Bước 2/`setup-flow.md` (`- [tag] mô tả -> memories/<lesson-slug>.md`).
  - `git -C notebooks/review add <short_name>` + commit (local only, không push).

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

## Bước 9 — Ghi chú hành vi chung (áp dụng mọi lúc plugin "review" active, không riêng lúc chạy `/review:pr`)

Đây không phải bước runtime của riêng lệnh này, mà là hành vi chung cần tuân thủ bất cứ khi nào
plugin này đang active trong session:

- Khi user đang trò chuyện bình thường với Claude Code (KHÔNG phải đang chạy `/review:pr`) và TỰ
  PHÁT BIỂU một sửa đổi/góp ý về convention của dự án đang được review (repo hiện có
  `notebooks/review/<short_name>/` từ lần chạy `/review:pr` trước đó) → KHÔNG được tự ý ghi ngay
  vào memory. Phải hỏi xác nhận user trước (giống hệt cơ chế đề xuất ở Bước 5), CHỈ SAU KHI user
  xác nhận đồng ý mới ghi file mới vào `notebooks/review/<short_name>/memories/<lesson-slug>.md`
  (format như Bước 5) + thêm 1 dòng entry vào `notebooks/review/<short_name>/memory.md`, rồi
  commit (local only) vào git nested tại `notebooks/review/.git`.
- Khi user yêu cầu "doctor lại"/"quét lại convention dự án" → sửa `doctored` trong `meta.json`
  thành `false` rồi thực hiện lại Phần C của `setup-flow.md`, không cần đợi tới lần `/review:pr`
  kế tiếp nếu user muốn làm ngay trong chat.

---

ARGUMENTS: $ARGUMENTS
