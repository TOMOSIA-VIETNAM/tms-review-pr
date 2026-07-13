# ALWAYS RULE — Rule cứng của plugin `review`

> **Đây là rule CỨNG, áp dụng cho MỌI repo được review qua plugin `review` này** — không phải
> file cấu hình riêng của 1 dự án cụ thể. File này sống tại đường dẫn TUYỆT ĐỐI của plugin:
>
> ```
> /Users/minhtang/Documents/Projects/MyProject/any4ai/github-reviewer/ALWAYS_RULE.md
> ```
>
> `commands/pr.md` đọc file này bằng đường dẫn tuyệt đối ở trên (KHÔNG phải path tương đối tính từ
> repo đang được review) — dù đang review repo nào, ở đâu, agent vẫn phải đọc đúng file này tại
> plugin, tránh nhầm với `ALWAYS_RULE.md`/convention nào đó nằm trong chính repo đang review.

## Ngôn ngữ

(chưa set — mặc định English)

Nếu section này chưa được user điền gì khác, ngôn ngữ output review mặc định là **English**.
Khi user ghi đè bằng chỉ định cụ thể tại đây (ví dụ "Luôn output bằng tiếng Việt"), agent phải theo
chỉ định đó thay vì mặc định.

## Nhận diện yêu cầu review bằng ngôn ngữ tự nhiên

Agent nên nhận diện yêu cầu review PR được diễn đạt bằng ngôn ngữ tự nhiên trong chat bình thường
(ví dụ user gõ "review giúp tôi PR này: <url>", "coi giùm cái PR <url> xem sao", "check PR <url>"),
KHÔNG bắt buộc user phải gõ đúng cú pháp slash-command. Khi nhận diện được ý định + có URL GitHub PR
hợp lệ, agent tự map sang luồng review tương ứng của lệnh `/review:pr <url>`.

---

## Rule bổ sung (tự điền thêm bên dưới)

<!-- User tự thêm rule riêng của mình / tổ chức tại đây. Chưa có nội dung nào khác ngoài 2 rule ở trên. -->

### Convention riêng

### Tiêu chí bổ sung

### Ngoại lệ / lưu ý đặc biệt
