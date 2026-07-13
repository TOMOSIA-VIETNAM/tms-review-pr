# review

Đây không phải 1 tool review PR. Đây là **năng lực** — dạy Claude Code cách review PR nhất quán,
theo đúng 1 bộ quy tắc chung (mọi ngôn ngữ/framework) cộng với quy tắc riêng của từng dự án, và
càng dùng thì càng hiểu dự án hơn (tự học convention, tự khám phá quy ước có sẵn, tự nhớ lại lần sau
không phải học lại).

## Dùng thế nào

```
/review:pr https://github.com/<owner>/<repo>/pull/<number>
```

Cũng nhận diện được khi gõ tự nhiên trong chat ("review giúp tôi PR này: <url>"), không bắt buộc
đúng cú pháp slash-command.

## Cài đặt

Trong 1 phiên Claude Code bất kỳ:

```
/plugin marketplace add /đường/dẫn/tới/github-reviewer
/plugin install review@github-reviewer
```

Mở phiên Claude Code mới sau khi cài, và nhập lệnh `/review:pr`.

## Cách hoạt động

```
   /review:pr <PR_URL>
          │
          ▼
   Đọc title + description của PR — có nêu rõ mục đích/business không?
          │
          ▼
   Đồng bộ code của PR về máy (không đụng branch bạn đang làm việc dở)
          │
          ▼
   Review đúng phần thay đổi của PR, đối chiếu với:
     • quy tắc kỹ thuật chung (mọi ngôn ngữ/framework)
     • quy ước riêng của dự án này (tự học — xem bên dưới)
          │
          ▼
   Đăng 1 review duy nhất lên PR:
     tổng quan + comment tại từng dòng liên quan, nhãn mức độ bằng chữ
     (không emoji, không bới lỗi vụn vặt — PR sạch thì chỉ "LGTM")
```

**Tự học quy ước của dự án.** Lần đầu review 1 project, nó tự tìm các tài liệu quy ước sẵn có
(README, CLAUDE.md, AGENTS.md, docs nội bộ...) để áp đúng convention của team thay vì áp luật chung
chung — chỉ làm kỹ 1 lần, không lặp lại mỗi lần review. Khi phát hiện 1 quy ước mới qua review thực
tế (dev và reviewer thống nhất với nhau trên thread), nó hỏi xác nhận trước khi ghi nhớ, không tự
quyết định thay team. Những lần review sau ngày càng sát với dự án cụ thể, không học lại từ đầu.

**Chỉ review + comment.** Không tự ý close/merge/reopen PR, không xoá/đổi branch, không sửa code
trong repo — mọi hành động ngoài phạm vi review đều cần bạn tự quyết định.
