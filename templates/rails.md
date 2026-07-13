Rails (API + View)

#### 1. Lỗi & Vấn đề logic

- Có bug rõ ràng hoặc lỗi logic nào không?
- Các trường hợp biên (nil, mảng rỗng, giá trị giới hạn) có được xử lý đúng không?
- Có nhánh điều kiện nào bị thiếu không?
- Xử lý transaction có đúng không (rollback có được áp dụng khi cần không)?

#### 2. Bảo mật

- Có lỗ hổng SQL injection nào không (ví dụ: nội suy chuỗi trong `where`)?
- Có lỗ hổng mass assignment nào không (`permit` được cấu hình đúng chưa)?
- Có thiếu kiểm tra xác thực (authentication) hay phân quyền (authorization) không?
- Code có chứa thông tin nhạy cảm (API key, mật khẩu, v.v.) không?

#### 3. Hiệu suất

- Có vấn đề N+1 query không?
- `includes` / `preload` / `eager_load` có được dùng khi cần không?
- Có truy vấn database lặp không cần thiết không (có thể giải quyết bằng cache)?
- `find_each` hoặc `in_batches` có được dùng khi xử lý tập dữ liệu lớn không?

#### 4. Chất lượng code

- Tên biến/hàm có rõ ràng và mô tả đúng không?
- Có code bị lặp không (nguyên tắc DRY)?
- Trách nhiệm của các method có được tách biệt đúng không?
- Code có được viết theo phong cách Ruby thuần không (`map`, `select`, `each_with_object`, v.v.)?
- Comment disable Rubocop có được giải thích lý do hợp lệ không?

#### 5. Ruby on Rails cụ thể

- Validations của ActiveRecord có phù hợp không?
- Scope và class method có được dùng đúng không?
- Có tác dụng phụ không mong muốn từ callback (`before_save`, v.v.) không?
- Việc tách service class và concern có hợp lý không?
- Nếu có mutation/query GraphQL, định nghĩa type có đúng không?
- RSpec test có được thêm hoặc cập nhật không? Có bao gồm cả happy path và error path không?

#### 6. Khả năng bảo trì & Dễ đọc

- Có comment ở những nơi logic không rõ ràng không?
- Hằng số và mapping có được định nghĩa phù hợp không?
- Thiết kế có đủ linh hoạt để đáp ứng thay đổi trong tương lai không?
