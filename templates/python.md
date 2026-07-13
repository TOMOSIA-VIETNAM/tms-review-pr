Python

> Tiêu chí dưới đây BỔ SUNG cho baseline chung trong `ALWAYS_RULE.md` (áp dụng mọi stack) — không
> lặp lại các mục đã có ở đó.

#### 1. Lỗi & Vấn đề logic

- Mutable default argument (`def f(x=[])`, `def f(x={})`) có bị dùng sai gây side-effect giữa các lần gọi không?
- Có nhánh điều kiện/exception nào bị thiếu xử lý không?

#### 2. Bảo mật

- Nên cấu hình secret qua biến môi trường thay vì hardcode.
- Có input nào được đưa thẳng vào query/command/eval mà không qua kiểm tra không?
- Exception handling có tránh nuốt lỗi âm thầm (bare `except:`) làm mất thông tin bảo mật/debug không?

#### 3. Hiệu suất

- Có vấn đề N+1 query nếu dùng ORM (SQLAlchemy/Django) không — có thiếu `select_related`/`prefetch_related` (Django) hoặc `joinedload`/`selectinload` (SQLAlchemy) không?
- Có xử lý dữ liệu lớn theo cách tốn bộ nhớ không (nên dùng generator/iterator thay vì load hết vào list)?
- Có tính toán lặp lại không cần thiết có thể cache (`functools.lru_cache`) không?

#### 4. Chất lượng code

- Type hints có đầy đủ cho public function/method không?
- Exception handling có cụ thể (bắt đúng loại exception cần) thay vì bare `except:` không? Khi re-raise có dùng exception chaining (`raise ... from e`) để giữ traceback gốc không?
- Context manager (`with`) có được dùng cho resource cần đóng (file, db connection, socket) thay vì quản lý mở/đóng thủ công không?

#### 5. Đặc thù Python

- Dùng `logging` thay vì `print` trong code chạy production không?
- Docstring có đầy đủ cho function phức tạp/public API không?
- Có tận dụng idiom Python (list/dict comprehension, unpacking, `enumerate`, `zip`) hợp lý, tránh code kiểu ngôn ngữ khác dịch sang không?
- Cấu trúc package/module (import) có rõ ràng, tránh circular import không?

#### 6. Khả năng bảo trì & Dễ đọc

- Tên biến/hàm/class có tuân theo PEP 8 không?
- Test có dùng pytest không?
