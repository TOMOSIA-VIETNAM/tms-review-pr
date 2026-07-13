Laravel (overlay)

> File này CHỒNG THÊM lên `php.md` — không thay thế. File này chỉ chứa tiêu chí ĐẶC THÙ Laravel,
> không lặp tiêu chí PHP nền đã có ở `php.md`.

#### 1. Lỗi & Vấn đề logic

- Migration có an toàn không — có định nghĩa method `down()` rollback đúng, đối xứng với `up()` không?
- Route model binding có được dùng thay vì query tay (`Model::find($id)`) lặp lại trong controller không?

#### 2. Bảo mật

- Mass assignment có được cấu hình an toàn không — `$fillable`/`$guarded` trên Model có khai trúng field, tránh cho phép gán field nhạy cảm (`is_admin`, `role`...) qua request không?
- Middleware/policy có được dùng cho authorization không, tránh check quyền tay (if-else) rải rác trong controller?
- Blade template có escape đúng không — `{{ }}` (tự động escape) được dùng mặc định, `{!! !!}` (không escape) chỉ dùng khi chắc chắn dữ liệu an toàn (không phải input user)?

#### 3. Hiệu suất

- Eloquent có bị N+1 query không — quan hệ (relationship) truy cập trong loop có thiếu `with()`/`load()` eager loading không?
- Query có tận dụng query builder/scope hợp lý thay vì load hết rồi filter bằng PHP (collection) không?

#### 4. Chất lượng code

- Form Request (class `FormRequest` riêng) có được dùng để validate input thay vì validate tay trong controller không?
- Logic nghiệp vụ có được tách khỏi controller (Service/Action class) thay vì để controller phình to không?

#### 5. Đặc thù Laravel

- Queue/job có xử lý lỗi đúng không — retry policy, `failed()` method, failed job có được log/theo dõi không?
- Event/Listener, Observer có được dùng hợp lý cho side-effect (thay vì nhét vào Controller/Model) không?
- Config/env có được truy cập qua `config()` (đã cache) thay vì `env()` trực tiếp ngoài file config không?

#### 6. Khả năng bảo trì & Dễ đọc

- Naming convention của Laravel (Model số ít, Controller số nhiều, method theo REST resource) có được tuân theo không?
- Có comment ở những nơi logic nghiệp vụ phức tạp không?
- Test (Feature/Unit test của Laravel) có được thêm hoặc cập nhật cho thay đổi không?
