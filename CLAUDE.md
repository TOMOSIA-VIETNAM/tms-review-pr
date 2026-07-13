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

```
.claude-plugin/plugin.json   Metadata plugin (name: "review", trỏ commands: "./commands/")
commands/pr.md                Slash command DUY NHẤT /review:pr — CHỈ chứa logic review, không
                               chứa chi tiết detect-stack (xem stack-detection.md) hay thiết lập
                               lần đầu (xem setup-flow.md)
stack-detection.md            KHÔNG phải slash command (ngoài commands/). Bảng mapping đuôi
                               file/path → stack + overlay rule; `pr.md` Bước 1 đọc bằng Read
setup-flow.md                 KHÔNG phải slash command (nằm ngoài commands/, có ý — xem bên dưới).
                               `pr.md` chỉ đọc file này bằng tool Read khi repo CHƯA thiết lập
                               xong, để không tốn context cho nội dung setup ở các lần review sau.
                               Chứa cả Phần E — quy trình ghi lesson vào memory (dùng chung)
templates/*.md                Template GỐC (thư viện dùng chung) theo từng ngôn ngữ/framework —
                               nội dung thuần, không logic điều phối. Mỗi repo được review có bản
                               LOCAL copy riêng, xem "Local template" bên dưới
ALWAYS_RULE.md                Rule cứng global, áp dụng mọi repo được review qua plugin này
backlogs/*.md                 Task breakdown lịch sử khi build plugin lần đầu (tham khảo khi mở
                               rộng thêm stack/tính năng, không phải doc vận hành runtime)
```

## Kiến trúc cốt lõi

**`commands/pr.md`** encode 10 bước tuần tự: validate URL PR → lấy context qua `gh pr view/diff` →
detect stack theo đuôi file/path cho từng file trong diff → thiết lập lần đầu nếu cần (đọc
`setup-flow.md` có điều kiện) → đảm bảo có local template cho từng stack → nạp `ALWAYS_RULE.md` +
memory + template local → đọc lại comment cũ của chính PR để phát hiện đồng thuận convention mới
(re-review) → review theo khung 6 mục → định dạng kết quả → post đúng 1 lần qua
`gh api POST .../pulls/{n}/reviews`.

**Setup tách khỏi review, nạp có điều kiện qua `Read`, không qua bash-gate.** `pr.md` chỉ dùng
`Read` để nạp `setup-flow.md` khi `meta.json` của repo cho thấy CHƯA thiết lập xong (bootstrap +
doctor) — nếu đã xong, không `Read` file đó, nội dung setup không vào context của lần review đó.
Lý do dùng `Read` (tool call, agent tự quyết định lúc reasoning) thay vì `!`...`` bash substitution:
mọi lệnh `!`...`` trong 1 command file chạy **trước khi model thấy prompt**, không thể điều kiện
theo kết quả suy luận (vd stack nào đã detect) — chỉ tool call thật sự (Read) mới sequence đúng
theo logic của agent.

**Local template = bản có hiệu lực cho từng repo, không phải `${CLAUDE_PLUGIN_ROOT}/templates/`
trực tiếp.** Lần đầu 1 stack xuất hiện trong 1 repo, `pr.md` (qua `setup-flow.md` Phần B) copy
template gốc từ plugin vào `notebooks/review/<short_name>/templates/<stack>.md` — team có thể tự
sửa bản local này riêng cho repo mà không ảnh hưởng plugin dùng chung. Nếu plugin CHƯA có template
cho 1 stack nào đó, agent tự soạn mới (theo đúng khung 6 mục) và lưu local — đây là cơ chế "tự cải
thiện" (self-improve) của plugin, không phải bộ tiêu chí đóng cứng. Việc đưa 1 template mới do agent
tự soạn ngược trở lại `${CLAUDE_PLUGIN_ROOT}/templates/` để dùng chung cho repo khác là thao tác
THỦ CÔNG của user, KHÔNG tự động (tránh mutate file dùng chung từ ngữ cảnh 1 repo cụ thể).

**Baseline (ALWAYS_RULE.md) + delta (templates/) — không lặp nội dung.** Tiêu chí CHUNG cho mọi
stack (mục 1,2,3,4,6 — bug/logic rõ ràng, hardcode secret, DRY, tên biến rõ ràng, comment logic
phức tạp, test coverage, thiết kế linh hoạt) sống trong `ALWAYS_RULE.md`, luôn nạp cho MỌI PR bất
kể stack. Mỗi file trong `templates/` CHỈ chứa tiêu chí ĐẶC THÙ của stack đó (toàn bộ mục 5 "Đặc thù
framework/language" không có baseline, luôn 100% từ template). Khi thêm/sửa tiêu chí, tự hỏi "đây
có áp dụng được cho stack khác không" — nếu có, nó thuộc `ALWAYS_RULE.md`, không phải template.

**Template = nền + overlay, không lặp nội dung.** `lambda-common.md` chồng lên
`python.md`/`nodejs.md`; `laravel.md`/`wordpress.md` chồng lên `php.md` — các file overlay này CHỈ
chứa tiêu chí đặc thù serverless/framework, cố tình không lặp lại rule đã có ở template nền HAY ở
baseline. Khi sửa template nền, kiểm tra overlay tương ứng có bị trùng/mâu thuẫn không.

**Mọi danh sách tiêu chí (baseline lẫn template) là gợi ý minh họa, không phải checklist đóng.**
Tránh viết dạng liệt kê khiến agent hiểu nhầm là chỉ cần tìm đúng những ý đã ghi — luôn giữ khung
câu kiểu "ví dụ, không giới hạn ở đây" khi thêm tiêu chí mới.

**Memory là state runtime, sống ngoài repo này.** `notebooks/review/<short_name>/{memory.md,
memories/, templates/, meta.json}` được `/review:pr` tự tạo bên trong repo đang được review (không
phải trong plugin), có git nested riêng (không push). Bootstrap + doctor (`meta.json.bootstrapped`/
`.doctored`) chỉ chạy 1 lần; local template copy (`meta.json.templates_copied`) chạy lại mỗi khi
gặp stack chưa từng thấy ở repo đó, kể cả sau khi đã bootstrap/doctor xong lâu rồi — đây là 2 điều
kiện khác nhau, đừng gộp chung 1 gate. Đừng nhầm thư mục này là dữ liệu của plugin repo này.

**`ALWAYS_RULE.md` luôn thắng memory nếu mâu thuẫn.** Đây là rule cứng global (vd ngôn ngữ output,
default English), đọc qua `${CLAUDE_PLUGIN_ROOT}` (biến môi trường chuẩn Claude Code, portable mọi
máy — KHÔNG hardcode path tuyệt đối của 1 máy cụ thể) — khác với convention riêng từng repo nằm
trong `memory.md`.

**Phân loại file-level vs line-level finding là phán đoán ngữ cảnh của agent lúc review**, cố tình
không có danh sách cứng/enum trong `pr.md` — đừng thêm danh sách cứng vào đó khi sửa.

## Khi thêm 1 stack mới

Theo đúng pattern trong `backlogs/templates.md`: viết 1 file `templates/<stack>.md` theo khung 6
mục, mở đầu bằng `# <Tên stack>` + 1 dòng note metadata italic (`_Bổ sung cho baseline
`ALWAYS_RULE.md`; ..._`) như các template hiện có; nếu là biến thể/sub-framework của 1 ngôn ngữ đã
có (ví dụ 1 framework PHP khác ngoài Laravel/WordPress) thì viết dạng overlay (note ghi rõ `_Overlay
chồng lên `<nền>.md`, ..._`) thay vì lặp rule nền. Sau đó cập nhật bảng mapping đuôi file/path →
stack trong `stack-detection.md`.
