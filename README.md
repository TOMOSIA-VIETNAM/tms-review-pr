# /tms:review-pr — Agent Review Pull Request Github

[![Latest Release](https://img.shields.io/github/v/release/TOMOSIA-VIETNAM/tms-review-pr?label=release)](https://github.com/TOMOSIA-VIETNAM/tms-review-pr/releases)
[![License: MIT](https://img.shields.io/github/license/TOMOSIA-VIETNAM/tms-review-pr)](./LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-5A32A3)](https://claude.ai/code)
[![Cursor Plugin](https://img.shields.io/badge/Cursor-Plugin-000000)](https://cursor.com)

**Tiếng Việt** · [English](./README.en.md) · [日本語](./README.ja.md)

Plugin dạy Agent review Pull Request GitHub **một cách nhất quán** — càng dùng càng hiểu đúng dự án của bạn.

Lần đầu nó đọc quy ước sẵn có (README, CLAUDE.md, AGENTS.md, docs, wiki…). Các lần sau luôn áp dụng rule đặc thù
của repo đó; bạn gõ thêm quy tắc trong chat thì nó nhớ ngay vào memory đúng repo — sát convention
thật, ít áp luật chung chung.

Nếu góp ý chỉ nằm trên comment PR? Nó sẽ hỏi bạn trước khi nhớ (tránh nhét rule giả qua PR).

Quy ước dự án không đứng yên — mỗi lần chạy lệnh review (`/tms:review-pr` trên Claude Code hoặc
`/review-pr` trên Cursor), nếu đã đến kỳ thì plugin tự đọc lại tài liệu convention để memory không
lỗi thời. Chi tiết lịch: [Chu kỳ cập nhật quy ước](#chu-kỳ-cập-nhật-quy-ước).

## Cần gì trước

- Một trong hai host: [Claude Code](https://claude.ai/code) **hoặc** [Cursor](https://cursor.com)
- [`gh`](https://cli.github.com/) đã đăng nhập (`gh auth login`) — plugin đăng review qua tài khoản này

## Cài đặt (Claude Code)

Trong phiên Claude Code:

```
/plugin marketplace add TOMOSIA-VIETNAM/tms-review-pr
/plugin install tms@review-pr
```

### Cập nhật lên bản mới nhất (Claude)

`plugin.json` không khai `version` (dự án đang dev tích cực) — mỗi commit mới trên `main` tự thành
1 bản. Đã cài rồi thì lấy bản mới:

```
/plugin marketplace update review-pr
/plugin update tms@review-pr
```

Rồi `/reload-plugins` (hoặc mở phiên Claude Code mới) để nạp lại.

Repo đã setup từ trước, muốn kiểm tra/cập nhật cấu hình theo bản mới (field mới nếu có sẽ backfill
ngay, không cần đợi lần review kế) — gõ trong chat ở repo đó: "làm mới cấu hình" (hoặc "đổi cấu
hình review").

## Cài đặt (Cursor)

Claude và Cursor dùng **cùng** `src/` (templates/cases/setup), nhưng command Cursor nằm riêng ở
`src/cursor/commands/` — không đổi hành vi Claude.

**Team Marketplace:** admin import URL GitHub repo này (Dashboard → Plugins → Team Marketplaces);
manifest Cursor ở `.cursor-plugin/marketplace.json` (`source: "./src"`). Sau khi cài, lệnh:
`/review-pr`.

Muốn sửa plugin trên máy (clone repo) → xem [For development](#for-development).

## Dùng thế nào

Slash command **chỉ chạy khi bạn gõ đúng lệnh** — agent không tự gọi.

**Claude Code:**

```
/tms:review-pr https://github.com/<owner>/<repo>/pull/<number>
```

**Cursor:**

```
/review-pr https://github.com/<owner>/<repo>/pull/<number>
```

URL có đuôi `/files`, `/changes`, query… vẫn được — chỉ cần chứa link PR hợp lệ.

Thêm chỉ dẫn ngay sau URL cho **lần chạy đó** (không đổi cấu hình đã lưu), ví dụ:

```
/tms:review-pr https://github.com/org/repo/pull/123 focus on security
```

```
/review-pr https://github.com/org/repo/pull/123 focus on security
```

**Làm việc song song, không sợ đụng branch.** Mỗi lần review, code PR được checkout vào một
[git worktree](https://git-scm.com/docs/git-worktree) riêng — không đổi branch/working tree repo gốc
bạn đang code. Có thể mở nhiều phiên review (nhiều PR cùng lúc) trong khi vẫn commit/
chỉnh sửa bình thường trên nhánh hiện tại.

## Lần đầu cho 1 repo chưa từng thiết lập

Plugin hỏi **một lần** (6 hoặc 7 câu, tuỳ repo có CI hay không — xem câu 5):

1. **Ngôn ngữ** review (vi / en / ja)
2. **Đăng review ngay hay để nháp?** (`auto_submit_review`) — `true`: mọi người thấy ngay; `false`
   (mặc định): bản nháp trên GitHub, bạn tự bấm Submit
3. **Tự đóng thread khi finding cũ đã fix?** (`auto_resolve_fixed_findings`) — mặc định `false`
4. **Bao lâu quét lại quy ước dự án?** — xem mục [Chu kỳ cập nhật quy ước](#chu-kỳ-cập-nhật-quy-ước)
   bên dưới (mặc định mỗi **1 tháng**)
5. **Có đối chiếu trạng thái CI check thật không?** (`review_ci_status`) — **chỉ hỏi nếu PR này có
   CI check** (repo không có CI → bỏ qua câu này, tự để `false`); mặc định `true` nếu được hỏi; CI
   có check fail thì cảnh báo 1 câu trong tổng quan (không tính lỗi phải fix)
6. **Ngưỡng số file để hỏi chiến lược review?** (`many_files_threshold`) — mặc định **30**; PR đổi
   nhiều file hơn số này thì plugin hỏi bạn muốn review nông toàn bộ, review sâu có chọn lọc, hay
   dừng đề nghị tách PR
7. **Ngưỡng size/file để coi là file to/dump?** (`big_file_threshold_kb`) — mặc định **20** (KB,
   ~5.000 token, ước lượng ~4 ký tự/token); file đổi vượt ngưỡng này (vd `package-lock.json`) chỉ
   lướt qua phân loại, không review chi tiết dòng-by-dòng — độc lập với ngưỡng số file ở câu 6

Sau đó nó đọc tài liệu quy ước sẵn có và nhớ lại cho các lần sau.

**Repo đã dùng lâu, từ trước khi 1 cài đặt nào đó mới xuất hiện?** Không cần làm gì — lần review kế
tiếp plugin tự nhận ra, tạm dùng default, báo 1 câu trong chat cho biết. Muốn đổi lại 1 trong 7 cài
đặt (bất cứ lúc nào, không cần chờ review chạy) — gõ trong chat "đổi cấu hình review" (hoặc "xem
setting hiện tại"), plugin in ra giá trị đang áp dụng và hỏi bạn muốn đổi field nào.

Dữ liệu nhớ nằm trong repo bạn đang review, tại `notebooks/review/<tên-repo>/` (git riêng local,
không push). Nên để thư mục này trong `.gitignore` của dự án — plugin tự thêm nếu thiếu.

## Cách hoạt động (ngắn)

```
/tms:review-pr <PR_URL>
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
  • mức độ bằng emoji: 🔴 MUST FIX / 🟠 SHOULD FIX / 🔵 SUGGESTION / 📝 NOTE
  • PR sạch → **LGTM 🌟**, không bới lỗi vụn
```

Hỗ trợ nhiều stack: Rails, Vue, React, Python, Node.js, Lambda, PHP, Laravel, WordPress, Shell,
Makefile (và tự mở rộng khi gặp stack mới).

**Chỉ review + comment.** Không close/merge PR, không đổi branch, không sửa code giúp bạn.

## Chu kỳ cập nhật quy ước

Quy ước dự án thay đổi theo thời gian. Plugin có thể **tự đọc lại định kỳ** khi bạn chạy
`/tms:review-pr`, để memory không bị lỗi thời.

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
| Quy tắc riêng team | `ALWAYS_RULE.md` mục Rule bổ sung, hoặc nói trong chat để ghi lesson |

## For development

Dành cho người sửa plugin trong clone repo này (không phải user chỉ cài để review). Runtime thật nằm
trong `src/` — README / `scripts/` / `CLAUDE.md` ở root không được copy vào máy user lúc install.

### Claude Code (local reinstall)

```bash
./scripts/reinstall.sh
```

Gỡ / add lại marketplace local rồi cài `tms@review-pr`, buộc nạp lại `src/` hiện tại (tránh cache
cũ). Cần `claude` CLI trong PATH. Sau đó `/reload-plugins` hoặc mở phiên mới, thử:

```
/tms:review-pr https://github.com/<owner>/<repo>/pull/<number>
```

### Cursor (local install)

```bash
./scripts/install-cursor-local.sh
```

Copy `src/` → `~/.cursor/plugins/local/tms` (**thư mục thật** — Cursor từ chối symlink trỏ ra ngoài
`plugins/local`). Restart Cursor hoặc **Developer: Reload Window**. Lệnh: `/review-pr`.

Mỗi lần sửa `src/` → chạy lại script + reload. Script cảnh báo nếu thiếu `gh` / chưa `gh auth login`.

### Khi đổi quy trình review

- **Source of truth** = `src/commands/review-pr.md` (Claude). Đổi Bước 0–10 → cập nhật adapter
  `src/cursor/commands/review-pr.md` cho khớp (map tool / Shell / allowlist prose).
- Shared (`setup-flow.md`, `cases/*`, `templates/*`, `ALWAYS_RULE.md`) giữ wording
  `${CLAUDE_PLUGIN_ROOT}` + tên tool Claude; Cursor map lúc runtime.
- Thêm stack mới: `src/templates/<stack>.md` + bảng `src/stack-detection.md` (xem `CLAUDE.md`).
