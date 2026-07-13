# Backlog: End-to-end Verification

Mục tiêu: xác nhận toàn bộ luồng /review:pr hoạt động đúng trên PR thật, không chỉ đọc code tĩnh.
User đã chọn: build code trước, chưa cần test PR thật ngay — các task dưới đây chạy KHI có PR test
thật, không phải điều kiện chặn việc build.

## Task V0: Chuẩn bị PR test (làm khi cần, không chặn build)
- Cần: ít nhất 1 PR chứa file Rails, 1 PR Vue, 1 PR mixed-stack (≥2 stack cùng lúc), 1 PR chứa file
  lambda handler, 1 PR Laravel/WordPress, 1 PR có sẵn thread comment đồng thuận convention (test re-review).

## Task V1: Test slice MVP (ứng Task P1)
- PR Rails hoặc Vue đơn giản → chạy `/review:pr <url>` → review xuất hiện trên GitHub, đúng format,
  không lỗi path/line từ GitHub API.
- Dependency: P1, V0.

## Task V2: Test multi-stack + overlay (ứng P2, P3)
- PR mixed-stack → verify đúng template áp dụng đúng file. PR lambda/laravel/wordpress → verify
  overlay xuất hiện tiêu chí đặc thù mà không mất tiêu chí nền.
- Dependency: P2, P3, V0.

## Task V3: Test memory bootstrap + idempotency (ứng P4)
- Lần 1 trên repo mới → verify `notebooks/review/<repo>/memory.md` + `memories/` + git nested +
  `.gitignore` tạo đúng. Lần 2 → verify không thao tác tạo/sửa lặp lại. Verify git nested KHÔNG có
  remote, không push.
- Dependency: P4, V0.

## Task V4: Test re-review + đề xuất lesson (ứng P5)
- PR có sẵn thread đồng thuận → verify agent đề xuất đúng, chờ xác nhận, chỉ ghi file sau khi user
  xác nhận. PR khác không liên quan → không bị quét nhầm.
- Dependency: P5, V0.

## Task V5: Test đầy đủ format post review (ứng P6, P7)
- Verify trên GitHub UI: review hiển thị đủ 3 mức 🔴🟡🟢, comment line-level đúng vị trí dòng diff,
  comment file-level hiển thị ở mức file, body tổng quan đúng đếm số.
- Dependency: P6, P7, V0.

## Task V6: Regression toàn bộ luồng trên 1 PR mới hoàn toàn
- Chạy lại toàn bộ luồng từ đầu trên 1 PR chưa từng review, xác nhận không bước nào bị bỏ sót/sai thứ tự.
- Dependency: tất cả task trên.

## Thứ tự: V0 (khi có nhu cầu test thật) → V1 → V2 → V3 → V4 → V5 → V6
