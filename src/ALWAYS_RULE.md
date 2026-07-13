# Always Rule — quy tắc chung của plugin `review`

Phạm vi: áp dụng cho mọi repo review qua plugin `review`. Convention riêng từng repo sống ở
`notebooks/review/<repo>/`, ngoài phạm vi file này.

## Ngôn ngữ output

```
{{OUTPUT_LANGUAGE}}
```

Bootstrap điền 1 giá trị cụ thể thay `{{OUTPUT_LANGUAGE}}` (vd `English`, `Vietnamese`,
`Japanese`). Để trống / còn placeholder → hỏi user trước khi review. Chỉ dẫn ngôn ngữ trong
`ARGUMENTS` hoặc chat phiên hiện tại **thắng** giá trị trên (chỉ lần chạy đó, không sửa file).

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

---

## Rule bổ sung
<!-- User tự thêm rule riêng của mình / tổ chức tại đây. -->

### Convention riêng

### Tiêu chí bổ sung

### Ngoại lệ / lưu ý đặc biệt
