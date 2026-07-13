---
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh pr checkout:*), Bash(gh api:*), Bash(git init:*), Bash(git -C notebooks/review:*), Bash(git fetch:*), Bash(git status:*), Bash(git show:*), Bash(git worktree add notebooks/review/*/worktrees/*), Bash(cd notebooks/review/*/worktrees/* && gh pr checkout:*), Bash(git -C notebooks/review/*/worktrees/* submodule update:*), Bash(cp:*), Bash(mkdir:*), Agent, Read, Grep, Write, Edit
argument-hint: <GitHub PR URL>
description: Review 1 PR GitHub đa stack, học convention riêng theo repo qua memory, post kết quả qua gh api.
---

> **CRITICAL:** CHỈ review + post comment lên PR (Bước 9). Được thêm đúng 1 review lên PR submodule
> khi Bước 1 mục 5 áp dụng (`src/cases/submodule-review.md`). CẤM close/merge/reopen PR, tạo/xoá/đổi
> branch trên repo đang review, push, sửa code — nêu trong review thôi, không tự làm.
> `allowed-tools` đã giới hạn subcommand; `git worktree add` chỉ trong `notebooks/review/*/worktrees/*`.

## Bước 0 — Validate ARGUMENTS

Hợp lệ khi `ARGUMENTS` chứa `github.com/<owner>/<repo>/pull/<number>` (bỏ qua đuôi `/changes`,
query, fragment). Trích `owner` / `repo` / `pull_number` từ phần khớp.

Trống hoặc không có pattern → in lỗi dưới, DỪNG (bỏ qua output `!`...`` Ngữ cảnh nếu đã chạy):

```
❌ Lỗi: Chưa cung cấp URL PR.
Cách dùng: /review:pr <GitHub PR URL>
Ví dụ: /review:pr https://github.com/org/repo/pull/123
```

Phần `ARGUMENTS` ngoài URL = chỉ dẫn bổ sung lần này (ưu tiên hơn default `ALWAYS_RULE.md` nếu hợp
lý). Mọi lệnh `gh` phải dùng canonical URL đã tách (`grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1`), không truyền `$ARGUMENTS` thô.

## Ngữ cảnh

Canonical URL từ `$ARGUMENTS` (cắt đuôi). Mọi `gh pr view`/`gh pr diff` kèm `-R "owner/repo"` tường minh.

- PR info: !`gh pr view "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" -R "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 | sed -E 's#.*github\.com/([^/]+)/([^/]+)/pull/[0-9]+#\1/\2#')" --json number,title,body,author,baseRefName,headRefName 2>/dev/null`
- Head sha: !`gh pr view "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" -R "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 | sed -E 's#.*github\.com/([^/]+)/([^/]+)/pull/[0-9]+#\1/\2#')" --json headRefOid --jq .headRefOid 2>/dev/null`
- Files: !`gh pr diff "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" -R "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 | sed -E 's#.*github\.com/([^/]+)/([^/]+)/pull/[0-9]+#\1/\2#')" --name-only 2>/dev/null`
- Diff: !`gh pr diff "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" -R "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 | sed -E 's#.*github\.com/([^/]+)/([^/]+)/pull/[0-9]+#\1/\2#')" 2>/dev/null`
- Commits: !`gh pr view "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1)" -R "$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 | sed -E 's#.*github\.com/([^/]+)/([^/]+)/pull/[0-9]+#\1/\2#')" --json commits --jq '.commits[].messageHeadline' 2>/dev/null`
- Comments cũ: !`gh api repos/$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 | sed -E 's#.*github\.com/([^/]+)/([^/]+)/pull/([0-9]+)#\1/\2#')/pulls/$(echo "$ARGUMENTS" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | head -1 | sed -E 's#.*/pull/([0-9]+)#\1#')/comments 2>/dev/null`

**Repo name** (thư mục memory) = segment `<repo>` từ PR URL — không suy từ pwd/remote. Hai owner
trùng tên repo dùng chung 1 thư mục (giới hạn đã biết).

**Filesystem:** thao tác tại đúng pwd phiên. Cấm `cd` / tự dò git root (ngoại lệ: subshell worktree
Bước 1). Trước khi ghi `notebooks/review/...`, nêu pwd + repo name trong chat.

## Bước 1 — Worktree ephemeral

Đưa code PR lên đĩa trong worktree riêng (không đụng main tree). Đọc thêm ngoài diff = phán đoán
Bước 7.

1. `git worktree add "notebooks/review/<repo>/worktrees/review-pr<pull_number>-$RANDOM" --detach`
   — tên ngẫu nhiên, không tái dùng. Read/Grep code PR tại `<worktree>/<path>`.
2. `(cd "notebooks/review/<repo>/worktrees/<tên>" && gh pr checkout <pull_number> -R "<owner>/<repo>")`
   — ngoại lệ duy nhất cho cấm `cd` (subshell, neo cứng worktree).
3. `git fetch origin "<baseRefName>"` (refs dùng chung mọi worktree).
4. `git -C "notebooks/review/<repo>/worktrees/<tên>" submodule update --init --recursive` (luôn chạy).
5. Nếu `meta.json.has_submodules == true` VÀ diff có `Subproject commit` → `Read`
   `"${CLAUDE_PLUGIN_ROOT}"/src/cases/submodule-review.md`. Thiếu `meta.json`/field → coi `false`
   (lần đầu trước doctor). Không đủ điều kiện → không đọc case.

Main tree không đổi branch — không khôi phục gì cuối lệnh.

## Bước 2 — Detect stack

Mỗi file trong diff → stack theo `"${CLAUDE_PLUGIN_ROOT}"/src/stack-detection.md` (`Read`). Giữ
`(file, [stacks])` cho Bước 4–7.

## Bước 3 — Setup lần đầu (nếu cần)

`Read` `notebooks/review/<repo>/meta.json`.

- Thiếu file, hoặc `bootstrapped`/`doctored` chưa cùng `true` → `Read`
  `"${CLAUDE_PLUGIN_ROOT}"/src/setup-flow.md`, làm Phần A + C (Phần B ở Bước 4).
- Cả hai `true` → bỏ qua, không đọc `setup-flow.md`.

Giữ từ meta: `auto_submit_review` / `auto_resolve_fixed_findings` (default `false`),
`pr_template_paths` (default `[]`). Sau setup xong: không đụng `notebooks/review/` ngoài Bước 4
(template mới) hoặc Bước 6 (lesson sau xác nhận user).

## Bước 4 — Local template theo stack

Mỗi stack Bước 2: nếu chưa có trong `templates_copied` → `Read` setup-flow Phần B (nếu chưa) và làm
theo; đã có → dùng `notebooks/review/<repo>/templates/<stack>.md`. Chạy mỗi lần (stack mới có thể
xuất hiện sau bootstrap).

## Bước 5 — Nạp rule + memory + template

1. **LOCAL** `notebooks/review/<repo>/ALWAYS_RULE.md` (không đọc seed plugin). Ngôn ngữ output
   (default English), baseline mục 1/2/3/4/6. Tiêu chí = gợi ý, không checklist đóng.
2. `memory.md` + `memories/<lesson>.md` tag trùng stack PR; dòng THAM CHIẾU → đọc path trong repo.
3. Template **LOCAL** theo stack (+ overlay nếu có). Không đọc `${CLAUDE_PLUGIN_ROOT}/src/templates/`.

## Bước 6 — Re-review

Comments từ Ngữ cảnh:

- Không rỗng → `Read` `"${CLAUDE_PLUGIN_ROOT}"/src/cases/re-review.md`.
- Rỗng → bỏ qua, sang Bước 7.

## Bước 7 — Review

**Overview (không tính N, không vào `comments[]`):**

- Title/body mập mờ về business → nêu đầu tổng quan Bước 8; đề nghị dev bổ sung, không viết thay.
- `headRefName` có mã ticket mà title thiếu prefix tương ứng → nêu tổng quan. Branch không có ticket
  → bỏ qua hoàn toàn.

**PR template:** `pr_template_paths` không rỗng → `Read`
`"${CLAUDE_PLUGIN_ROOT}"/src/cases/pr-template-checklist.md`. Rỗng → không đọc.

**Khung 6 mục** = baseline `ALWAYS_RULE` (1–4, 6) + template stack (mục 5 + bổ sung). Gợi ý minh họa
— chủ động tìm thêm ngoài list. Memory bổ sung; mâu thuẫn với `ALWAYS_RULE` → ALWAYS_RULE thắng.

**FILE vs LINE:** phán đoán ngữ cảnh (không enum). LINE: `-` → `side: "LEFT"` (dòng base); `+`/
context → `side: "RIGHT"` (dòng head). FILE → body Bước 8; LINE → `comments[]` Bước 9. Không trộn
FILE vào `comments[]`.

**Phạm vi:**

- Ưu tiên thay đổi in-scope; out-of-scope gắn nhãn riêng, không ép fix.
- Đọc thêm tại `<worktree>/<path>` khi cần; không bắt buộc.
- Diff Ngữ cảnh = nguồn duy nhất cho nội dung đổi — không refetch cùng diff.
- Không đọc source thư viện trừ khi thật không chắc.
- Không bới finding vụn. PR tốt → "LGTM"; không sàn tối thiểu N.

**Format finding** (VI; EN: `**Issue**` / `**Fix**`):

```
**Vấn đề** — <mô tả ngắn>.
**Cách fix** — <code hoặc lời>
*(tuỳ chọn)* vì <1 câu>.
```

Fix bằng code → code block; LINE thay đúng dòng comment → ` ```suggestion `; còn lại → fence ngôn
ngữ thường. Fix không phải code → 1 câu lời, không ép code block.

## Bước 8 — Định dạng

Ngôn ngữ theo `ALWAYS_RULE` (default English):

```
### Nhận xét tổng quan
(2-3 câu hoặc LGTM; + overview title/prefix nếu có)

#### Bắt buộc sửa: N vấn đề
(FILE findings mức này + path; LINE chỉ đếm vào N)
#### Nên sửa: N vấn đề
#### Đề xuất: N vấn đề
```

Nhãn text thuần (EN: MUST FIX / SHOULD FIX / SUGGESTION). N = FILE + LINE. Mức trống → "Không có
vấn đề" (hoặc bản dịch).

## Bước 9 — Post (1 lần POST cho PR chính)

`commit_id` = `headRefOid`. `comments[]` chỉ LINE (`path` + `line` + `side` + `body`). Dùng
`--input -` + heredoc:

```bash
gh api -X POST repos/{owner}/{repo}/pulls/{pull_number}/reviews \
  --input - <<EOF
{
  "body": "<Bước 8>",
  "commit_id": "<headRefOid>",
  "event": "COMMENT",
  "comments": [
    {"path": "<file>", "line": <n>, "side": "<LEFT|RIGHT>", "body": "<finding LINE>"}
  ]
}
EOF
```

- `auto_submit_review: true` → có `"event": "COMMENT"`.
- `false` → bỏ hẳn key `event` (PENDING chủ ý).
- `event` chỉ được `"COMMENT"` — cấm APPROVE / REQUEST_CHANGES.
- POST submodule (nếu Bước 1 mục 5) không tính vào "1 lần" ở đây.

Verify 1 lần: `gh api repos/{owner}/{repo}/pulls/{pull_number}/reviews --jq '.[-1] | {id, state}'`.

- `auto_submit_review: true` + `state: "PENDING"` → POST
  `.../reviews/{id}/events -f event="COMMENT"`.
- `false` + PENDING → báo user review nháp; không submit hộ.

POST lỗi, hoặc verify lệch kỳ vọng → `Read` `"${CLAUDE_PLUGIN_ROOT}"/src/cases/post-review.md`.
Happy path không đọc file đó.

---

ARGUMENTS: $ARGUMENTS
