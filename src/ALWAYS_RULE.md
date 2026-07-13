# Always Rule — quy tắc chung của plugin `review`

Phạm vi: áp dụng cho mọi repo review qua plugin `review`. Convention riêng từng repo sống ở
`notebooks/review/<repo>/`, ngoài phạm vi file này.

## Ngôn ngữ output

Mặc định **English**. Điền ngôn ngữ cụ thể vào khối bên dưới để ghi đè.

<!-- Chưa set — đang dùng mặc định English. Ví dụ ghi đè: "Luôn output tiếng Việt". -->

## Khung review chung (baseline mọi stack)

Áp dụng cho mọi PR, mọi stack, không phân biệt ngôn ngữ/framework; luôn nạp cùng template đặc thù
của stack đang review. `templates/<stack>.md` chỉ chứa tiêu chí ĐẶC THÙ (gồm toàn bộ mục 5 "Đặc thù
framework/language" — mục này không có baseline chung), không lặp lại các mục dưới đây.

Các tiêu chí trong file này và trong `templates/*.md` là gợi ý minh họa định hướng, không phải
checklist đóng. Phạm vi review không giới hạn ở các mục được liệt kê; vấn đề khác phát hiện được
vẫn nằm trong phạm vi.

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

## Kích hoạt bằng ngôn ngữ tự nhiên

Luồng review kích hoạt cả khi yêu cầu được diễn đạt bằng ngôn ngữ tự nhiên trong chat (ví dụ:
"review giúp tôi PR này: <url>", "coi giùm cái PR <url> xem sao", "check PR <url>"), không bắt buộc
đúng cú pháp slash-command. Điều kiện: nội dung chứa 1 URL GitHub PR hợp lệ; khi đó áp dụng cùng
luồng như `/review:pr <url>`.

## Hành vi ngoài `/review:pr`

Áp dụng khi plugin `review` đã từng dùng trên repo (có `notebooks/review/<repo>/`), kể cả lúc chat
thường không gọi slash command:

- User nêu sửa đổi/góp ý convention → KHÔNG tự ghi lesson ngay. Hỏi xác nhận trước; chỉ sau khi user
  đồng ý mới ghi theo Phần E của `"${CLAUDE_PLUGIN_ROOT}"/src/setup-flow.md`.
- User yêu cầu "doctor lại" / "quét lại convention dự án" → set `doctored: false` trong `meta.json`,
  rồi làm lại Phần C của `"${CLAUDE_PLUGIN_ROOT}"/src/setup-flow.md`.

---

## Rule bổ sung (tự điền thêm bên dưới)

<!-- User tự thêm rule riêng của mình / tổ chức tại đây. Chưa có nội dung nào khác ngoài 2 rule ở trên. -->

### Convention riêng

### Tiêu chí bổ sung

### Ngoại lệ / lưu ý đặc biệt
