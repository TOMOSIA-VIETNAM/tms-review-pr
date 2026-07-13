PHP (nền chung, không đặc thù framework)

#### 1. Lỗi & Vấn đề logic

- Có bug rõ ràng hoặc lỗi logic nào không?
- Các trường hợp biên (`null`, mảng rỗng, giá trị giới hạn) có được xử lý đúng không?
- Type juggling nguy hiểm có xảy ra không — dùng `==` thay vì `===` ở nơi cần so sánh strict (đặc biệt so sánh string/number dễ dính lỗi kiểu `"0" == "abc"`)?
- Error/exception handling có tránh dùng `@` để nuốt lỗi âm thầm không?

#### 2. Bảo mật

- Có lỗ hổng SQL injection không — có dùng PDO prepared statement/parameter binding thay vì nội suy chuỗi trực tiếp vào query không?
- Output có escape chống XSS không (`htmlspecialchars` khi render dữ liệu user ra HTML)?
- Session/cookie có cấu hình an toàn không (`httponly`, `secure`, `samesite` flag)?
- Code có chứa thông tin nhạy cảm (API key, mật khẩu) hardcode không?

#### 3. Hiệu suất

- Có truy vấn database lặp không cần thiết trong loop không?
- Có tính toán nặng lặp lại nhiều lần thay vì cache kết quả không?

#### 4. Chất lượng code

- Tên biến/hàm/class có rõ ràng, theo convention dự án không?
- Có code bị lặp không (nguyên tắc DRY)?
- Autoload có tuân theo chuẩn PSR-4/composer không (tránh `require`/`include` thủ công tùy tiện)?

#### 5. Đặc thù PHP

- Type hint tham số/return type có được khai báo đầy đủ không (PHP 7+)?
- Namespace có tổ chức rõ ràng, khớp cấu trúc thư mục (PSR-4) không?
- Có tận dụng tính năng ngôn ngữ hợp lý (null coalescing `??`, arrow function, match expression) không?

#### 6. Khả năng bảo trì & Dễ đọc

- Có comment ở những nơi logic không rõ ràng không?
- Test (PHPUnit) có được thêm hoặc cập nhật không? Có bao gồm cả happy path và error path không?
- Thiết kế có đủ linh hoạt để đáp ứng thay đổi trong tương lai không?
