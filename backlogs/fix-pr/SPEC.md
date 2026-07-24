# SPEC — `/tms:fix-pr`

Command mới trong plugin `tms` (cùng repo, cùng plugin với `/tms:review-pr` đã có). Chốt qua phiên
grilling với user — không còn quyết định thiết kế mở, chỉ còn việc viết file + implement.

## 1. Objective

`/tms:review-pr` là review-bot: chạy trong worktree ephemeral, CHỈ review + comment, cấm sửa code.
Dev nhận review xong phải tự fix — mỗi lần giao việc fix cho subagent, dev phải nhập lại rule bằng
tay (format reply, có nên amend không, tone...), dễ lệch/quên.

`/tms:fix-pr` giải quyết đúng việc đó: 1 command dev-facing, đọc đúng finding bot đã để lại
trên 1 PR, tự quyết fix/decline theo severity, sửa code ĐÚNG convention dự án, commit/push có kiểm
soát, reply lại PR đúng format — để dev (hoặc subagent dev giao việc) không phải tự bịa rule mỗi lần.

**Target user:** dev đang cầm PR đã được `/tms:review-pr` review, đứng tại working directory THẬT
của mình (không phải review-bot).

**Ngoài phạm vi (đã bàn riêng, chưa chốt, KHÔNG làm ở đây):** multi-PR review tuần tự cho
`/tms:review-pr`.

## 2. Commands (invocation + control flow)

### Invocation

```
/tms:fix-pr <PR_URL> [chỉ dẫn tự do]
```

- Không có chỉ dẫn thêm → xử lý TẤT CẢ finding bot còn MỞ (chưa resolve) trên PR đó.
- Có chỉ dẫn tự do → agent tự hiểu để thu hẹp phạm vi (vd "chỉ fix phần security").
- **An toàn `$ARGUMENTS`**: giống bài học vừa fix ở `review-pr.md` — Claude Code splice
  `$ARGUMENTS` thô (không escape) vào bất kỳ lệnh bash nào tham chiếu nó. Nếu cần 1 block
  context-injection (`!`...`` hoặc fenced ` ```! `) đọc `$ARGUMENTS`, PHẢI dùng heredoc quote-
  delimiter (`<<'DELIM'`), copy nguyên kỹ thuật từ block "Ngữ cảnh" của `review-pr.md`. Không có
  ngoại lệ.

### Control flow (thứ tự bắt buộc)

1. **Verify context an toàn** (DỪNG NGAY nếu sai, không tự sửa gì):
   - `git remote` của pwd khớp `owner/repo` trong PR URL.
   - Branch hiện tại (`git branch --show-current`) khớp `headRefName` của PR đó.
   - Branch hiện tại KHÔNG khớp CHÍNH XÁC (không phân biệt hoa/thường, không substring) 1 trong:
     `main`, `master`, `production`, `prod`, `staging`, `stg`, `release`, `rls`, `dev`,
     `development`, `develop`.
2. **Bootstrap setting** (chỉ lần đầu trên repo đó — file `fix-pr-meta.json` chưa tồn tại):
   hỏi `decline_needs_confirmation` + `auto_push` (mặc định đề xuất, chờ trả lời), viết file, rồi
   tiếp tục bước 3. Đã có file → đọc thẳng, bỏ qua hỏi.
3. **Nhận diện finding cần xử lý**: `gh api user` lấy account đang chạy → lọc comment top-level
   khớp account + marker `<!-- bot-finding -->` (hoặc fallback pre-marker, theo đúng logic
   `re-review.md`) → GraphQL `reviewThreads` loại thread đã `isResolved: true` → còn lại là danh
   sách finding cần xét. Áp `[chỉ dẫn tự do]` (nếu có) để lọc thêm phạm vi.
4. **Đọc convention dự án** cho mỗi file liên quan (map stack qua `stack-detection.md`, đọc LOCAL
   `ALWAYS_RULE.md` + `memory.md`/`memories/*.md` + template stack — bản LOCAL nếu có, seed nếu
   chưa; repo chưa từng review-pr → bỏ qua, fix theo phán đoán thường).
5. **Xét mỗi finding** (đọc finding gốc + MỌI reply đã có trên đúng thread):
   - Thread đã có human reply rõ ràng (đồng ý/không cần fix) → tôn trọng, bỏ qua hoàn toàn, không
     hỏi lại, không tự fix đè.
   - 🔴 MUST FIX / 🟠 SHOULD FIX → default FIX. Agent tự thấy SAI/không hợp lý → rẽ theo
     `decline_needs_confirmation`: `true` hỏi dev trước khi reply decline, `false` tự quyết luôn.
   - 🔵 SUGGESTION / 📝 NOTE → KHÔNG tự quyết (bất kể setting) — LUÔN nêu recommend (nên/không nên
     + lý do + phạm vi ảnh hưởng), chờ dev chọn.
6. **Gộp câu hỏi**: nếu có ≥1 finding SUGGESTION/NOTE cần hỏi → hỏi TẤT CẢ trong 1 câu duy nhất,
   CHỜ dev trả lời đầy đủ TRƯỚC khi làm bước 7 (không fix phần chắc trước rồi hỏi sau).
7. **Fix**: sửa code cho toàn bộ finding đã quyết fix (MUST/SHOULD + SUGGESTION/NOTE dev chọn),
   đúng convention đọc ở bước 4.
8. **Commit**: `git add` CHỈ file đã sửa (không `-A`/`.`) → 1 commit DUY NHẤT cho cả lượt, message
   theo convention đã học (fallback `fix: address review comments (PR #<n>)` + bullet tóm tắt).
   KHÔNG `--amend`.
9. **Push** theo `auto_push`:
   - `false` (default): dừng ở local, báo dev 1 câu ("đã fix + commit local, nói 'push' khi muốn
     mình đẩy lên + reply luôn"). Dev sau đó gõ ý định push (match theo Ý ĐỊNH, không string cứng)
     → agent push (thường, KHÔNG `--force`) rồi làm bước 10.
   - `true`: `git push` (thường) ngay sau bước 8, rồi làm bước 10 luôn trong lượt.
10. **Reply lên PR** (chỉ sau khi code đã thật sự lên remote):
    - Finding LINE-level đã fix/decline → `POST /pulls/comments/{comment_id}/replies`, nội dung
      ngắn (không kể lể quá trình), kết marker `<!-- bot-reply -->`.
    - Finding OVERVIEW-level (không `line`/`path`) đã fix/decline → GitHub không hỗ trợ reply trực
      tiếp vào review tổng quan → `POST /repos/{owner}/{repo}/issues/{pull_number}/comments`, nội
      dung dẫn link `https://github.com/<owner>/<repo>/pull/<n>#pullrequestreview-<review_id>`
      (KHÔNG blockquote nguyên văn), kết marker `<!-- bot-reply -->`.
    - KHÔNG tự resolve thread bao giờ (không có setting bật auto-resolve cho command này).
11. **Lesson-saving** (bất cứ lúc nào trong flow phát hiện finding phản ánh convention CHUNG của dự
    án, không riêng PR này): đề xuất trong chat (nội dung + tag stack + Recommend nên/không nên +
    lý do), chờ dev xác nhận, chỉ ghi sau khi đồng ý — theo Phần E `setup-flow.md`, dùng chung
    memory.md/ALWAYS_RULE.md của repo.

### Reconfigure trigger

Dev gõ ý định tương đương "đổi cấu hình fix-pr" (khớp theo Ý ĐỊNH) → in giá trị hiện tại của
`fix-pr-meta.json`, hỏi muốn đổi field nào, ghi ngay không cần đợi lần chạy sau.

## 3. Project structure (file mới/sửa)

```
src/commands/fix-pr.md       MỚI — command chính, Bước 0-11 theo mục 2 trên
notebooks/review/<repo>/
  fix-pr-meta.json           MỚI — settings riêng (schema mục 5), SIBLING với meta.json,
                                  KHÔNG chung field, cùng git nested + .gitignore đã có
src/cases/re-review.md            SỬA — thêm marker <!-- bot-reply --> vào cuối reply xác nhận
                                  đã có sẵn ("Xác nhận đã fix, cảm ơn bạn!"/nhánh Đã fix)
CLAUDE.md                         SỬA — thêm fix-pr.md vào bảng cấu trúc + mục kiến trúc
README.md / .en.md / .ja.md       SỬA — thêm mục giới thiệu /tms:fix-pr (dùng khi nào, khác
                                  gì review-pr)
```

Không tạo repo/plugin mới (đã chốt: dùng chung repo `tms-review-pr`, chung plugin `tms`).

## 4. Code style / convention khi viết `fix-pr.md`

Theo đúng convention CHỮ VIẾT đã thiết lập trong `review-pr.md`/`src/cases/*.md`:
- Giọng imperative ngắn, không nhồi chú thích "vì sao" (lý do → CLAUDE.md, không → runtime file).
- Case-specific logic (vd chi tiết resolve GraphQL, chi tiết fallback marker) → tái dùng NGUYÊN
  VĂN kỹ thuật của `re-review.md` bằng cách `Read` file đó thay vì copy-paste lại logic.
- Mọi bullet tiêu chí = gợi ý minh họa, không phải checklist đóng (khớp nguyên tắc chung của repo).
- `allowed-tools` scope theo path/endpoint cụ thể — KHÔNG `gh api:*`/`git:*` chung (xem mục 5).

## 5. `allowed-tools` (frontmatter `fix-pr.md`)

```
Bash(gh pr view:*)
Bash(gh api repos/*/pulls/*/comments:*)          # GET — đọc finding
Bash(gh api repos/*/pulls/*/reviews:*)           # GET — lấy overview + review_id dựng link
Bash(gh api graphql:*)                           # query reviewThreads (đọc isResolved), KHÔNG mutation
Bash(gh api user:*)
Bash(gh api -X POST repos/*/pulls/*/comments/*/replies:*)   # reply LINE-level
Bash(gh api -X POST repos/*/issues/*/comments:*)            # MỚI — reply OVERVIEW-level
Bash(git remote:*)                               # verify owner/repo
Bash(git branch --show-current)                  # verify branch
Bash(git add:*)                                  # chỉ file cụ thể, KHÔNG -A/.
Bash(git commit:*)                               # KHÔNG --amend
Bash(git push:*)                                 # thường, KHÔNG --force/--force-with-lease
Read, Grep, Write, Edit, Agent
```

**KHÔNG cấp** (khác biệt có chủ đích với `review-pr.md`): `gh pr checkout`, `git worktree`,
`gh pr close/merge/reopen`, `git push --force*`, `git branch -D`, `git reset --hard`,
`gh api -X POST .../reviews*` (fix-pr không tạo REVIEW, chỉ reply/comment).

Không giới hạn path cho `Read`/`Edit`/`Write` (khác `review-pr.md` giới hạn qua Bash pattern
`notebooks/review/*/worktrees/*`) — vì chạy trực tiếp tại pwd thật, không có worktree để giới hạn.

## 6. `fix-pr-meta.json` schema

```json
{
  "decline_needs_confirmation": true,
  "auto_push": false
}
```

- `decline_needs_confirmation` (boolean, default `true`): chỉ chi phối nhánh MUST/SHOULD mà agent
  tự thấy sai. KHÔNG áp dụng cho SUGGESTION/NOTE (nhánh đó luôn hỏi, hard rule, không do setting).
- `auto_push` (boolean, default `false`): xem bước 9 mục 2.
- File nằm tại `notebooks/review/<repo>/fix-pr-meta.json` — sibling `meta.json`, không chung
  field, dùng lại git nested + `.gitignore` review-pr đã tạo (không cần `git init`/`.gitignore`
  mới).

## 7. Testing strategy

Plugin này không có test suite tự động (toàn bộ là markdown instruction, không phải code chạy
được độc lập — đúng bản chất repo, xem `CLAUDE.md` mục "Repo là gì"). "Test" = cài plugin
(`./scripts/reinstall.sh`) rồi gọi `/tms:fix-pr <PR_URL thật>` trên 1 PR đã được
`/tms:review-pr` review trước, quan sát:

- Verify context an toàn chặn đúng khi cố tình đứng ở branch khác/repo khác.
- Bootstrap hỏi đúng 2 câu lần đầu, ghi đúng file, không hỏi lại lần 2.
- 1 finding MUST FIX + 1 finding SUGGESTION cùng lúc → hỏi SUGGESTION trước, chờ trả lời, rồi fix
  cả 2 thành 1 commit.
- `auto_push: false` → dừng đúng ở local, reply đúng chỉ sau khi dev gõ ý định push.
- Reply LINE-level lẫn OVERVIEW-level đều đúng endpoint, đúng marker `<!-- bot-reply -->`.
- `re-review.md` sau khi sửa: reply xác nhận cũ vẫn đúng luồng, có thêm marker.

## 8. Boundaries — LUÔN / HỎI TRƯỚC / KHÔNG BAO GIỜ

**LUÔN** (không cần hỏi):
- Verify remote+branch trước khi đụng code.
- Fix MUST/SHOULD khi finding hợp lý và chưa có human reply nào phản đối.
- Gộp toàn bộ fix trong 1 lượt thành đúng 1 commit.
- Đọc convention dự án (ALWAYS_RULE/memory/template) trước khi sửa code.
- Gắn marker `<!-- bot-reply -->` vào mọi reply do lệnh này tạo ra.

**HỎI TRƯỚC** (chờ dev xác nhận):
- Bất kỳ finding SUGGESTION/NOTE (luôn hỏi, không có ngoại lệ).
- Finding MUST/SHOULD mà agent tự thấy sai, khi `decline_needs_confirmation: true`.
- Đề xuất ghi lesson convention chung.
- `auto_push: false` → chờ dev tự ra lệnh push mới push + reply.

**KHÔNG BAO GIỜ**:
- `git commit --amend`, `git push --force`/`--force-with-lease`.
- `git add -A`/`git add .` (chỉ add file đã sửa cho lượt fix).
- Tự resolve thread (mọi trường hợp, không có setting bật).
- Sửa/commit khi đang ở branch bảo vệ (main/master/production/.../develop) hoặc remote/branch
  không khớp PR.
- Kể lể quá trình làm trong reply lên PR hoặc tường thuật chat (chỉ nói kết quả).
- Tự quyết fix/decline một mình cho finding SUGGESTION/NOTE mà không hỏi dev.
