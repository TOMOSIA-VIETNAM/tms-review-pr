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
commands/pr.md                Toàn bộ logic của slash command /review:pr — file quan trọng nhất
templates/*.md                Tiêu chí review theo từng ngôn ngữ/framework (nội dung thuần, không
                               logic điều phối)
ALWAYS_RULE.md                Rule cứng global, áp dụng mọi repo được review qua plugin này
backlogs/*.md                 Task breakdown lịch sử khi build plugin lần đầu (tham khảo khi mở
                               rộng thêm stack/tính năng, không phải doc vận hành runtime)
```

## Kiến trúc cốt lõi

**`commands/pr.md`** encode 9 bước tuần tự: validate URL PR → lấy context qua `gh pr view/diff` →
detect stack theo đuôi file/path cho từng file trong diff → bootstrap (idempotent) thư mục
`notebooks/review/<short_name>/` tại **root của repo đang được review** (không phải trong plugin
này) → nạp `ALWAYS_RULE.md` + memory + template tương ứng → đọc lại comment cũ của chính PR để phát
hiện đồng thuận convention mới (re-review) → review theo khung 6 mục → định dạng kết quả → post
đúng 1 lần qua `gh api POST .../pulls/{n}/reviews`.

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

**Memory là state runtime, sống ngoài repo này.** `notebooks/review/<short_name>/memory.md` +
`memories/<lesson>.md` được `/review:pr` tự tạo bên trong repo đang được review (không phải trong
plugin), có git nested riêng (không push), và bootstrap CHỈ chạy nếu chưa tồn tại — đã tồn tại rồi
thì lệnh bỏ qua hoàn toàn, không tạo/sửa lại. Đừng nhầm đây là dữ liệu của plugin repo này.

**`ALWAYS_RULE.md` luôn thắng memory nếu mâu thuẫn.** Đây là rule cứng global (vd ngôn ngữ output,
default English), đọc bằng đường dẫn tuyệt đối tới root plugin — khác với convention riêng từng
repo nằm trong `memory.md`.

**Phân loại file-level vs line-level finding là phán đoán ngữ cảnh của agent lúc review**, cố tình
không có danh sách cứng/enum trong `pr.md` — đừng thêm danh sách cứng vào đó khi sửa.

## Khi thêm 1 stack mới

Theo đúng pattern trong `backlogs/templates.md`: viết 1 file `templates/<stack>.md` theo khung 6
mục; nếu là biến thể/sub-framework của 1 ngôn ngữ đã có (ví dụ 1 framework PHP khác ngoài
Laravel/WordPress) thì viết dạng overlay (ghi rõ dòng "File này CHỒNG THÊM lên `<nền>.md`" ở đầu
file) thay vì lặp lại rule nền. Sau đó cập nhật bảng mapping đuôi file/path → template ở Bước 1 của
`commands/pr.md`.
