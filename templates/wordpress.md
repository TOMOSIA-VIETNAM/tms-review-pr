WordPress (overlay)

> File này CHỒNG THÊM lên `php.md` — không thay thế. File này chỉ chứa tiêu chí ĐẶC THÙ WordPress,
> không lặp tiêu chí PHP nền đã có ở `php.md`.

#### 1. Lỗi & Vấn đề logic

- Hooks/filters có dùng đúng cách không — `add_action`/`add_filter` có khai đúng priority, tránh side-effect ẩn (chạy nhầm thứ tự, chạy nhiều lần) khi hook được trigger không?
- Cấu trúc plugin/theme có hardcode path tuyệt đối không, hay dùng `plugin_dir_path(__FILE__)`/`get_template_directory()` để path luôn đúng dù cài ở đâu?

#### 2. Bảo mật

- Nonce verification có được kiểm tra cho form/AJAX request không (`wp_verify_nonce`, `check_admin_referer`)?
- Input có được sanitize trước khi lưu DB không (`sanitize_text_field`, `sanitize_email`, `sanitize_textarea_field`...)?
- Output có được escape trước khi render không (`esc_html`, `esc_attr`, `esc_url`...)?
- Capability check (`current_user_can`) có được kiểm tra trước hành động nhạy cảm (xóa/sửa dữ liệu, đổi setting) không?
- Query DB có dùng `$wpdb->prepare` thay vì nội suy chuỗi trực tiếp vào SQL không?

#### 3. Hiệu suất

- Có gọi `WP_Query`/`get_posts` lặp lại không cần thiết trong loop không?
- Có tận dụng Transients API/object cache cho dữ liệu tính toán tốn kém, ít thay đổi không?
- Query meta có tránh `meta_query` không cần thiết gây chậm không?

#### 4. Chất lượng code

- Hook callback có đặt tên rõ ràng, tránh anonymous function khó unhook khi cần không?
- Có code bị lặp giữa các hook/shortcode/widget không (nguyên tắc DRY)?

#### 5. Đặc thù WordPress

- Enqueue script/style có đúng cách không — dùng `wp_enqueue_script`/`wp_enqueue_style` với dependency khai báo đúng, tránh echo `<script>`/`<link>` trực tiếp ra HTML?
- Custom post type/taxonomy đăng ký có đầy đủ tham số cần thiết (labels, capability, rewrite) không?
- Có tránh xung đột namespace/global function/hook tên với plugin/theme khác không (dùng prefix riêng)?

#### 6. Khả năng bảo trì & Dễ đọc

- Có comment giải thích cho hook phức tạp hoặc thứ tự phụ thuộc giữa các hook không?
- Coding standard có tuân theo WordPress Coding Standards (WPCS) không?
- Thiết kế có đủ linh hoạt để tương thích khi WordCore/plugin khác cập nhật không?
