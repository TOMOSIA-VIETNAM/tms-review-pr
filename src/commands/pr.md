---
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh pr checkout:*), Bash(gh api:*), Bash(git init:*), Bash(git -C notebooks/review:*), Bash(git fetch:*), Bash(git status:*), Bash(git show:*), Bash(git worktree add notebooks/review/*/worktrees/*), Bash(cd notebooks/review/*/worktrees/* && gh pr checkout:*), Bash(git -C notebooks/review/*/worktrees/* submodule update:*), Bash(cp:*), Bash(mkdir:*), Agent, Read, Grep, Write, Edit
argument-hint: <GitHub PR URL>
description: Review 1 PR GitHub đa stack, học convention riêng theo repo qua memory, post kết quả qua gh api.
---

> **QUY TẮC AN TOÀN BẮT BUỘC (CRITICAL):** Lệnh này CHỈ được review + post 1 review comment lên PR
> (Bước 9) — CỘNG THÊM đúng 1 review nữa lên PR submodule khi phát hiện bump submodule kèm link
> (xem `submodule-review.md`, điều kiện ở Bước 1), không hơn. TUYỆT ĐỐI KHÔNG tự ý close/merge/reopen
> PR, KHÔNG xoá/tạo/đổi branch trên repo đang review, KHÔNG push, KHÔNG sửa code trong repo đang
> review, KHÔNG thực hiện bất kỳ hành động nào ngoài phạm vi review mà KHÔNG có sự đồng ý rõ ràng của
> user — kể cả khi phát hiện vấn đề nghiêm trọng. Nếu thấy cần hành động khác ngoài comment (vd đề
> xuất đóng PR, revert, đổi base branch), CHỈ NÊU trong nội dung review, KHÔNG tự thực hiện.
> `allowed-tools` ở trên đã cố tình giới hạn đúng các subcommand `gh`/`git` cần dùng (không có
> `gh pr close/merge`, không có `git push/branch -D/reset --hard`; `git worktree add` neo cứng trong
> `notebooks/review/*/worktrees/*` — không tạo được worktree ở nơi khác) — không tự ý dùng lệnh ngoài
> danh sách này để lách qua giới hạn.

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
của Claude Code — output của các lệnh đó lúc này vô nghĩa, bỏ qua hoàn toàn):

```
❌ Lỗi: Chưa cung cấp URL PR.
Cách dùng: /review:pr <GitHub PR URL>
Ví dụ: /review:pr https://github.com/org/repo/pull/123
```

Chỉ tiến hành các bước 1-10 bên dưới nếu `ARGUMENTS` chứa 1 tham chiếu PR GitHub hợp lệ.

**Phần còn lại của `ARGUMENTS` ngoài URL (nếu có) là chỉ dẫn bổ sung của user cho lần review này**
(vd `<url> Review comment tiếng Việt` → dùng tiếng Việt cho lần chạy này), không phải rác bỏ qua vô
điều kiện — đọc hiểu và áp dụng nếu hợp lý (ưu tiên hơn default trong `ALWAYS_RULE.md` cho lần chạy
này), bỏ qua phần không hiểu được ý nghĩa. Về kỹ thuật: mọi lệnh `gh` dùng ARGUMENTS trong "Ngữ
cảnh" bên dưới PHẢI trích riêng canonical URL trước (qua
`grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1`, có quote `"$ARGUMENTS"`) —
KHÔNG bao giờ truyền thẳng `$ARGUMENTS` thô (không quote) vào lệnh shell, vì phần chỉ dẫn bổ sung
này là văn bản tự do (có thể chứa khoảng trắng, ký tự bất kỳ) sẽ làm vỡ câu lệnh nếu không tách ra
trước.

## Ngữ cảnh

Các lệnh dưới đây trước tiên trích PR URL "sạch" (canonical `https://github.com/<owner>/<repo>/pull/<number>`,
CẮT BỎ mọi phần đuôi như `/changes`/`/files`/query/fragment) từ `$ARGUMENTS` bằng
`grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+'`, để `gh` không bị lỗi khi URL có đuôi:

Mọi lệnh `gh pr view`/`gh pr diff` dưới đây kèm thêm `-R "owner/repo"` (trích cùng cách với
`sed` bên dưới) TƯỜNG MINH thay vì để `gh` tự đoán remote qua git config local của pwd hiện tại —
tránh lỗi khi repo có nhiều remote hoặc không remote nào (pwd hiện tại không nhất thiết đã có sẵn
remote đúng của repo đang review, nhất là trước khi worktree ở Bước 1 tồn tại):

- Thông tin PR (bao gồm `body` = description — dùng ở Bước 7 để đánh giá title/description có thể
  hiện rõ business không; `baseRefName`/`headRefName` dùng ở Bước 1 để checkout): !`gh pr view "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" -R "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 | sed -E 's#.*github\.com/([^/]+)/([^/]+)/pull/[0-9]+#\1/\2#')" --json number,title,body,author,baseRefName,headRefName 2>/dev/null`
- Head commit sha (bắt buộc dùng ở Bước 9 khi post review): !`gh pr view "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" -R "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 | sed -E 's#.*github\.com/([^/]+)/([^/]+)/pull/[0-9]+#\1/\2#')" --json headRefOid --jq .headRefOid 2>/dev/null`
- Danh sách file thay đổi: !`gh pr diff "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" -R "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 | sed -E 's#.*github\.com/([^/]+)/([^/]+)/pull/[0-9]+#\1/\2#')" --name-only 2>/dev/null`
- Diff đầy đủ (dùng ở Bước 1 mục 5 để phát hiện `Subproject commit` — submodule bump): !`gh pr diff "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" -R "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 | sed -E 's#.*github\.com/([^/]+)/([^/]+)/pull/[0-9]+#\1/\2#')" 2>/dev/null`
- Commits: !`gh pr view "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" -R "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 | sed -E 's#.*github\.com/([^/]+)/([^/]+)/pull/[0-9]+#\1/\2#')" --json commits --jq '.commits[].messageHeadline' 2>/dev/null`
- Review comments cũ của chính PR này (dùng ở Bước 6 — response rỗng là bình thường, không phải lỗi): !`gh api repos/$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 | sed -E 's#.*github\.com/([^/]+)/([^/]+)/pull/([0-9]+)#\1/\2#')/pulls/$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 | sed -E 's#.*/pull/([0-9]+)#\1#')/comments 2>/dev/null`

**Parse `{owner}/{repo}/{pull_number}` từ ARGUMENTS:** từ phần khớp
`github.com/<owner>/<repo>/pull/<number>` → `owner` = segment sau `github.com/`, `repo` = segment
kế tiếp, `pull_number` = số sau `/pull/` (bỏ qua mọi phần đuôi sau số này). Ví dụ
`.../acme/api/pull/42/files` → `owner=acme`, `repo=api`, `pull_number=42`. Dùng lại cách parse này
ở Bước 1 (cờ `-R owner/repo` khi checkout) và Bước 9 khi gọi `gh api`.

**Tên repo (`repo name`, dùng làm tên thư mục memory từ Bước 3 trở đi) = CHÍNH segment `<repo>` cắt
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

## Bước 1 — Đưa code PR vào 1 worktree ephemeral

Mục tiêu: đưa code của PR vào đúng trạng thái trên đĩa để Claude Code (và IDE đang chạy trong đó
nếu có, vd Cursor) tận dụng được index/search sẵn có trên codebase thật — ngữ cảnh review tốt hơn
đoạn diff patch đơn thuần. Đọc thêm file nào ngoài diff, đọc sâu tới đâu, là PHÁN ĐOÁN của agent lúc
review (Bước 7); bước này chỉ chuẩn bị điều kiện, không bắt buộc đọc toàn bộ codebase mỗi lần.

**Khác bản trước:** KHÔNG còn checkout thẳng lên working tree chính của pwd — dùng 1 **git worktree
riêng, tên NGẪU NHIÊN, tạo mới mỗi lần chạy, KHÔNG tái sử dụng/pool/lock** (cleanup nằm ngoài phạm
vi lệnh này, để lại cho tooling sau). Nhờ vậy KHÔNG còn cần gate "working tree bẩn" và KHÔNG còn
cần ghi nhớ/khôi phục branch cũ — main tree ở pwd chưa từng bị đổi branch hay nội dung, 2 cơ chế đó
đã bỏ hoàn toàn. Vì tên ngẫu nhiên và không tái sử dụng, 2 lần review chạy song song (cùng PR hay
khác PR, cùng repo) luôn có thư mục riêng biệt, không cần thêm cơ chế lock nào.

1. Tạo worktree mới — path đi NGAY SAU `add` (khớp `allowed-tools`), cờ `--detach` đặt SAU path
   (`git worktree add` chấp nhận thứ tự này, tránh tạo thêm 1 branch thừa trỏ theo tên thư mục):
   ```bash
   git worktree add "notebooks/review/<repo>/worktrees/review-pr<pull_number>-$RANDOM" --detach
   ```
   (`git worktree add` tự tạo cả các thư mục cha còn thiếu.) Từ đây, mọi Read/Grep lên CODE của PR ở
   các bước sau (Bước 6, Bước 7) đọc TẠI `<worktree>/<path>` — tức đường dẫn vừa tạo ở trên nối thêm
   path trong repo — KHÔNG phải tại pwd trực tiếp như bản cũ.
2. Checkout code PR VÀO ĐÚNG worktree vừa tạo (không phải pwd chính), dùng subshell:
   ```bash
   (cd "notebooks/review/<repo>/worktrees/<tên vừa tạo>" && gh pr checkout <pull_number> -R "<owner>/<repo>")
   ```
   **Ngoại lệ DUY NHẤT, có chủ đích, cho rule "cấm `cd`"** ở block Ngữ cảnh phía trên: rule đó áp
   dụng cho pwd CHÍNH của phiên (cấm tự dò/điều hướng khỏi đó); subshell `(cd ... && ...)` ở đây
   KHÔNG đổi cwd của phiên chính (chỉ tồn tại trong tiến trình con) và bị neo cứng đúng thư mục
   worktree do chính bước này tạo ra (khớp `allowed-tools`), không phải tự "thông minh" điều hướng
   đi nơi khác. `-R owner/repo` (đã parse ở block Ngữ cảnh) dùng TƯỜNG MINH để `gh` không tự đoán
   remote qua git config local — tránh lỗi ở repo có nhiều remote hoặc không remote nào; cùng lý do
   mọi lệnh `gh pr view`/`gh pr diff` ở Ngữ cảnh phía trên cũng đã kèm `-R`.
3. `git fetch origin "<baseRefName>"` để có sẵn ref target khi cần so sánh (`git show
   "<baseRefName>":<path>` đọc nội dung file ở target mà không cần checkout riêng) — refs/objects
   dùng chung giữa mọi worktree của cùng 1 repo (kể cả worktree vừa tạo), fetch 1 lần là đủ.
4. LUÔN chạy (không điều kiện theo PR có đụng submodule hay không — vô hại nếu không có, và Bước 5
   dưới đây cần thư mục submodule đã sẵn sàng nếu có):
   ```bash
   git -C "notebooks/review/<repo>/worktrees/<tên vừa tạo>" submodule update --init --recursive
   ```
5. **Review PR submodule (nếu có):** nếu `meta.json.has_submodules == true` (field từ doctor, xem
   Phần D `setup-flow.md`) VÀ "Diff đầy đủ" đã lấy ở block Ngữ cảnh chứa dòng `Subproject commit`
   (submodule pointer đổi) → `Read` `"${CLAUDE_PLUGIN_ROOT}"/src/submodule-review.md` và làm theo.
   Repo không có `.gitmodules` (`has_submodules` luôn `false`) → bỏ qua hoàn toàn, KHÔNG BAO GIỜ đọc
   file này.

Không còn bước "khôi phục branch cuối cùng" — main tree (pwd chính của phiên) chưa từng bị đổi
branch hay nội dung ở bất kỳ đâu trong lệnh này, không có gì cần khôi phục.

## Bước 2 — Detect stack cho từng file trong diff

Với MỖI file trong "Danh sách file thay đổi", xác định (các) stack áp dụng theo bảng mapping +
overlay rule trong `stack-detection.md` (đọc bằng `Read` tại
`"${CLAUDE_PLUGIN_ROOT}"/src/stack-detection.md`). Giữ danh sách cặp `(file, [stack áp dụng])` — dùng
lại ở Bước 4 (đảm bảo local template), Bước 5 (nạp template), Bước 6 và Bước 7 (áp đúng tiêu chí
cho đúng file).

## Bước 3 — Thiết lập lần đầu cho repo (nếu cần)

`Read` thử `notebooks/review/<repo>/meta.json` tại pwd (root repo đang review, KHÔNG PHẢI
root plugin).

- **File không tồn tại, HOẶC `bootstrapped`/`doctored` chưa cùng `true`**: đọc
  `"${CLAUDE_PLUGIN_ROOT}"/src/setup-flow.md` và làm theo Phần A + Phần C (Phần B — copy template theo
  stack — xử lý ở Bước 4).
- **`bootstrapped: true` VÀ `doctored: true`**: bỏ qua bước này, KHÔNG đọc `setup-flow.md`, sang
  thẳng Bước 4.

Dù rẽ nhánh nào, giữ lại giá trị `auto_submit_review`/`auto_resolve_fixed_findings` đọc được từ
`meta.json` (mặc định `false` nếu thiếu) — dùng lại ở Bước 6 và Bước 9.

Idempotent nghiêm ngặt: từ lần chạy thứ 2 trở đi (đã bootstrap + doctor), lệnh KHÔNG đụng bất kỳ
file nào trong `notebooks/review/` ngoài phần thêm ở Bước 4 (template stack chưa từng gặp) hoặc
Bước 6 (lesson, có xác nhận của user).

## Bước 4 — Đảm bảo có local template cho (các) stack của PR này

Với MỖI stack đã detect ở Bước 2: kiểm mảng `templates_copied` trong
`notebooks/review/<repo>/meta.json`.

- **Chưa có** → đọc `"${CLAUDE_PLUGIN_ROOT}"/src/setup-flow.md` Phần B (nếu chưa đọc ở Bước 3) và làm
  theo.
- **Đã có** → dùng thẳng bản local `notebooks/review/<repo>/templates/<stack>.md`.

Bước này CHẠY MỖI LẦN (tách khỏi gate "đã setup xong" của Bước 3): stack mới có thể xuất hiện ở PR
sau dù bootstrap/doctor đã xong từ trước.

## Bước 5 — Nạp rule + memory + template

1. Đọc bản **LOCAL** `notebooks/review/<repo>/ALWAYS_RULE.md` (copy từ plugin lúc bootstrap — xem
   Phần A của `setup-flow.md`; team có thể đã tự chỉnh sửa cho dự án). KHÔNG đọc trực tiếp
   `${CLAUDE_PLUGIN_ROOT}/src/ALWAYS_RULE.md` — bản plugin chỉ là "seed" mặc định, bản local mới có
   hiệu lực cho repo này (giống cách mục 3 dưới đọc template LOCAL thay vì global). Đây là rule
   chung mọi repo, khác convention riêng của repo đang review (lesson trong
   `notebooks/review/<repo>/memory.md`). Lấy từ đây: ngôn ngữ output (default **English** nếu không
   ghi rõ khác) + rule cứng khác nếu có + khung 6 mục **baseline** (mục 1,2,3,4,6 — chung mọi stack;
   mục 5 "Đặc thù framework/language" không có baseline, lấy 100% từ template ở mục 3 dưới). Danh
   sách tiêu chí là GỢI Ý MINH HỌA, không phải checklist đóng — giữ tinh thần đó khi review ở Bước 7.
2. Đọc `notebooks/review/<repo>/memory.md` (index) + đọc từng `memories/<lesson>.md` được
   trỏ tới bởi các dòng có tag stack TRÙNG với (các) stack đã detect ở Bước 2 (bỏ qua lesson của
   stack không xuất hiện trong PR). Dòng dạng THAM CHIẾU (từ doctor, không phải lesson tự học) →
   đọc luôn nội dung tại path được trỏ tới trong repo đang review, coi là tiêu chí bổ sung có giá
   trị ngang lesson thường.
3. Đọc (các) file **LOCAL** trong `notebooks/review/<repo>/templates/` tương ứng kết quả
   detect ở Bước 2 (gồm cả overlay nếu có, vd đọc cả `python.md` lẫn `lambda-common.md` khi PR có
   lambda). KHÔNG đọc trực tiếp từ `${CLAUDE_PLUGIN_ROOT}/src/templates/` — bản local mới là bản có
   hiệu lực cho repo này (có thể đã được team chỉnh sửa).

## Bước 6 — Đọc lại review comments cũ của chính PR này (re-review detection)

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
  bằng `Read` nếu chưa nạp file này ở Bước 3/4).

**Kiểm tra finding cũ (do chính lần review trước của lệnh này để lại) đã được fix chưa** — mục tiêu
riêng, khác với việc học convention ở trên, dùng chung dữ liệu đã fetch:

1. Lấy tài khoản đang chạy lệnh: `gh api user --jq .login`.
2. Trong danh sách comment đã fetch, lọc ra các comment TOP-LEVEL (không phải reply, tức không có
   `in_reply_to_id`) mà `user.login` TRÙNG tài khoản ở mục 1 VÀ nội dung khớp khung finding ở Bước 7
   (chứa `**Vấn đề**`/`**Issue**`) — đây là các finding do chính lệnh này để lại ở (các) lần chạy
   trước trên PR này.
3. Với MỖI comment như vậy: đối chiếu mô tả vấn đề trong comment với code HIỆN TẠI tại đúng
   path/vùng đó (đã có sẵn trong worktree tạo ở Bước 1, dùng `Read` tại `<worktree>/<path>`) — tự
   phán đoán vấn đề đã được fix hay chưa, không có rule cứng, dựa vào đọc hiểu thực tế.
   - **Đã fix** → reply ngắn gọn xác nhận vào ĐÚNG thread đó:
     `gh api -X POST repos/{owner}/{repo}/pulls/{pull_number}/comments/{comment_id}/replies -f
     body="<nhận xét cơ bản, 1 câu, theo ngôn ngữ output đã chọn, vd 'Đã fix, cảm ơn.'/'Fixed, thanks.'>"`.
     Sau đó rẽ theo `auto_resolve_fixed_findings` (đọc từ `meta.json` ở Bước 3):
     - **`true`** → resolve luôn thread: query `reviewThreads` qua GraphQL để tìm `threadId` ứng với
       `comment_id` đó
       (`gh api graphql -f query='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){reviewThreads(first:100){nodes{id comments(first:1){nodes{databaseId}}}}}}}' -f o={owner} -f r={repo} -F n={pull_number}`),
       lấy `id` của thread có `databaseId` khớp `comment_id`, rồi gọi mutation
       `gh api graphql -f query='mutation($t:ID!){resolveReviewThread(input:{threadId:$t}){thread{id isResolved}}}' -f t=<threadId>`.
       Nếu bước resolve lỗi (thiếu quyền, v.v.) thì bỏ qua, KHÔNG coi là lỗi chặn — reply xác nhận đã
       có là đủ giá trị chính.
     - **`false`** → CHỈ reply như trên, KHÔNG gọi GraphQL resolve — thread giữ nguyên trạng thái
       chưa resolve, để user tự resolve trên GitHub nếu muốn.
   - **Chưa fix** → KHÔNG làm gì cả, giữ nguyên comment, không nhắc lại, không tạo thêm nội dung gì.

## Bước 7 — Thực hiện review theo 6 mục

**Kiểm tra title & description PR trước (cấp độ tổng quan, không phải finding cấp file/line):**

- Đọc `title` + `body` (description) của PR đã lấy ở block Ngữ cảnh. Đánh giá: title + description
  có thể hiện rõ được BUSINESS/mục đích của thay đổi không (người đọc hiểu PR làm gì, giải quyết vấn
  đề gì, KHÔNG cần đọc code mới hiểu)? Nếu mập mờ/thiếu (title chung chung kiểu "fix bug", "update",
  description rỗng hoặc không giải thích được lý do thay đổi) → ghi rõ trong phần tổng quan ở Bước 8
  (ưu tiên cao, nêu ngay đầu đoạn) rằng title/description chưa thể hiện đủ business, ĐỀ NGHỊ dev tự
  bổ sung — KHÔNG tự viết sẵn nội dung title/description thay cho dev, chỉ nêu vấn đề cần cải thiện.
- Kiểm tra prefix theo branch: nếu `headRefName` (tên branch) chứa dạng mã backlog/ticket (vd
  `PROJ-123`, `JIRA-456`, hoặc số ticket rõ ràng trong tên branch) NHƯNG title PR KHÔNG mang prefix
  tương ứng → cũng ghi trong phần tổng quan, đề nghị thêm prefix cho nhất quán. Nếu tên branch KHÔNG
  chứa dạng mã ticket nào → BỎ QUA HOÀN TOÀN kiểm tra này, không ép buộc phải có prefix.
- 2 mục trên là nhận xét ở phần TỔNG QUAN — KHÔNG tính vào 3 mức nghiêm trọng của Bước 8 (những mức
  đó dành cho finding cấp file/line), KHÔNG đưa vào `comments[]` ở Bước 9 vì không gắn được với 1
  file/dòng cụ thể trong diff.

Áp dụng khung 6 mục sau, hợp nhất từ 2 nguồn đã nạp ở Bước 5: **baseline** trong `ALWAYS_RULE.md`
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
(Bước 5) như **tiêu chí bổ sung** cho 6 mục trên. Nếu 1 lesson/tham chiếu trong memory MÂU THUẪN với
`ALWAYS_RULE.md` → `ALWAYS_RULE.md` LUÔN THẮNG, bỏ qua phần mâu thuẫn đó.

Với MỖI finding phát hiện được, tự quyết định đây là finding cấp **FILE** (ví dụ minh hoạ, không
phải danh sách cứng: file thừa/không cần thiết, sai vị trí trong cấu trúc thư mục, thiếu 1 file bắt
buộc phải đi kèm...) hay cấp **LINE** (bug/logic/security/performance tại 1 đoạn code cụ thể). Đây
là phán đoán theo ngữ cảnh của agent lúc review, KHÔNG dùng enum/danh sách cố định để phân loại.

**Với finding cấp LINE, xác định thêm `side` theo đúng vị trí trong diff** (dùng ở Bước 9): dòng bị
XOÁ (tiền tố `-` trong unified diff, thuộc nửa CŨ/before) → `side: "LEFT"`, số dòng lấy theo file
CŨ (base); dòng THÊM hoặc GIỮ NGUYÊN (tiền tố `+` hoặc dòng context, thuộc nửa MỚI/after) → `side:
"RIGHT"`, số dòng lấy theo file MỚI (head). Không mặc định `RIGHT` cho mọi trường hợp — comment vào
đúng nửa diff mà finding đang nói tới, sai `side` khiến GitHub gắn comment nhầm dòng.

**Finding cấp FILE đưa vào phần tổng quan (Bước 8), KHÔNG đưa vào `comments[]` (Bước 9).** GitHub
review API không hỗ trợ tin cậy comment không gắn dòng cụ thể khi trộn chung request với comment
gắn dòng (thực tế đã gặp lỗi 422 "position null" khi làm vậy) — nên finding cấp FILE luôn liệt kê
dưới dạng bullet trong body tổng quan (theo đúng mức nghiêm trọng), CHỈ finding cấp LINE mới thành
1 object trong `comments[]`.

**Nguyên tắc phạm vi (in-scope) & mức độ:**

- **Tập trung vào phần THAY ĐỔI của PR (in-scope).** Ưu tiên review đúng những gì PR này thêm/sửa.
  Nếu phát hiện vấn đề KHÔNG liên quan trực tiếp tới thay đổi của PR (code cũ có sẵn, ngoài phạm vi)
  — vẫn có thể nêu nhưng phải TÁCH RIÊNG rõ ràng, gắn nhãn "ngoài phạm vi PR này" (out-of-scope):
  KHÔNG tính vào các mức bắt buộc/nên sửa, KHÔNG ép fix trong PR này.
- **Đọc thêm codebase ngoài diff là phán đoán của agent, không bắt buộc.** Code PR đã có sẵn trong
  worktree tạo ở Bước 1 (`<worktree>/<path>`) — diff không đủ để đánh giá đúng (vd cần xem hàm được
  gọi từ file khác, convention hiện có của 1 module liên quan) thì tự đọc thêm bằng `Read`/`Grep`
  tại `<worktree>/<path>`; diff đã đủ rõ ràng thì không cần chủ động mở rộng đọc toàn bộ codebase.
- **"Diff đầy đủ" đã lấy 1 lần ở block Ngữ cảnh là nguồn DUY NHẤT cho nội dung thay đổi** — KHÔNG
  gọi lại `git diff`, `gh api .../pulls/{n}/files`, hay bất kỳ cách nào khác để lấy lại CÙNG nội
  dung diff đó cho từng file (tốn token vô ích, lấy 3 lần cùng 1 thông tin). Cần thêm ngữ cảnh NGOÀI
  diff thì dùng `Read` trên file thật đã checkout ở Bước 1 (đọc thêm, không phải đọc lại).
- **KHÔNG dùng source thư viện/framework như thói quen.** Dựa vào kiến thức chung về framework/ngôn
  ngữ trước; CHỈ tra cứu source thư viện bên ngoài (vendor, `node_modules`, gem source, package cài
  sẵn...) khi THỰC SỰ không chắc về 1 hành vi cụ thể không suy ra được từ kiến thức chung — không
  mặc định đọc source thư viện (tốn token).
- **Không bới finding vụn vặt để lấp chỗ trống.** KHÔNG cố tạo finding nhỏ nhặt chỉ để "có nội dung
  comment"; không có ngưỡng tối thiểu N finding. Nếu PR thực sự tốt, không có vấn đề đáng kể → tóm
  tắt chỉ cần "LGTM" (hoặc bản dịch tương ứng theo ngôn ngữ output đã chọn), 3 mức đều "Không có
  vấn đề". Chất lượng hơn số lượng.

**Định dạng nội dung mỗi finding** (áp dụng cho MỌI finding dù cấp FILE (bullet trong body ở Bước 8)
hay cấp LINE (`body` trong `comments[]` ở Bước 9)) — theo đúng khung sau, nhãn dịch theo ngôn ngữ
output đã chọn (tiếng Việt dưới đây, tiếng Anh: `**Issue**` / `**Fix**` / `*(if needed)* because ...`):

```
**Vấn đề** — <mô tả ngắn gọn lỗi/code thừa/inconsistent>.
**Cách fix** — <code hoặc mô tả, xem 2 trường hợp dưới>
*(chỉ thêm nếu cần)* vì <lý do ngắn gọn trong 1 câu>.
```

Phần **Cách fix** chọn 1 trong 2 dạng tuỳ bản chất của fix, KHÔNG cố ép dạng còn lại:

- **Fix thể hiện được bằng code** (sửa 1 đoạn cụ thể, đổi tên biến, thêm check, đổi cách gọi API...)
  → viết dưới dạng code block, KHÔNG diễn giải bằng lời thay cho code:
  - Finding cấp **LINE** mà fix là thay thế trực tiếp đúng (các) dòng đang comment → dùng
    ` ```suggestion ` (đúng cú pháp GitHub suggestion) thay vì code block thường — GitHub render
    thành nút "Apply suggestion" cho dev bấm áp dụng ngay, không cần gõ lại tay.
  - Các trường hợp còn lại (fix nằm ở chỗ khác trong file, cần thêm code mới, liên quan nhiều dòng
    không liền kề, hoặc finding cấp FILE) → dùng code block thường với tag ngôn ngữ phù hợp
    (```` ```ruby ````, ```` ```ts ````...), không dùng `suggestion`.
- **Fix KHÔNG thể hiện được bằng code** (quan điểm thiết kế, đề nghị đổi tên cho rõ nghĩa hơn nhưng
  không có 1 đáp án code duy nhất, cân nhắc kiến trúc, xác nhận lại giả định nghiệp vụ...) → viết
  bằng lời như hiện tại (1 câu ngắn gọn), KHÔNG gượng ép bọc vào code block.

Dòng lý do là TÙY CHỌN — chỉ thêm khi lý do không hiển nhiên từ mô tả vấn đề/cách fix.

## Bước 8 — Định dạng kết quả

Giữ khung định dạng sau (ngôn ngữ lấy theo `ALWAYS_RULE.md` đã đọc ở Bước 5, default **English**
nếu file đó không ghi rõ khác):

```
### Nhận xét tổng quan
(2-3 câu đánh giá chung; nếu PR tốt, không có vấn đề đáng kể → chỉ cần "LGTM")
(nếu có, thêm ngay ở đây nhận xét về title/description theo Bước 7 — không tính vào 3 mức bên dưới,
không đưa vào comments[] ở Bước 9, vì không gắn với 1 file/dòng cụ thể)

#### [Bắt buộc sửa] (N vấn đề)
(finding cấp FILE ở mức này, nếu có — mỗi finding 1 khối theo khung Vấn đề/Cách fix ở Bước 7, có ghi
rõ path của file. Finding cấp LINE KHÔNG lặp lại ở đây — đã có inline comment riêng ở Bước 9, chỉ
cần tính vào N.)
#### [Nên sửa] (N vấn đề)
(tương tự — finding cấp FILE ở mức này)
#### [Đề xuất] (N vấn đề)
(tương tự — finding cấp FILE ở mức này)
```

Dùng nhãn TEXT thuần cho 3 mức nghiêm trọng (KHÔNG dùng emoji/ký hiệu màu). Nhãn dịch theo ngôn ngữ
output đã chọn — ví dụ tiếng Anh: `[MUST FIX]` / `[SHOULD FIX]` / `[SUGGESTION]`; tiếng Việt như
trên. `N` = tổng finding cấp FILE + cấp LINE ở mức đó (đếm đúng số lượng thực tế). Nếu 1 mức không
có finding nào (cả file lẫn line), ghi rõ "Không có vấn đề" (hoặc bản dịch tương ứng) thay vì bỏ
trống mục đó.

## Bước 9 — Post review (ĐÚNG 1 LẦN GỌI API DUY NHẤT)

Không hardcode tên người review vào nội dung — `gh api` tự đăng dưới tài khoản `gh auth` đang
active trên máy chạy lệnh, không cần thêm field tên người review vào payload.

Dùng `owner`/`repo`/`pull_number` đã parse ở block "Ngữ cảnh", và `headRefOid` đã lấy sẵn ở đó làm
`commit_id`. `comments[]` CHỈ gồm finding cấp **LINE** — finding cấp FILE đã liệt kê trong `body`
tổng quan ở Bước 8, KHÔNG lặp lại trong `comments[]`. Vì JSON có thể lớn/phức tạp (nhiều phần tử
`comments`), dùng `--input -` với heredoc thay vì nhiều cờ `-f`/`-F` riêng lẻ, để tránh lỗi escaping
qua command-line flags:

```bash
gh api -X POST repos/{owner}/{repo}/pulls/{pull_number}/reviews \
  --input - <<EOF
{
  "body": "<nội dung ### Nhận xét tổng quan + finding cấp FILE + đếm 3 mức nhãn text từ Bước 8>",
  "commit_id": "<headRefOid lấy từ block Ngữ cảnh>",
  "event": "COMMENT",
  "comments": [
    {"path": "<file>", "line": <số dòng>, "side": "<LEFT hoặc RIGHT, đã xác định ở Bước 7>", "body": "<nội dung finding cấp LINE>"}
  ]
}
EOF
```

Rẽ theo `auto_submit_review` (đọc từ `meta.json` ở Bước 3):

- **`true`** (giữ nguyên như ví dụ trên): payload luôn có `"event": "COMMENT"`.
- **`false`**: payload KHÔNG có field `event` — bỏ hẳn key này khỏi JSON (không để giá trị rỗng/
  null), review dừng ở trạng thái PENDING một cách CHỦ Ý.

- Mỗi object trong `comments[]` gồm `path` + `line` + `side` (`LEFT` hoặc `RIGHT`, đã xác định ở
  Bước 7 theo dòng finding nằm ở nửa cũ hay mới của diff) + `body` — KHÔNG thêm object nào thiếu
  `line` (đó là finding cấp FILE, đã xử lý ở Bước 8, không thuộc payload này).
- `body` có thể chứa code block nhiều dòng (kể cả ` ```suggestion `, xem Bước 7) — đây vẫn là 1
  string JSON bình thường, chỉ cần escape xuống dòng đúng chuẩn JSON (`\n`) khi dựng payload, không
  cần xử lý gì thêm. ` ```suggestion ` CHỈ dùng cho finding cấp LINE mà nội dung suggestion thay thế
  ĐÚNG (các) dòng đang bị comment — sai dòng sẽ khiến GitHub áp dụng suggestion nhầm chỗ.
- Thay `{owner}`, `{repo}`, `{pull_number}` bằng giá trị thật đã parse. Đây là lần gọi `gh api`
  POST DUY NHẤT của lệnh cho PR CHÍNH đang review — không gọi thêm lần POST review nào khác cho PR
  này. (PR submodule, nếu có phát hiện ở Bước 1 mục 5, có đúng 1 lần POST RIÊNG của chính nó lên
  repo submodule — xem `submodule-review.md`, không tính vào ràng buộc "duy nhất" ở đây vì là PR
  khác, có thể ở repo khác.) Khi có mặt, `event` LUÔN là `"COMMENT"` — KHÔNG BAO GIỜ dùng
  `"APPROVE"` hay `"REQUEST_CHANGES"` (đó là quyết định của con người, ngoài phạm vi quy tắc an
  toàn ở đầu file này).

**Field `"event"` chỉ BẮT BUỘC có mặt khi `auto_submit_review: true`** — thiếu field này lúc đó
khiến GitHub tạo review ở trạng thái **PENDING** ngoài ý muốn (chỉ người review tự thấy, dev KHÔNG
thấy comment nào cho tới khi có người bấm submit thủ công trên UI). Khi `auto_submit_review: false`,
việc bỏ `event` để review dừng ở PENDING là CHỦ Ý, không phải lỗi. KHÔNG dùng `gh pr review --comment`
hay POST riêng lẻ từng comment qua `/pulls/{pull_number}/comments` — cả 2 cách này đều KHÔNG đảm bảo
review được submit kèm comment, CHỈ dùng đúng 1 lệnh `POST .../pulls/{pull_number}/reviews` như trên.

**Nếu lệnh POST trả lỗi (vd 422)**: đọc thông báo lỗi, đối chiếu lại đúng schema đã mô tả ở trên
(nghi ngờ đầu tiên: có object nào trong `comments[]` thiếu `line`, hoặc `line`/`side` không khớp vị
trí thật trong diff), sửa payload rồi gọi lại ĐÚNG 1 LẦN NỮA. KHÔNG tự tạo review/comment thử nghiệm
với nội dung giả (vd "test", "isolate") lên PR thật để debug, KHÔNG post rồi xoá đi xoá lại để dò
nguyên nhân — nếu sau khi sửa theo schema mà vẫn lỗi, DỪNG và báo lỗi thật cho user, không tự ý thử
thêm cách khác. Nếu lỗi vì tài khoản `gh auth` đang dùng CHÍNH LÀ tác giả của PR (GitHub không cho
tự duyệt PR của mình ở một số action) — đây KHÔNG phải sự cố cần workaround, chỉ báo lại cho user.

**Verify ngay sau khi post** (đúng 1 lần gọi kiểm tra, không hơn): gọi
`gh api repos/{owner}/{repo}/pulls/{pull_number}/reviews --jq '.[-1] | {id, state}'` để lấy review
vừa tạo, rồi rẽ theo `auto_submit_review`:

- **`true`**: nếu `state` là `"PENDING"` (nghĩa là lần POST ở trên vì lý do nào đó không submit
  được dù đã gửi `event`) → submit ngay bằng `gh api -X POST
  repos/{owner}/{repo}/pulls/{pull_number}/reviews/{review_id}/events -f event="COMMENT"` (thay
  `{review_id}` bằng `id` vừa lấy được).
- **`false`**: `state: "PENDING"` là kết quả ĐÚNG NHƯ MONG ĐỢI (đã cố ý bỏ `event`) — KHÔNG gọi
  endpoint submit-events. Chỉ báo cho user: đã tạo review nháp (PENDING) trên PR, vào GitHub tự
  submit khi sẵn sàng.

Đây là TOÀN BỘ việc verify cần làm — không tự thêm bước kiểm tra nào khác (không re-fetch diff để đối chiếu, không liệt kê lại từng
comment để soát, không tạo review test) ngoài 1 lệnh kiểm tra `state` này. Không còn bước khôi phục
branch sau verify (bản cũ) — main tree ở pwd chưa từng bị đổi branch (xem Bước 1), không có gì cần
khôi phục.

## Bước 10 — Hành vi chung khi plugin "review" active (ngoài luồng `/review:pr`)

Áp dụng bất cứ khi nào plugin này active trong session, không riêng lúc chạy `/review:pr`:

- User trò chuyện bình thường (KHÔNG chạy `/review:pr`) và tự phát biểu một sửa đổi/góp ý convention
  cho repo đang có `notebooks/review/<repo>/` (từ lần `/review:pr` trước) → KHÔNG tự ghi ngay.
  Hỏi xác nhận trước (như Bước 6); CHỈ SAU KHI user đồng ý mới ghi lesson theo Phần E của
  `"${CLAUDE_PLUGIN_ROOT}"/src/setup-flow.md`.
- User yêu cầu "doctor lại"/"quét lại convention dự án" → set `doctored: false` trong `meta.json`
  rồi thực hiện lại Phần C của `"${CLAUDE_PLUGIN_ROOT}"/src/setup-flow.md`, không cần đợi lần
  `/review:pr` kế tiếp.

---

ARGUMENTS: $ARGUMENTS
