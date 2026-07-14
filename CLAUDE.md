# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo là gì

Claude Code **plugin** tên `tms` — 1 slash command duy nhất `/tms:review-pr <PR_URL>` để review PR
GitHub đa stack (Rails, Vue, React, Python, Node.js, Lambda, PHP, Laravel, WordPress, Shell,
Makefile), tự học convention riêng theo từng repo được review, post kết quả (summary + inline
line-by-line) trực tiếp lên PR qua `gh api`.

Không có build/lint/test — toàn bộ plugin là markdown (command + template nội dung) và 1 file JSON
cấu hình. Không có runtime code riêng của repo này để chạy/test độc lập; cách "chạy thử" là cài
plugin vào Claude Code rồi gọi `/tms:review-pr <PR_URL>` thật trên 1 repo khác.

## Cấu trúc

Sản phẩm (những gì `${CLAUDE_PLUGIN_ROOT}` trỏ tới lúc runtime) nằm trong `src/` — `src/` CHÍNH LÀ
plugin root thật (có `.claude-plugin/plugin.json` riêng), không phải repo root. Nhờ vậy lúc
`/plugin install`, Claude Code chỉ copy đúng `src/` vào plugin cache — README, CLAUDE.md,
backlogs/, scripts/ ở repo root (phục vụ phát triển repo này) không lọt vào máy user cài plugin.

```
.claude-plugin/marketplace.json  Marketplace tự host (source: "./src") — chỉ copy `src/` vào
                               plugin cache lúc install, không phải cả repo root
src/.claude-plugin/plugin.json   Metadata plugin (name: "tms", trỏ commands: "./commands/" — path
                               tính từ root MỚI là src/, không phải repo root)
scripts/reinstall.sh          Script dev: uninstall/re-add marketplace/install lại (đọc tên qua
                               2 manifest trên, không đụng nội dung src/)
CLAUDE.md                     File này
backlogs/*.md                 Task breakdown lịch sử khi build plugin lần đầu (tạm, sẽ xoá sau
                               khi xong dự án — không phải doc vận hành runtime)
.gitignore                    Dev repo, không liên quan runtime plugin

src/commands/review-pr.md            Slash command DUY NHẤT /tms:review-pr — **thin orchestrator**: mindset +
                               xương quy trình + invariant cứng (giọng imperative ngắn). Không nhồi
                               chú thích "vì sao / đã bug thật" (chúng nằm ở file này, mục D dưới).
                               Chi tiết detect-stack → `src/stack-detection.md`; setup →
                               `src/setup-flow.md`; nhánh theo PR → `src/cases/` (hard gate). CRITICAL
                               + allowed-tools: chỉ review/comment (+ 1 review submodule khi case áp
                               dụng); `gh pr view/diff/checkout`, `gh api`, `git init`,
                               `git -C notebooks/review:*`, `git fetch/status/show`,
                               `git worktree add notebooks/review/*/worktrees/*`,
                               `cd notebooks/review/*/worktrees/* && gh pr checkout`,
                               `git -C notebooks/review/*/worktrees/* submodule update`, `cp`,
                               `mkdir`, `Agent`, `Read`, `Grep`, `Write`, `Edit` — không
                               `gh pr close/merge`, không `git push/branch -D/reset --hard`, không
                               `git branch`/`git checkout` trần
src/stack-detection.md        KHÔNG phải slash command. Bảng mapping đuôi file/path → stack +
                               overlay rule; `review-pr.md` Bước 2 đọc bằng Read
src/setup-flow.md             KHÔNG phải slash command (có ý — xem bên dưới). `review-pr.md` chỉ đọc
                               file này bằng tool Read khi repo CHƯA thiết lập xong, để không tốn
                               context cho nội dung setup ở các lần review sau. Chứa cả Phần E —
                               quy trình ghi lesson vào memory (dùng chung)
src/cases/*.md                KHÔNG phải slash command. Logic review-time CÓ ĐIỀU KIỆN — hard gate
                               boolean trong `review-pr.md`, chỉ `Read` khi trigger đúng. Hiện có:
                               `re-review.md`, `pr-template-checklist.md`, `submodule-review.md`,
                               `post-review.md` (POST lỗi / verify lệch)
src/templates/*.md            Template GỐC (thư viện dùng chung) theo từng ngôn ngữ/framework —
                               nội dung thuần, không logic điều phối. Mỗi repo được review có bản
                               LOCAL copy riêng, xem "Local template" bên dưới
src/ALWAYS_RULE.md            Rule cứng global — bản "seed". Lúc bootstrap 1 repo, được `cp` vào
                               `notebooks/review/<repo>/ALWAYS_RULE.md` (bản LOCAL); từ đó review
                               đọc bản local (team tự chỉnh sửa được), không đọc bản plugin nữa
```

## Kiến trúc cốt lõi

_Trạng thái git: nội dung từ đây trở xuống — cơ chế worktree ephemeral ở Bước 1, `-R owner/repo`
tường minh, và case review submodule — mô tả đúng code hiện có trên branch `feature/pr-review-worktree`,
chưa merge vào `main`, đang trong giai đoạn user tự kiểm thử trước khi merge. Đây là mô tả kiến trúc
THẬT của code trên branch này, không phải kế hoạch dự kiến; khi merge, gộp thẳng vào bản `main` của
file này và bỏ ghi chú trạng thái git này._

**`src/commands/review-pr.md` = thin orchestrator (Bước 0–9).** Validate URL linh hoạt → context
`gh pr view/diff -R owner/repo` → worktree ephemeral + submodule update (Bước 1; hard gate
`submodule-review.md`) → detect stack → setup có điều kiện → local template → nạp ALWAYS_RULE
LOCAL + memory + template → hard gate `re-review.md` / `pr-template-checklist.md` → review 6 mục →
định dạng → 1 POST review PR chính (+ POST submodule nếu case). Happy path Bước 9 đủ schema inline;
POST lỗi hoặc verify lệch → hard gate `post-review.md`. Bước 10: memory/doctor ngoài luồng review
thuần (chat ghi lesson ngay; comment PR phải hỏi; "doctor lại") — nằm trong `review-pr.md`, không
trong seed `ALWAYS_RULE` (user không customize hành vi này).

**Phân loại nội dung runtime (I/C/D/K):** Inline = invariant + xương quy trình; Case = hard gate;
Delete khỏi runtime = lý do bug/lịch sử (chỉ file này); Keep skeleton = khung rút gọn. Mục tiêu:
cắt chú thích thừa trên hot path, giữ chất lượng post/API.

**Quy tắc an toàn CRITICAL (đầu `review-pr.md`, trước Bước 0):** lệnh này CHỈ được review + post 1 review
comment lên PR chính — CỘNG THÊM đúng 1 review nữa lên PR submodule khi case `submodule-review.md`
áp dụng, không hơn. KHÔNG được tự ý close/merge/reopen PR, xoá/tạo/đổi branch trên repo đang review,
push, hay sửa code trong repo đang review, dù phát hiện vấn đề nghiêm trọng tới đâu (chỉ nêu trong
review, không tự hành động). Enforce ở 2 lớp: chữ viết (rule tường minh) + `allowed-tools` thu hẹp
đúng subcommand cần dùng (không có `gh pr close/merge`, không có `git push`/`branch -D`/
`reset --hard`; `git worktree add` và mọi thao tác bên trong worktree đều neo cứng path
`notebooks/review/*/worktrees/*`, không tạo/thao tác được ở nơi khác).

**Bước 1 (worktree ephemeral) đưa code PR vào 1 `git worktree` RIÊNG, không đụng working tree chính
của pwd.** Mục đích không đổi so với thiết kế trước (tận dụng index/search sẵn có của Claude Code/IDE
— không mandate đọc full codebase), nhưng cơ chế khác hẳn: `git worktree add
"notebooks/review/<repo>/worktrees/review-pr<pull_number>-$RANDOM" --detach` tạo 1 thư mục MỚI, TÊN
NGẪU NHIÊN mỗi lần chạy — KHÔNG tái sử dụng/pool/lock (cleanup nằm ngoài phạm vi lệnh này, để lại cho
tooling sau, cố tình đơn giản). `gh pr checkout <pull_number> -R "<owner>/<repo>"` (xử lý đúng cả PR
từ fork) chạy TRONG worktree đó qua subshell `(cd "notebooks/review/<repo>/worktrees/<tên>" && gh pr
checkout ...)` — ngoại lệ DUY NHẤT, có chủ đích, cho rule "cấm `cd`" ở block Ngữ cảnh: rule đó áp dụng
cho pwd CHÍNH của phiên, không áp dụng cho subshell neo cứng đúng thư mục worktree do chính bước này
tạo ra. `git fetch origin "<baseRefName>"` vẫn chạy 1 lần (refs/objects dùng chung giữa mọi worktree
của cùng 1 repo). Ngay sau checkout, `git submodule update --init --recursive` chạy VÔ ĐIỀU KIỆN
trong worktree (vô hại nếu repo không có submodule, và case submodule ở dưới cần thư mục submodule
đã sẵn sàng nếu có). Vì main tree ở pwd KHÔNG BAO GIỜ bị đổi branch/nội dung, 2 cơ chế của thiết kế
trước đã bỏ hoàn toàn: không còn gate "chặn review nếu working tree bẩn" (`git status --porcelain`),
và không còn ghi nhớ/khôi phục branch hiện tại ở cuối lệnh. Từ đây, Read/Grep lên code PR ở các bước
sau (Bước 6, 7) đọc tại `<worktree>/<path>`, không phải tại pwd trực tiếp.

**`-R owner/repo` tường minh cho mọi lệnh `gh pr`.** Cả block "Ngữ cảnh" (`gh pr view`/`gh pr diff`,
chạy trước khi worktree tồn tại) lẫn Bước 1 (`gh pr checkout`) đều truyền `-R "<owner>/<repo>"` tường
minh (parse từ PR URL) thay vì để `gh` tự đoán remote qua git config local của pwd — tránh lỗi khi
pwd có nhiều remote hoặc không remote nào khớp đúng repo đang review.

**Cô lập giữa các lần review chạy song song, không cần lock.** Vì tên worktree ngẫu nhiên và không
tái sử dụng, nhiều lần `/tms:review-pr` chạy đồng thời (cùng PR hay khác PR, cùng hay khác repo) luôn có
thư mục riêng biệt, không đụng nhau. Rủi ro còn lại (thấp, CHẤP NHẬN, không xây lock cho case hiếm
này): `meta.json`/`memory.md` là file DÙNG CHUNG giữa các lần chạy của CÙNG 1 repo — 2 phiên ghi đồng
thời đúng lúc setup/thêm template có thể mất 1 write.

**Tên thư mục memory (`repo name`) = CHÍNH segment `<repo>` cắt từ PR URL — định nghĩa DUY NHẤT.**
Không suy tên repo từ basename pwd/thư mục con/git remote (nếu không, 2 PR cùng repo sẽ tạo 2 thư
mục khác nhau — chính bug đã gặp). Mọi thao tác filesystem thực hiện tại ĐÚNG pwd hiện tại của phiên;
`review-pr.md`/`src/setup-flow.md` cấm `cd`, cấm tự dò "git root"/"repo thật sự", cấm tự "thông minh" điều hướng
khỏi pwd. (Thuật ngữ cũ "short_name" đã bỏ hoàn toàn — dùng "repo name".)

**Kỷ luật phạm vi review (Bước 7):** tập trung phần THAY ĐỔI in-scope; vấn đề code cũ ngoài phạm
vi, hoặc chưa cần fix ngay trong PR này, gắn nhãn 📝 NOTE riêng — không ép fix, không tính vào 3
mức nghiêm trọng. KHÔNG đọc source thư viện/framework như thói quen (dựa kiến thức chung trước,
chỉ tra source khi thật sự không chắc). Diff đã fetch 1 lần ở Ngữ cảnh là nguồn duy nhất — không
refetch qua `git diff`/`gh api .../files` per file. KHÔNG bới finding vụn vặt lấy số lượng — PR
hoàn toàn sạch thì **LGTM 🌟** (đậm, kèm emoji), không viết "không có vấn đề" cho từng mức rỗng.
Nhãn 3 mức nghiêm trọng dùng emoji ASCII thay text: 🔴 MUST FIX (Bắt buộc sửa) / 🟠 SHOULD FIX
(Nên sửa) / 🔵 SUGGESTION (Đề xuất) — áp cho cả FILE (heading Bước 8) lẫn LINE (prefix ngay trong
`comments[]`, không chỉ nhóm theo heading).

**Finding cấp LINE xác định `side` theo đúng nửa diff, không hardcode.** Bước 7 xác định `side` cho
mỗi finding cấp LINE dựa vào vị trí thật trong diff: dòng bị XOÁ (tiền tố `-`, thuộc nửa CŨ/before)
→ `side: "LEFT"`, số dòng lấy theo file CŨ (base); dòng THÊM hoặc GIỮ NGUYÊN (tiền tố `+` hoặc dòng
context, thuộc nửa MỚI/after) → `side: "RIGHT"`, số dòng lấy theo file MỚI (head). Không mặc định
`RIGHT` cho mọi trường hợp — sai `side` khiến GitHub gắn comment nhầm dòng hoặc từ chối payload.

**Finding cấp FILE nằm trong body tổng quan, KHÔNG vào `comments[]` (Bước 8/9).** GitHub reviews
API 422 "position null" khi trộn comment không-line chung request với comment có-line (đã gặp thật)
— nên `comments[]` chỉ chứa finding cấp LINE; finding cấp FILE thành bullet trong body dưới đúng
heading emoji mức nghiêm trọng. **Body tổng quan CẤM paste lại Vấn đề/Cách fix của LINE** (đã có
inline, đã trực quan theo đúng dòng diff) — overview không liệt kê lại, không đếm số lượng LINE
finding dưới bất kỳ hình thức nào; tránh duplicate tốn token. Verify sau post (Bước 9) bó hẹp đúng
1 lần check state;
lỗi POST → `post-review.md`, retry 1 lần, KHÔNG tạo/xoá comment test trên PR thật.

**`src/cases/` — logic review-time có điều kiện theo TỪNG PR, không phải theo trạng thái repo.**
Khác `setup-flow.md` (gate theo trạng thái CỦA REPO — đã bootstrap/doctor chưa, chạy 1 lần) và
`stack-detection.md` (bảng tra cứu, đọc MỌI lần review bất kể PR), mỗi file trong `src/cases/` gắn
với 1 trigger riêng CỦA PR ĐANG REVIEW — `review-pr.md` chỉ `Read` file đó khi trigger đúng, nên nhiều PR
không bao giờ tốn context cho case không áp dụng. Hiện có:

- `re-review.md` — trigger: PR đã có comment review cũ (fetch 1 lần ở block "Ngữ cảnh", dùng ở
  Bước 6). Gồm 2 việc dùng chung dữ liệu đã fetch: đề xuất 1 lesson convention mới nếu phát hiện
  đồng thuận trong reply chain của thread (CHỜ user xác nhận trong chat trước khi ghi — comment PR
  không tự tin cậy, tránh nhét rule giả; khác góp ý trong chat session → ghi ngay), VÀ
  kiểm tra finding cũ do chính lệnh này để lại (lọc comment top-level của tài khoản đang chạy lệnh,
  khớp khung emoji-mở-đầu + `**Gợi ý**`) đã được fix chưa — đã fix thì reply ngắn xác nhận, rồi rẽ theo
  `auto_resolve_fixed_findings` (xem cấu hình bên dưới) để quyết định có resolve thread qua GraphQL
  (`resolveReviewThread`, REST không hỗ trợ resolve) hay chỉ reply; chưa fix thì không làm gì,
  không nhắc lại.
- `pr-template-checklist.md` — trigger: repo có file dạng `.github/PULL_REQUEST_TEMPLATE.md` (phát
  hiện 1 lần lúc doctor, cache tại `meta.json.pr_template_paths`, dùng ở Bước 7). Đối chiếu
  description thật của PR với checklist trong template đó, gộp mọi mục còn thiếu/chưa tick thành
  ĐÚNG 1 finding tổng hợp cấp FILE mức `🟠 SHOULD FIX`. Khác 2 kiểm tra title/description còn lại của
  Bước 7 (rõ business, prefix ticket theo branch) — 2 kiểm tra đó chỉ mang tính overview, KHÔNG tính
  vào 3 mức nghiêm trọng; kiểm tra checklist này CÓ tính, vì đây là vi phạm 1 rule dự án tự đặt ra
  qua PR template, không chỉ là góp ý phong cách.
- `submodule-review.md` — trigger: `meta.json.has_submodules == true` (detect đúng 1 lần lúc doctor,
  check `.gitmodules` tại root repo) VÀ "Diff đầy đủ" của PR chính chứa dòng `Subproject commit`
  (submodule pointer đổi), dùng ở Bước 1 mục 5. KHÔNG tạo worktree thứ 2 cho submodule — tái dùng
  đúng thư mục submodule đã init sẵn trong worktree (từ `git submodule update --init --recursive` ở
  Bước 1); tìm link PR submodule trong description của PR chính (không tìm được thì HỎI user, không
  tự đoán/bỏ qua), checkout PR đó VÀO ĐÚNG thư mục submodule, rồi review ĐẦY ĐỦ như 1 PR độc lập
  (lặp lại Bước 2→8 của `review-pr.md` cho diff submodule) — DÙNG CHUNG memory/template của repo CHÍNH
  (KHÔNG tạo `notebooks/review/<tên-submodule>/` riêng), rồi post ĐÚNG 1 review RIÊNG lên chính PR
  submodule đó (khác PR, có thể khác repo, nên không tính vào ràng buộc "1 lần POST duy nhất" của PR
  chính ở Bước 9). KHÔNG xử lý submodule LỒNG submodule (nếu diff của PR submodule lại có
  `Subproject commit` của chính nó — dừng, chỉ ghi chú trong output, không đệ quy tầng 2).
- `post-review.md` — trigger: POST review lỗi **hoặc** verify `state` lệch kỳ vọng
  `auto_submit_review`. Retry 1 lần theo schema; cấm comment/review test trên PR thật; nhánh
  submit-events khi `true` mà vẫn PENDING. Happy path không đọc file này.

Thư mục này CHỦ Ý để MỞ RỘNG: case mới = hard gate boolean + 1 file, không nhét vào `review-pr.md`.

**Lý do bug đã gặp (D — không đưa lại runtime `review-pr.md`):** API 422 "position null" khi trộn comment
không-line với có-line → FILE chỉ trong body, LINE trong `comments[]`. Debug bằng post/xoá comment
test từng để lại nhiều review object → cấm; sửa schema rồi retry 1 lần rồi dừng. Sai `side`
LEFT/RIGHT gắn comment nhầm dòng. Thiếu `event` khi `auto_submit_review: true` → PENDING ngoài ý
muốn (dev không thấy). Repo name suy từ pwd từng tạo 2 thư mục memory cho cùng 1 repo GitHub.

**Cấu hình per-repo hỏi 1 lần lúc bootstrap, dùng lại mọi lần review sau của repo đó.** Phần A của
`setup-flow.md` hỏi user **4 câu** trong 1 lượt: ngôn ngữ output (vi/en/ja), `auto_submit_review`
(mặc định `false`), `auto_resolve_fixed_findings` (mặc định `false`), `doctor_schedule` (mặc định
`"1 months"`; giá trị `{N} days|weeks|months` hoặc `never`).

- Ngôn ngữ: thay placeholder `{{OUTPUT_LANGUAGE}}` trong LOCAL `ALWAYS_RULE.md` — không lưu
  `meta.json`. Chỉ dẫn ngôn ngữ trong ARGUMENTS/chat phiên thắng giá trị file (chỉ lần đó).
- `auto_submit_review`/`auto_resolve_fixed_findings`/`doctor_schedule` → `meta.json`; đọc Bước 3.
  Bootstrap cũng ghi `_comments.doctor_schedule` (chú thích giá trị hợp lệ cho sửa tay; runtime bỏ qua).
- `doctor_schedule` + `doctored_at`: Bước 3 tính `doctor_due` → hết hạn thì chỉ chạy lại Phần C
  (không hỏi bootstrap lại). `never` = không tự due theo lịch. Repo cũ thiếu field → coi
  `"1 months"`.
- `auto_submit_review` chi phối payload Bước 9: `true` → `"event": "COMMENT"`; `false` → bỏ `event`
  (PENDING chủ ý).
- `auto_resolve_fixed_findings` chi phối nhánh finding đã fix trong `re-review.md`.

**Setup tách khỏi review, nạp có điều kiện qua `Read`, không qua bash-gate.** `review-pr.md` chỉ dùng
`Read` để nạp `src/setup-flow.md` khi `meta.json` của repo cho thấy CHƯA thiết lập xong (bootstrap +
doctor) — nếu đã xong, không `Read` file đó, nội dung setup không vào context của lần review đó.
Lý do dùng `Read` (tool call, agent tự quyết định lúc reasoning) thay vì `!`...`` bash substitution:
mọi lệnh `!`...`` trong 1 command file chạy **trước khi model thấy prompt**, không thể điều kiện
theo kết quả suy luận (vd stack nào đã detect) — chỉ tool call thật sự (Read) mới sequence đúng
theo logic của agent.

**Local template = bản có hiệu lực cho từng repo, không phải `${CLAUDE_PLUGIN_ROOT}/templates/`
trực tiếp.** Lần đầu 1 stack xuất hiện trong 1 repo, `review-pr.md` (qua `src/setup-flow.md` Phần B) copy
template gốc từ plugin vào `notebooks/review/<repo>/templates/<stack>.md` **bằng `cp`** (không
Read+Write qua context — tiết kiệm token với file dài; chỉ nhánh "plugin chưa có template, agent tự
soạn mới" mới dùng Read tham khảo + Write lưu). Team có thể tự
sửa bản local này riêng cho repo mà không ảnh hưởng plugin dùng chung. Nếu plugin CHƯA có template
cho 1 stack nào đó, agent tự soạn mới (theo đúng khung 6 mục) và lưu local — đây là cơ chế "tự cải
thiện" (self-improve) của plugin, không phải bộ tiêu chí đóng cứng. Việc đưa 1 template mới do agent
tự soạn ngược trở lại `${CLAUDE_PLUGIN_ROOT}/templates/` để dùng chung cho repo khác là thao tác
THỦ CÔNG của user, KHÔNG tự động (tránh mutate file dùng chung từ ngữ cảnh 1 repo cụ thể).

**Baseline (ALWAYS_RULE.md) + delta (templates/) — không lặp nội dung.** Tiêu chí CHUNG cho mọi
stack (mục 1,2,3,4,6 — bug/logic rõ ràng, hardcode secret, DRY, tên biến rõ ràng, comment logic
phức tạp, test coverage, thiết kế linh hoạt) sống trong `src/ALWAYS_RULE.md`, luôn nạp cho MỌI PR bất
kể stack. Mỗi file trong `src/templates/` CHỈ chứa tiêu chí ĐẶC THÙ của stack đó (toàn bộ mục 5 "Đặc thù
framework/language" không có baseline, luôn 100% từ template). Khi thêm/sửa tiêu chí, tự hỏi "đây
có áp dụng được cho stack khác không" — nếu có, nó thuộc `src/ALWAYS_RULE.md`, không phải template.

**Template = nền + overlay, không lặp nội dung.** `lambda-common.md` chồng lên
`python.md`/`nodejs.md`; `laravel.md`/`wordpress.md` chồng lên `php.md` — các file overlay này CHỈ
chứa tiêu chí đặc thù serverless/framework, cố tình không lặp lại rule đã có ở template nền HAY ở
baseline. Khi sửa template nền, kiểm tra overlay tương ứng có bị trùng/mâu thuẫn không.

**Mọi danh sách tiêu chí (baseline lẫn template) là gợi ý minh họa, không phải checklist đóng.**
Tránh viết dạng liệt kê khiến agent hiểu nhầm là chỉ cần tìm đúng những ý đã ghi — luôn giữ khung
câu kiểu "ví dụ, không giới hạn ở đây" khi thêm tiêu chí mới.

**Memory là state runtime, sống ngoài repo này.** `notebooks/review/<repo>/{memory.md,
memories/, templates/, ALWAYS_RULE.md, meta.json, worktrees/}` được `/tms:review-pr` tự tạo bên trong
repo đang được review (không phải trong plugin), có git nested riêng (không push). Bootstrap +
doctor (`meta.json.bootstrapped`/`.doctored`) chỉ chạy 1 lần; local template copy
(`meta.json.templates_copied`) chạy lại mỗi khi gặp stack chưa từng thấy ở repo đó, kể cả sau khi đã
bootstrap/doctor xong lâu rồi — đây là 2 điều kiện khác nhau, đừng gộp chung 1 gate. `worktrees/`
chứa các worktree ephemeral của Bước 1 (code PR thật, KHÔNG phải memory) — bootstrap ghi dòng
`worktrees/` vào `notebooks/review/.gitignore` (file riêng của git nested, khác `.gitignore` của repo
chính) để code PR checkout vào đó không bao giờ lọt vào git nested này, vốn chỉ nên chứa
memory/template/rule. Đừng nhầm thư mục `notebooks/review/` này là dữ liệu của plugin repo này.

**`src/ALWAYS_RULE.md` luôn thắng memory nếu mâu thuẫn.** Rule cứng global. Seed
`${CLAUDE_PLUGIN_ROOT}/ALWAYS_RULE.md` được `cp` sang LOCAL lúc bootstrap; Bước 5 đọc LOCAL.
Ngôn ngữ = placeholder `{{OUTPUT_LANGUAGE}}` điền lúc bootstrap (không còn "default rồi ghi đè").
Hành vi memory/doctor ngoài luồng (Bước 10) nằm trong `review-pr.md`, không trong seed. **Không
auto-migrate** local đã bootstrap — copy tay section mới nếu cần (xem README).

**Doctor (setup-flow Phần C)** quét TOÀN REPO khi lần đầu, khi `doctor_schedule` hết hạn
(`doctored_at`), hoặc user "doctor lại". Không giới hạn theo stack PR. Subagent song song. Ghi
THAM CHIẾU path vào `memory.md`; mâu thuẫn → lesson Phần E không hỏi user.

**Phân loại file-level vs line-level finding là phán đoán ngữ cảnh của agent lúc review**, cố tình
không có danh sách cứng/enum trong `review-pr.md` — đừng thêm danh sách cứng vào đó khi sửa.

## Khi thêm 1 stack mới

Theo đúng pattern trong `backlogs/templates.md`: viết 1 file `src/templates/<stack>.md` theo khung 6
mục, mở đầu bằng `# <Tên stack>` + 1 dòng note metadata italic (`_Bổ sung cho baseline
`src/ALWAYS_RULE.md`; ..._`) như các template hiện có; nếu là biến thể/sub-framework của 1 ngôn ngữ đã
có (ví dụ 1 framework PHP khác ngoài Laravel/WordPress) thì viết dạng overlay (note ghi rõ `_Overlay
chồng lên `<nền>.md`, ..._`) thay vì lặp rule nền. Sau đó cập nhật bảng mapping đuôi file/path →
stack trong `src/stack-detection.md`.
