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
  - Ghi rõ: file này được `commands/pr.md` tham chiếu bằng đường dẫn TUYỆT ĐỐI tới plugin (không
    phải path tương đối tính từ repo đang review) — tránh nhầm khi maintain.
- Dependency: S3.

## Thứ tự: S1 → S2 → S3 → S4
