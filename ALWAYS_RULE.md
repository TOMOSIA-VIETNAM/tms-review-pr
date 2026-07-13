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

## Khung review chung (baseline mọi stack)

> Danh sách bên dưới (và toàn bộ danh sách trong `templates/*.md`) là GỢI Ý MINH HỌA để định hướng
> review, KHÔNG PHẢI checklist đóng/đầy đủ. Agent phải tự tư duy, chủ động phát hiện thêm vấn đề
> khác ngoài những gì được liệt kê nếu có — không tự giới hạn bản thân chỉ tìm đúng những ý đã ghi.

Áp dụng cho MỌI PR, MỌI stack, không phân biệt ngôn ngữ/framework — luôn nạp cùng với template đặc
thù của stack đang review. `templates/<stack>.md` CHỈ chứa tiêu chí ĐẶC THÙ (bao gồm toàn bộ mục 5
"Đặc thù framework/language" — mục này không có baseline chung), không lặp lại các mục dưới đây.

#### 1. Lỗi & vấn đề logic
- Có bug rõ ràng hoặc lỗi logic nào không?
- Các trường hợp biên (giá trị rỗng/null/undefined, giới hạn, mảng/danh sách rỗng) có được xử lý đúng không?

#### 2. Bảo mật
- Code có chứa thông tin nhạy cảm hardcode không (API key, token, mật khẩu, connection string)?

#### 3. Hiệu suất
- Có gọi lại (API/DB/lệnh con/tính toán) lặp không cần thiết mà có thể cache/gom lại không?

#### 4. Chất lượng code
- Tên biến/hàm/class/component có rõ ràng, theo convention của dự án không?
- Có code bị lặp không (nguyên tắc DRY)?

#### 6. Khả năng bảo trì & dễ đọc
- Có comment giải thích ở những nơi logic không rõ ràng/phức tạp không?
- Test có được thêm hoặc cập nhật cho thay đổi không? Có bao gồm cả happy path và error path không?
- Thiết kế có đủ linh hoạt để đáp ứng thay đổi trong tương lai không?

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
