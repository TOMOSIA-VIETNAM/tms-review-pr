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

**Template = nền + overlay, không lặp nội dung.** Mỗi file trong `templates/` dùng chung khung 6
mục (1.Lỗi&logic 2.Bảo mật 3.Hiệu suất 4.Chất lượng code 5.Đặc thù framework 6.Bảo trì&dễ đọc).
`lambda-common.md` chồng lên `python.md`/`nodejs.md`; `laravel.md`/`wordpress.md` chồng lên
`php.md` — các file overlay này CHỈ chứa tiêu chí đặc thù, cố tình không lặp lại rule đã có ở
template nền. Khi sửa template nền, kiểm tra overlay tương ứng có bị trùng/mâu thuẫn không.

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
