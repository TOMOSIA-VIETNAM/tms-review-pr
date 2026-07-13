# tms — GitHub PR Reviewer

Plugin Claude Code: dạy Claude review Pull Request GitHub **nhất quán**, theo quy tắc chung +
convention riêng từng dự án. Càng dùng càng nhớ dự án hơn.

## Cần gì trước

- [Claude Code](https://claude.ai/code) đã cài
- [`gh`](https://cli.github.com/) đã đăng nhập (`gh auth login`) — plugin đăng review qua tài khoản này

## Cài đặt

Trong phiên Claude Code:

```
/plugin marketplace add /đường/dẫn/tới/github-reviewer
/plugin install tms@github-reviewer
```

Mở **phiên mới**, rồi dùng lệnh bên dưới.

Cập nhật bản local sau khi kéo code mới: chạy lại `scripts/reinstall.sh` (hoặc uninstall + install lại).

## Dùng thế nào

Slash command **chỉ chạy khi bạn gõ đúng lệnh** — Claude không tự gọi `/tms:review_pr`

```
/tms:review_pr https://github.com/<owner>/<repo>/pull/<number>
```

URL có đuôi `/files`, `/changes`, query… vẫn được — chỉ cần chứa link PR hợp lệ.

Thêm chỉ dẫn ngay sau URL cho **lần chạy đó** (không đổi cấu hình đã lưu), ví dụ:

```
/tms:review_pr https://github.com/org/repo/pull/123 tiếng Việt
/tms:review_pr https://github.com/org/repo/pull/123 focus on security
```

## Lần đầu trên 1 repo

Plugin hỏi **một lần** (4 câu):

1. **Ngôn ngữ** review (vi / en / ja)
2. **Đăng review ngay hay để nháp?** (`auto_submit_review`) — `true`: mọi người thấy ngay; `false`
   (mặc định): bản nháp trên GitHub, bạn tự bấm Submit
3. **Tự đóng thread khi finding cũ đã fix?** (`auto_resolve_fixed_findings`) — mặc định `false`
4. **Bao lâu quét lại quy ước dự án?** — xem mục [Chu kỳ đọc lại quy ước](#chu-kỳ-đọc-lại-quy-ước)
   bên dưới (mặc định mỗi **1 tháng**)

Sau đó nó đọc tài liệu quy ước sẵn có (README, CLAUDE.md, AGENTS.md, docs…) và nhớ lại cho các lần
sau.

Dữ liệu nhớ nằm trong repo bạn đang review, tại `notebooks/review/<tên-repo>/` (git riêng local,
không push). Nên để thư mục này trong `.gitignore` của dự án — plugin tự thêm nếu thiếu.

## Cách hoạt động (ngắn)

```
/tms:review_pr <PR_URL>
        │
        ▼
Checkout code PR vào worktree riêng (không đụng branch bạn đang làm)
        │
        ▼
Review phần thay đổi, theo:
  • quy tắc kỹ thuật chung
  • convention / memory của đúng repo này
        │
        ▼
Đăng 1 review: tổng quan + comment từng dòng (khi cần)
  • mức độ bằng chữ: Bắt buộc sửa / Nên sửa / Đề xuất
  • PR sạch → "LGTM", không bới lỗi vụn
```

Hỗ trợ nhiều stack: Rails, Vue, React, Python, Node.js, Lambda, PHP, Laravel, WordPress, Shell,
Makefile (và tự mở rộng khi gặp stack mới).

**Chỉ review + comment.** Không close/merge PR, không đổi branch, không sửa code giúp bạn.

## Chu kỳ đọc lại quy ước

Quy ước dự án (README, CLAUDE.md, …) thay đổi theo thời gian. Plugin có thể **tự đọc lại định kỳ**
khi bạn chạy `/tms:review_pr`, để memory không bị lỗi thời.

| Bạn muốn | Điền vào `doctor_schedule` |
|----------|----------------------------|
| Mỗi tuần | `"1 weeks"` hoặc `"7 days"` |
| Mỗi 2 tuần | `"2 weeks"` |
| Mỗi tháng (mặc định) | `"1 months"` |
| Mỗi quý | `"3 months"` |
| Không bao giờ tự đọc lại | `"never"` |

Sửa trong `notebooks/review/<repo>/meta.json` — cạnh field có dòng `_comments` giải thích nhanh.
Muốn đọc lại **ngay** (không đợi lịch): trong chat nói **doctor lại** / **quét lại convention**.

## Tuỳ chỉnh sau khi đã dùng

Trong repo đã review ít nhất một lần:

| Muốn đổi | Sửa đâu |
|----------|---------|
| Ngôn ngữ mặc định | `notebooks/review/<repo>/ALWAYS_RULE.md` — khối `Ngôn ngữ output` |
| Đăng ngay / nháp, tự resolve thread, chu kỳ đọc lại quy ước | `notebooks/review/<repo>/meta.json` |
| Quy tắc riêng team | cùng file `ALWAYS_RULE.md` (mục Rule bổ sung) hoặc bảo Claude ghi lesson khi chat |

## Góp ý convention khi chat thường

Bạn nêu quy ước mới ngoài lệnh review → Claude **hỏi xác nhận** rồi mới ghi nhớ. Không tự ghi thay
team.
