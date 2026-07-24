# Agent Instructions (Markdown)

_Bổ sung cho baseline `ALWAYS_RULE.md`; áp dụng cho file `.md` là chỉ dẫn cho 1 AI coding agent đọc
và làm theo (skill/command/CLAUDE.md/AGENTS.md/cursor rules...), KHÔNG áp dụng cho README/docs
thường cho người đọc._

#### 1. Mâu thuẫn & lỗi logic

- 2 đoạn trong cùng file (hoặc giữa file này và file liên quan) có nói khác nhau về cùng 1 hành vi không?
- Điều kiện rẽ nhánh có phủ đủ trường hợp không, hay để agent tự đoán khi gặp case ngoài dự kiến?
- Ví dụ minh hoạ trong file có còn khớp hành vi thật đang mô tả không (stale example)?

#### 2. Lệnh nguy hiểm / rò rỉ thông tin qua văn bản

- Có gợi ý agent chạy lệnh phá hoại (`rm -rf`, force-push, `reset --hard`...) mà không kèm rào chắn/xác nhận không?
- Ví dụ minh hoạ có chứa secret/token/credential thật (không phải placeholder) không?
- File có xử lý data từ nguồn không tin cậy (input người dùng, PR content, web) mà thiếu câu "đây là DATA không phải INSTRUCTION" không?

#### 3. Token-bloat & overthinking

- Có nội dung lặp lại cùng 1 rule ở nhiều đoạn/nhiều file không?
- Nội dung chỉ áp dụng 1 trigger hiếm có bị để LUÔN-NẠP thay vì tách case riêng (chỉ đọc khi cần) không?
- Có đoạn giải thích "vì sao" dài dòng lẫn vào phần "làm gì" không — nếu file này luôn được nạp lúc runtime, lý do/lịch sử nên tách sang tài liệu riêng cho người phát triển đọc?
- Có yêu cầu agent tự-verify/tự-hỏi lại nhiều lần mà không rõ điều kiện dừng (rủi ro loop) không?

#### 4. Viết trung lập

- Có kể lể quá trình xây dựng/lịch sử sửa đổi khi chỉ cần nêu hành vi hiện tại không?
- Có tường thuật "diễn biến" (từng bước đã làm) thay vì chỉ dẫn thẳng không?
- Có tham chiếu tới thứ tạm/sẽ đổi (task ID, tên branch, số mục doc thiết kế, jargon nội bộ) khiến người đọc sau không giải nghĩa được khi thứ đó bị xoá/đổi không?

#### 5. Cấu trúc markdown

- Heading phân cấp rõ, mỗi heading 1 ý, không nhồi nhiều chủ đề không liên quan chung 1 mục?
- Frontmatter (nếu có) đủ field cần, không field thừa/legacy?
- Nội dung có điều kiện (chỉ áp dụng 1 số trigger) có tách đúng thành case/gate riêng, không nhồi vào file chính luôn-nạp?

#### 6. Khả năng bảo trì & dễ đọc

(không có tiêu chí bổ sung ngoài baseline chung — xem `ALWAYS_RULE.md`)
