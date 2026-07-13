Makefile

#### 1. Lỗi & Vấn đề logic

- Có bug rõ ràng hoặc lỗi logic nào không?
- Dependency giữa các target có đúng thứ tự không (không thiếu prerequisite khiến target chạy trước khi cần)?
- Target mặc định (target đầu tiên trong file, chạy khi gõ `make` trơn) có tránh side-effect ẩn ngoài ý muốn không (ví dụ vô tình chạy `deploy`/`clean` thay vì `build`/`help`)?

#### 2. Bảo mật

- Recipe có chứa hardcode credential/secret không?
- Có lệnh tải file/script từ nguồn ngoài rồi thực thi ngay mà không kiểm tra không?

#### 3. Hiệu suất

- Có target chạy lại công việc không cần thiết dù output đã up-to-date (thiếu khai báo file target/prerequisite đúng) không?
- Có tận dụng parallel build (`-j`) hợp lý khi các target độc lập không?

#### 4. Chất lượng code

- Dùng biến (`$(VAR)`) thay vì hardcode path/giá trị lặp lại ở nhiều target không?
- Tránh duplicate logic giữa các targets không — có nên dùng pattern rule hoặc `include` file chung để DRY không?
- Kiểm tra exit code lệnh con trong recipe có đúng không (không âm thầm nuốt lỗi bằng dấu `-` đứng trước lệnh hoặc nối lệnh bằng `;` sai chỗ khiến lỗi bị bỏ qua)?

#### 5. Đặc thù Makefile

- Khai báo `.PHONY` có đủ cho mọi target không sinh ra file thật tương ứng tên target (`build`, `test`, `clean`, `deploy`...) không?
- Tab/indent trong recipe có đúng chuẩn Makefile (dùng tab, không phải space) không?
- Biến môi trường/override (`?=`, `:=`, `=`) có được dùng đúng ngữ nghĩa không?

#### 6. Khả năng bảo trì & Dễ đọc

- Tên target có rõ ràng, mô tả đúng hành động không?
- Có comment giải thích cho target/logic phức tạp không?
- Có target `help` liệt kê các lệnh sẵn có không (giúp người mới dễ dùng)?
