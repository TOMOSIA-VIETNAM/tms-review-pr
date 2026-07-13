# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo là gì

Claude Code **plugin** tên `review` — 1 slash command duy nhất `/review:pr <PR_URL>` để review PR
GitHub đa stack (Rails, Vue, React, Python, Node.js, Lambda, PHP, Laravel, WordPress, Shell,
Makefile), tự học convention riêng theo từng repo được review, post kết quả (summary + inline
line-by-line) trực tiếp lên PR qua `gh api`.

Không có build/lint/test — toàn bộ plugin là markdown (command + template nội dung) và 1 file JSON
cấu hình. Không có runtime code riêng của repo này để chạy/test độc lập; cách "chạy thử" là cài
plugin vào Claude Code rồi gọi `/review:pr <PR_URL>` thật trên 1 repo khác.

## Cấu trúc

Sản phẩm (những gì `${CLAUDE_PLUGIN_ROOT}` trỏ tới lúc runtime) nằm trong `src/`; phần phục vụ
phát triển repo này nằm ở root, tách bạch khỏi nội dung plugin thật sự chạy.

```
.claude-plugin/plugin.json   Metadata plugin (name: "review", trỏ commands: "./src/commands/")
.claude-plugin/marketplace.json  Marketplace tự host (source: "./") — root plugin không đổi dù
                               nội dung bên trong tổ chức lại vào src/
scripts/reinstall.sh          Script dev: uninstall/re-add marketplace/install lại (đọc tên qua
                               2 manifest trên, không đụng src/)
CLAUDE.md                     File này
backlogs/*.md                 Task breakdown lịch sử khi build plugin lần đầu (tạm, sẽ xoá sau
                               khi xong dự án — không phải doc vận hành runtime)
.gitignore                    Dev repo, không liên quan runtime plugin

src/commands/pr.md            Slash command DUY NHẤT /review:pr — CHỈ chứa logic review, không
                               chứa chi tiết detect-stack (xem src/stack-detection.md) hay thiết
                               lập lần đầu (xem src/setup-flow.md). Mở đầu bằng 1 quy tắc an toàn
                               CRITICAL (chỉ review + comment, không close/merge/push/xoá branch).
                               allowed-tools thu hẹp đúng subcommand cần dùng: `gh pr view`,
                               `gh pr diff`, `gh api`, `git init`, `git -C notebooks/review:*`,
                               `git fetch`, `git status`, `git show`, `cp`, `mkdir`, `Agent`
                               (doctor song song), `Read`, `Write`, `Edit` — KHÔNG có
                               `gh pr close/merge`, KHÔNG có `git push/branch -D/reset --hard`
src/stack-detection.md        KHÔNG phải slash command. Bảng mapping đuôi file/path → stack +
                               overlay rule; `pr.md` Bước 2 đọc bằng Read
src/setup-flow.md             KHÔNG phải slash command (có ý — xem bên dưới). `pr.md` chỉ đọc
                               file này bằng tool Read khi repo CHƯA thiết lập xong, để không tốn
                               context cho nội dung setup ở các lần review sau. Chứa cả Phần E —
                               quy trình ghi lesson vào memory (dùng chung)
src/templates/*.md            Template GỐC (thư viện dùng chung) theo từng ngôn ngữ/framework —
                               nội dung thuần, không logic điều phối. Mỗi repo được review có bản
                               LOCAL copy riêng, xem "Local template" bên dưới
src/ALWAYS_RULE.md            Rule cứng global — bản "seed". Lúc bootstrap 1 repo, được `cp` vào
                               `notebooks/review/<repo>/ALWAYS_RULE.md` (bản LOCAL); từ đó review
                               đọc bản local (team tự chỉnh sửa được), không đọc bản plugin nữa
```

## Kiến trúc cốt lõi

**`src/commands/pr.md`** encode 11 bước tuần tự (Bước 0-10): validate — nhận diện linh hoạt 1 tham
chiếu PR GitHub bất kể phần đuôi (`/changes`, `/files`, query, fragment), chỉ trích
`owner/repo/pull_number` từ phần khớp → lấy context qua `gh pr view/diff` → đồng bộ local cho
source/target branch + chặn review nếu working tree bẩn → detect stack theo đuôi file/path cho
từng file trong diff → thiết lập lần đầu nếu cần (đọc `src/setup-flow.md` có điều kiện) → đảm bảo
có local template cho từng stack → nạp `src/ALWAYS_RULE.md` LOCAL + memory + template local → đọc
lại comment cũ của chính PR để phát hiện đồng thuận convention mới (re-review) → review theo khung
6 mục → định dạng kết quả → post đúng 1 lần qua `gh api POST .../pulls/{n}/reviews`.

**Quy tắc an toàn CRITICAL (đầu `pr.md`, trước Bước 0):** lệnh này CHỈ được review + post 1 review
comment — KHÔNG được tự ý close/merge/reopen PR, xoá/tạo/đổi branch, push, hay sửa code trong repo
đang review, dù phát hiện vấn đề nghiêm trọng tới đâu (chỉ nêu trong review, không tự hành động).
Enforce ở 2 lớp: chữ viết (rule tường minh) + `allowed-tools` thu hẹp đúng subcommand cần dùng
(không có `gh pr close/merge`, không có `git push`/`branch -D`/`reset --hard`).

**Bước 1 (đồng bộ local) đưa code PR lên đĩa để tận dụng index/search sẵn có của Claude Code/IDE —
không phải để mandate đọc full codebase.** Ghi nhớ branch hiện tại → `git status --porcelain`
bẩn thì dừng TOÀN BỘ review (yêu cầu commit/`git stash` trước) → `gh pr checkout <pull_number>`
(xử lý đúng cả PR từ fork) đưa code PR vào working tree, `git fetch origin <base>` để `git show
<base>:<path>` dùng được khi cần so sánh. Việc đọc thêm ngoài diff (mức độ, phạm vi) là PHÁN ĐOÁN
của agent lúc review (Bước 7), không phải bước này ép buộc. Sau khi post review xong (Bước 9),
checkout lại đúng branch đã ghi nhớ — không để user kết thúc phiên trên nhánh khác.

**Tên thư mục memory (`repo name`) = CHÍNH segment `<repo>` cắt từ PR URL — định nghĩa DUY NHẤT.**
Không suy tên repo từ basename pwd/thư mục con/git remote (nếu không, 2 PR cùng repo sẽ tạo 2 thư
mục khác nhau — chính bug đã gặp). Mọi thao tác filesystem thực hiện tại ĐÚNG pwd hiện tại của phiên;
`pr.md`/`src/setup-flow.md` cấm `cd`, cấm tự dò "git root"/"repo thật sự", cấm tự "thông minh" điều hướng
khỏi pwd. (Thuật ngữ cũ "short_name" đã bỏ hoàn toàn — dùng "repo name".)

**Kỷ luật phạm vi review (Bước 6/7):** tập trung phần THAY ĐỔI in-scope; vấn đề code cũ ngoài phạm
vi thì tách riêng nhãn "ngoài phạm vi", không ép fix. KHÔNG đọc source thư viện/framework như thói
quen (dựa kiến thức chung trước, chỉ tra source khi thật sự không chắc). KHÔNG bới finding vụn vặt
lấy số lượng — PR tốt thì "LGTM". Nhãn 3 mức nghiêm trọng là TEXT thuần (Bắt buộc sửa / Nên sửa /
Đề xuất; EN: MUST FIX / SHOULD FIX / SUGGESTION) — KHÔNG dùng emoji màu.

**Setup tách khỏi review, nạp có điều kiện qua `Read`, không qua bash-gate.** `pr.md` chỉ dùng
`Read` để nạp `src/setup-flow.md` khi `meta.json` của repo cho thấy CHƯA thiết lập xong (bootstrap +
doctor) — nếu đã xong, không `Read` file đó, nội dung setup không vào context của lần review đó.
Lý do dùng `Read` (tool call, agent tự quyết định lúc reasoning) thay vì `!`...`` bash substitution:
mọi lệnh `!`...`` trong 1 command file chạy **trước khi model thấy prompt**, không thể điều kiện
theo kết quả suy luận (vd stack nào đã detect) — chỉ tool call thật sự (Read) mới sequence đúng
theo logic của agent.

**Local template = bản có hiệu lực cho từng repo, không phải `${CLAUDE_PLUGIN_ROOT}/src/templates/`
trực tiếp.** Lần đầu 1 stack xuất hiện trong 1 repo, `pr.md` (qua `src/setup-flow.md` Phần B) copy
template gốc từ plugin vào `notebooks/review/<repo>/templates/<stack>.md` **bằng `cp`** (không
Read+Write qua context — tiết kiệm token với file dài; chỉ nhánh "plugin chưa có template, agent tự
soạn mới" mới dùng Read tham khảo + Write lưu). Team có thể tự
sửa bản local này riêng cho repo mà không ảnh hưởng plugin dùng chung. Nếu plugin CHƯA có template
cho 1 stack nào đó, agent tự soạn mới (theo đúng khung 6 mục) và lưu local — đây là cơ chế "tự cải
thiện" (self-improve) của plugin, không phải bộ tiêu chí đóng cứng. Việc đưa 1 template mới do agent
tự soạn ngược trở lại `${CLAUDE_PLUGIN_ROOT}/src/templates/` để dùng chung cho repo khác là thao tác
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
memories/, templates/, ALWAYS_RULE.md, meta.json}` được `/review:pr` tự tạo bên trong repo đang được review (không
phải trong plugin), có git nested riêng (không push). Bootstrap + doctor (`meta.json.bootstrapped`/
`.doctored`) chỉ chạy 1 lần; local template copy (`meta.json.templates_copied`) chạy lại mỗi khi
gặp stack chưa từng thấy ở repo đó, kể cả sau khi đã bootstrap/doctor xong lâu rồi — đây là 2 điều
kiện khác nhau, đừng gộp chung 1 gate. Đừng nhầm thư mục này là dữ liệu của plugin repo này.

**`src/ALWAYS_RULE.md` luôn thắng memory nếu mâu thuẫn.** Đây là rule cứng global (vd ngôn ngữ output,
default English). Bản plugin `${CLAUDE_PLUGIN_ROOT}/src/ALWAYS_RULE.md` (biến môi trường chuẩn Claude
Code, portable mọi máy — KHÔNG hardcode path tuyệt đối của 1 máy cụ thể) là "seed", được `cp` sang
bản LOCAL `notebooks/review/<repo>/ALWAYS_RULE.md` lúc bootstrap; review (Bước 5) đọc bản LOCAL —
khác với convention riêng từng repo nằm trong `memory.md`.

**Doctor (setup-flow Phần C) quét TOÀN REPO, 1 lần duy nhất, dùng subagent song song.** Không giới
hạn theo stack/tính năng của PR hiện tại: quét ĐỆ QUY toàn cây thư mục tìm HẾT nguồn convention
(`README.md`/`CLAUDE.md`/`AGENTS.md`/`GEMINI.md`/`docs/`/`wiki/`/cursor/copilot rules) kể cả nằm sâu
ở subfolder (dự án thật có nhiều `AGENTS.md` rải rác). Dùng `Agent` spawn subagent: 1 quét cây thư
mục ra danh sách file, nhiều subagent song song đọc+tóm tắt từng file. Gate `doctored` chặn chạy lại
tự động — chỉ chạy lại khi user chủ động yêu cầu "doctor lại". Vẫn ghi THAM CHIẾU (path, không copy
nội dung) vào `memory.md`; mâu thuẫn thì reconcile thành 1 lesson (Phần E) không cần hỏi user.

**Phân loại file-level vs line-level finding là phán đoán ngữ cảnh của agent lúc review**, cố tình
không có danh sách cứng/enum trong `pr.md` — đừng thêm danh sách cứng vào đó khi sửa.

## Khi thêm 1 stack mới

Theo đúng pattern trong `backlogs/templates.md`: viết 1 file `src/templates/<stack>.md` theo khung 6
mục, mở đầu bằng `# <Tên stack>` + 1 dòng note metadata italic (`_Bổ sung cho baseline
`src/ALWAYS_RULE.md`; ..._`) như các template hiện có; nếu là biến thể/sub-framework của 1 ngôn ngữ đã
có (ví dụ 1 framework PHP khác ngoài Laravel/WordPress) thì viết dạng overlay (note ghi rõ `_Overlay
chồng lên `<nền>.md`, ..._`) thay vì lặp rule nền. Sau đó cập nhật bảng mapping đuôi file/path →
stack trong `src/stack-detection.md`.
