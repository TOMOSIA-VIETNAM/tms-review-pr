# PR template checklist — đối chiếu description với checklist tự đặt của dự án (Bước 7 `pr.md`)

Không phải slash command (nằm ngoài `commands/`). `pr.md` Bước 7 `Read` file này khi
`meta.json.pr_template_paths` (đọc ở Bước 3) không rỗng — rỗng (dự án không có PR template nào) thì
bỏ qua hoàn toàn, không đọc file này, không tạo finding nào cho mục này.

Khác 2 mục kiểm tra title/description và branch-ticket-prefix ở Bước 7 (chỉ overview, không tính
severity) — mục này CÓ tính vào N ở Bước 8, vì đây là vi phạm 1 rule dự án đã tự đặt ra qua PR
template, không chỉ là góp ý phong cách.

Đọc nội dung (các) file tại (các) path trong `pr_template_paths` bằng `Read`, đối chiếu với `body`
thật của PR (đã lấy ở block "Ngữ cảnh"). Tìm dấu hiệu còn sót lại chưa điền — vd checkbox `- [ ]`
còn chưa tick, hoặc 1 section của template còn nguyên văn bản hướng dẫn/placeholder/HTML-comment
gốc thay vì nội dung thật của PR. Đây là phán đoán ngữ cảnh, KHÔNG có danh sách cứng "mục nào bắt
buộc phải điền".

Phát hiện ≥1 chỗ chưa điền → gộp thành ĐÚNG 1 finding TỔNG HỢP (liệt kê các mục còn thiếu trong
cùng 1 finding, KHÔNG tách vụn mỗi checkbox thành 1 finding riêng) theo khung Vấn đề/Cách fix của
Bước 7. Finding này xếp mức **[Nên sửa]**, là finding cấp **FILE** (không gắn 1 dòng code cụ thể)
nên vào body Bước 8 dưới mục [Nên sửa], KHÔNG vào `comments[]` ở Bước 9.
