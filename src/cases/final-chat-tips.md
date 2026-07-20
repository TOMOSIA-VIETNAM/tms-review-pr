# Final chat tips — gợi ý đặt tên session (sau Bước 9 `review-pr.md`)

Không phải slash command (nằm ngoài `commands/`). `review-pr.md` `Read` file này NGAY SAU Bước 9
post thành công (happy path, không phải nhánh lỗi của `post-review.md`) CHỈ khi PR đang review
(canonical `owner/repo/pull_number`) CHƯA từng hiện tip này trong CHÍNH session hiện tại — kiểm
theo TẬP HỢP mọi PR đã hiện tip từ đầu phiên, KHÔNG CHỈ so với 1 PR gần nhất (sai 1 PR gần nhất sẽ
lộ bug: review A → tip hiện; review B → tip hiện; quay lại re-review A → "gần nhất" giờ là B nên
A≠B, tip hiện SAI lần 2 cho A). Tự nhớ tập hợp đó qua lịch sử chat của phiên — KHÔNG ghi vào file
nào (`meta.json` hay khác); tip này ephemeral theo session, không phải state của repo. Review lại
BẤT KỲ PR nào đã hiện tip trước đó trong cùng phiên (vd re-review) → không hiện lại, dù có bao
nhiêu PR khác đã review ở giữa.

Nội dung hiện Ở CHAT, SAU toàn bộ tóm tắt review (không phải trong PR body Bước 8 — GitHub không
cần thấy dòng này), xuống dòng tách biệt, độc lập với đoạn tóm tắt phía trên:

```
💡 Gợi ý đặt tên cho session/cuộc trò chuyện này: "review-pr#<pull_number>-<repo>-<từ khoá ngắn>"
   — giúp tìm lại lịch sử review PR này nhanh hơn sau này.
```

- `<từ khoá ngắn>` = rút từ title PR, viết liền bằng gạch ngang, tối đa ~3-4 từ, không dấu.
- Câu chữ trung lập, KHÔNG gợi lệnh cụ thể của riêng 1 tool (vd không nêu `/rename`) — plugin này
  chạy trên nhiều IDE/tool khác nhau (Claude Code, Cursor, …), mỗi tool có cách đặt tên session
  riêng hoặc không có cơ chế nào cả; chỉ đưa tên gợi ý + lý do, để user tự áp dụng theo cách phù hợp
  với tool họ đang dùng.
