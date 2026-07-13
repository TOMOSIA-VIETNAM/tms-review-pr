# Backlog: Review Templates (templates/*.md)

Mục tiêu: mỗi file trong templates/ chứa tiêu chí review theo khung 6 mục cố định (1. Lỗi & logic,
2. Bảo mật, 3. Hiệu suất, 4. Chất lượng code, 5. Đặc thù framework/language, 6. Khả năng bảo trì &
dễ đọc). Không chứa logic điều phối (đó là việc của `commands/pr.md`) — chỉ chứa NỘI DUNG tiêu chí.

**Convention baseline/delta (áp dụng từ lần refactor sau khi build xong V1):** tiêu chí CHUNG cho
mọi stack (mục 1,2,3,4,6 — vd "có bug rõ ràng không", "code có lặp không", "tên biến rõ ràng không",
"comment nơi logic phức tạp", "test coverage happy+error path", "thiết kế linh hoạt tương lai") sống
Ở `ALWAYS_RULE.md`, KHÔNG lặp lại trong từng file template. Mỗi `templates/<stack>.md` CHỈ chứa tiêu
chí THỰC SỰ đặc thù của stack đó — nếu 1 tiêu chí đang định viết trùng ý với baseline, không thêm
vào template, để agent tự áp dụng baseline. Toàn bộ danh sách (baseline lẫn template) phải giữ tinh
thần "gợi ý minh họa, không phải checklist đóng" — không viết dạng liệt kê đóng khung khiến agent
hiểu nhầm chỉ cần tìm đúng những ý đã ghi.

Dependency chung: cần Task S3 (thư mục `templates/` tồn tại) xong trước khi bắt đầu bất kỳ task nào.

**Lưu ý vai trò của `templates/` (plugin) vs local copy (per-repo):** file trong thư mục này là
THƯ VIỆN GỐC dùng chung cho mọi repo — không phải bản mà `pr.md` đọc trực tiếp lúc review. Mỗi repo
được review có bản LOCAL copy riêng tại `notebooks/review/<short_name>/templates/<stack>.md` (xem
Task M6, memory-system.md), được tạo lần đầu stack đó xuất hiện trong repo, và có thể được team tự
sửa riêng. Nếu plugin CHƯA có template cho 1 stack, agent tự soạn thẳng vào bản local — việc thêm
file mới vào chính `templates/` (để dùng chung cho repo khác) là thao tác thủ công của
user/maintainer plugin, không tự động.

## Task T1: `templates/rails.md`
- Nguồn: port nguyên khung 6 mục từ `review_be.md` (gộp API + View, giữ nguyên tiêu chí, bỏ phần
  context/gh-command/post vì đó là việc của pr.md).
- Acceptance: đủ 6 heading `#### 1..6`, nội dung tiêu chí y hệt review_be.md, không bịa thêm/bớt,
  không chứa `gh pr view/diff` hay hướng dẫn post.

## Task T2: `templates/vue.md`
- Nguồn: port nguyên khung 6 mục từ `review_fe.md`, giữ nguyên vị trí tiêu chí Vue-specific đang
  rải ở mục 3 và 4 (không dồn hết về mục 5).
- Acceptance: đủ 6 heading, tiêu chí Vue (v-html, v-for key, computed vs methods, Vuex,
  nuxt-property-decorator...) giữ đúng vị trí như bản gốc.

## Task T3: `templates/react.md` (soạn mới)
- Acceptance tối thiểu: hooks deps array (useEffect/useMemo/useCallback), key trong list render,
  re-render thừa (memo/useCallback), state lifting/prop drilling, XSS qua
  `dangerouslySetInnerHTML`, error boundary, cleanup khi unmount (subscription/listener), test
  (RTL/jest) happy+error path.

## Task T4: `templates/python.md` (soạn mới)
- Acceptance tối thiểu: type hints, exception handling (bare except, exception chaining), context
  manager cho resource (file/db/socket), N+1 query nếu dùng ORM (SQLAlchemy/Django), mutable
  default argument, config qua env, logging thay vì print, test (pytest) coverage.

## Task T5: `templates/nodejs.md` (soạn mới, backend runtime — không phải React)
- Acceptance tối thiểu: async/await error handling (unhandled rejection), N+1 query ORM
  (Sequelize/Prisma/TypeORM), input validation trước business logic, secret/env handling, module
  boundary, structured logging, test (jest/mocha) coverage. Không cover JSX/component (đó là react.md).

## Task T6: `templates/lambda-common.md` (CHỒNG lên python.md/nodejs.md)
- Acceptance:
  - Chỉ chứa tiêu chí ĐẶC THÙ serverless, không lặp nội dung đã có ở python.md/nodejs.md: cold
    start, timeout config, memory sizing, idempotency khi retry, IAM least-privilege trong
    serverless.yml/template.yaml/SAM, structured logging CloudWatch, kích thước package/layer, env
    var qua Parameter Store/Secrets Manager thay vì hardcode, xử lý batch event SQS/SNS đúng
    partial-failure.
  - Ghi chú đầu file: "File này CHỒNG THÊM lên template ngôn ngữ nền (python.md hoặc nodejs.md) khi
    path/pattern khớp handler lambda — không thay thế template ngôn ngữ nền."
- Dependency: T4, T5 (tránh trùng lặp tiêu chí).

## Task T7: `templates/shell.md` (soạn mới)
- Acceptance tối thiểu: `set -euo pipefail`, quoting biến, kiểm tra exit code lệnh con, `[[ ]]`
  thay `[ ]`, tránh parse `ls`, shellcheck-clean, idempotency khi chạy lại, xử lý path có khoảng trắng.

## Task T8: `templates/makefile.md` (soạn mới)
- Acceptance tối thiểu: `.PHONY` khai báo đủ target không sinh file, tránh side-effect ẩn trong
  target mặc định, dùng biến thay vì hardcode path, dependency đúng thứ tự, DRY qua pattern
  rule/include, check exit code lệnh con.

## Task T9: `templates/php.md` (soạn mới — nền chung PHP thuần)
- Acceptance tối thiểu: type juggling (`==` vs `===`), SQL injection (dùng PDO prepared statement,
  không nội suy chuỗi), autoload PSR-4/composer, error/exception handling, escape output
  (htmlspecialchars) chống XSS, session/cookie an toàn (httponly/secure flag), test (PHPUnit)
  coverage.

## Task T10: `templates/laravel.md` (CHỒNG lên php.md)
- Acceptance:
  - Chỉ chứa tiêu chí ĐẶC THÙ Laravel, không lặp rule PHP nền đã có ở php.md: Eloquent (N+1 query,
    `with`/`load` eager loading), mass assignment (`$fillable`/`$guarded`), Form Request validation,
    Blade template (escape `{{ }}` vs `{!! !!}`), middleware/policy cho authorization, queue/job
    error handling, migration an toàn (rollback), route model binding.
  - Ghi chú đầu file: "File này CHỒNG THÊM lên php.md — không thay thế."
- Dependency: T9.

## Task T11: `templates/wordpress.md` (CHỒNG lên php.md)
- Acceptance:
  - Chỉ chứa tiêu chí ĐẶC THÙ WordPress, không lặp rule PHP nền đã có ở php.md: hooks/filters
    (`add_action`/`add_filter` đúng priority, không side-effect ẩn), nonce verification cho
    form/AJAX, sanitize input (`sanitize_text_field`...) + escape output (`esc_html`/`esc_attr`...),
    capability check (`current_user_can`) trước hành động nhạy cảm, dùng `$wpdb->prepare` thay nội
    suy chuỗi SQL, cấu trúc plugin/theme (không hardcode path, dùng `plugin_dir_path`), enqueue
    script/style đúng cách (không hardcode `<script>` trực tiếp).
  - Ghi chú đầu file: "File này CHỒNG THÊM lên php.md — không thay thế."
- Dependency: T9.

## Thứ tự khuyến nghị
T1, T2 trước (đã có sẵn nội dung từ file tham khảo, dùng test vertical-slice sớm nếu cần) → song
song T3/T4/T5/T7/T8/T9 → T6 (phụ thuộc T4+T5), T10+T11 (phụ thuộc T9) sau cùng.
