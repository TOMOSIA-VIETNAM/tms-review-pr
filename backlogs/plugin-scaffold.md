# Backlog: Plugin Scaffold

Mục tiêu: dựng khung thư mục + file cấu hình tối thiểu để Claude Code nhận diện được plugin
"review", làm nền cho mọi task khác. Không chứa logic review.

## Task S1: Khởi tạo git cho chính plugin repo
- Acceptance:
  - `git init` tại root `github-reviewer/` — đây là git CỦA CODEBASE PLUGIN, khác hoàn toàn với
    git nested `notebooks/review/` được tạo runtime bởi lệnh `/review:pr` khi review 1 repo khác —
    không nhầm lẫn 2 việc này.
- Status: DONE.

## Task S2: Tạo `.claude-plugin/plugin.json`
- Acceptance:
  - Đúng field: `name: "review"`, `displayName`, `version: "0.1.0"`, `description`, `author.name`,
    `keywords: []`, `commands: "./commands/"`.
  - `author.name` = "Minh Tang Q." (lấy từ `git config user.name`).
- Dependency: S1.

## Task S3: Tạo khung thư mục rỗng
- Acceptance:
  - Tồn tại `commands/`, `templates/`.
- Dependency: S2.

## Task S4: Soạn nội dung `ALWAYS_RULE.md`
- Acceptance:
  - Rule duy nhất khi khởi tạo file: ngôn ngữ output review default English nếu không set khác.
  - Ghi chú agent nên nhận diện yêu cầu review PR bằng ngôn ngữ tự nhiên (không bắt buộc user gõ
    đúng cú pháp `/review:pr <url>`) và tự map sang luồng review tương ứng.
  - Phần còn lại để trống cho user tự điền rule riêng dự án/tổ chức sau này.
  - Viết trung lập (đọc được bởi cả human lẫn agent, không phải câu văn "diễn giải" hướng dẫn cho
    agent) — KHÔNG chứa path tuyệt đối của 1 máy cụ thể (plugin dùng chung nhiều máy trong team;
    `pr.md` tự trỏ tới file này qua biến `${CLAUDE_PLUGIN_ROOT}`, không cần file này tự mô tả path).
- Dependency: S3.

## Task S5: Tạo `setup-flow.md` (KHÔNG đặt trong `commands/`)
- Acceptance:
  - Đặt tại root plugin (ngang hàng `ALWAYS_RULE.md`), KHÔNG đặt trong `commands/` — nếu đặt trong
    `commands/` nó sẽ tự trở thành 1 slash command khác, vi phạm quyết định "chỉ 1 command duy nhất".
  - Chứa: Phần A (bootstrap `notebooks/review/<short_name>/`), Phần B (copy/tự soạn local template
    theo stack), Phần C (doctor — khám phá convention có sẵn của dự án), Phần D (schema
    `meta.json`).
  - `commands/pr.md` chỉ đọc file này bằng tool `Read` khi `meta.json` cho thấy chưa thiết lập
    xong — không dùng bash `!`...`` để include có điều kiện (bash chạy trước khi model thấy prompt,
    không thể điều kiện theo kết quả suy luận của model).
- Dependency: S3.

## Thứ tự: S1 → S2 → S3 → S4, S5 (song song)
