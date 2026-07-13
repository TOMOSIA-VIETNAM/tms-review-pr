# review

Đây không phải 1 tool review PR. Đây là **năng lực** — dạy Claude Code cách review PR nhất quán,
theo đúng 1 bộ quy tắc chung (mọi ngôn ngữ/framework) cộng với quy tắc riêng của từng dự án, và
càng dùng thì càng hiểu dự án hơn (tự học convention, tự khám phá quy ước có sẵn, tự nhớ lại lần sau
không phải học lại).

## Dùng thế nào

```
/review:pr https://github.com/<owner>/<repo>/pull/<number>
```

Cũng nhận diện được khi gõ tự nhiên trong chat ("review giúp tôi PR này: <url>"), không bắt buộc
đúng cú pháp slash-command.

## Cài đặt

```
./scripts/reinstall.sh
```

Cài lại từ đầu (uninstall → gỡ marketplace cũ → add lại → install lại) — chạy an toàn nhiều lần.
Sau khi chạy, mở phiên Claude Code mới để nạp `/review:pr`.

## Cách hoạt động

```
┌─ plugin (dùng chung cả team, 1 nơi) ───────────────────────────────┐
│                                                                     │
│  src/ALWAYS_RULE.md    baseline: quy tắc áp dụng MỌI PR, mọi stack │
│  src/templates/*.md    tiêu chí riêng từng ngôn ngữ/framework       │
│  src/commands/pr.md    /review:pr — quy trình review                │
│  src/setup-flow.md     bootstrap + doctor (chỉ đọc khi cần)          │
│                                                                     │
└──────────────────────────────┬──────────────────────────────────────┘
                                │  /review:pr <PR_URL>
                                ▼
┌─ repo đang được review (mỗi repo state riêng) ─────────────────────┐
│                                                                     │
│  Lần đầu review 1 repo:                                             │
│    notebooks/review/<repo>/                                        │
│      ALWAYS_RULE.md         ← copy từ plugin, team tự sửa được      │
│      templates/<stack>.md   ← copy từ plugin, hoặc tự soạn nếu chưa │
│                                 có (rồi lưu local)                  │
│      memory.md + memories/  ← rỗng lúc đầu                          │
│      doctor: quét TOÀN repo tìm README/CLAUDE.md/AGENTS.md/docs/... │
│              → ghi THAM CHIẾU vào memory.md (không copy nội dung,   │
│                tránh bị lỗi thời khi dự án tự cập nhật docs)         │
│                                                                     │
│  Mọi lần review:                                                    │
│    1. Đồng bộ local cho source/target — dừng nếu working tree bẩn   │
│    2. Detect stack cho từng file trong diff                         │
│    3. Đảm bảo có local template cho (các) stack đó                  │
│    4. Nạp ALWAYS_RULE + memory + template (bản LOCAL của repo)      │
│    5. Review theo 6 mục (baseline + đặc thù stack + lesson đã học)  │
│    6. Post ĐÚNG 1 review (summary + inline comment), verify đã submit│
│                                                                     │
│  Theo thời gian: phát hiện đồng thuận convention mới qua re-review  │
│  → hỏi user xác nhận → ghi thêm vào memory.md → lần review sau      │
│  ngày càng sát với quy ước thật của dự án, không phải học lại từ 0  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Nguyên tắc

- **Baseline + delta, không lặp.** Quy tắc chung nằm ở `ALWAYS_RULE.md`, nạp cho mọi PR. Mỗi
  template chỉ chứa phần đặc thù của stack đó — không lặp lại quy tắc chung.
- **Học theo dự án, không học chung chung.** Convention riêng (từ doctor hoặc từ đồng thuận
  review thật) sống trong `notebooks/review/<repo>/` của chính repo đó — không trộn giữa các dự án.
- **Gợi ý, không phải checklist đóng.** Tiêu chí trong baseline/template là ví dụ định hướng —
  luôn khuyến khích tự phát hiện thêm vấn đề ngoài danh sách.
- **Chỉ review + comment.** Không tự ý close/merge PR, không xoá/đổi branch, không sửa code —
  mọi hành động ngoài phạm vi review đều cần user tự quyết định.

## Cho người phát triển plugin này

Xem `CLAUDE.md` (kiến trúc chi tiết) và `backlogs/` (lịch sử task lúc build, tạm thời).
