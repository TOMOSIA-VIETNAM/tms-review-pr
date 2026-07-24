# Backlog: `/tms:fix-pr`

Spec đầy đủ tại `SPEC.md` (cùng thư mục) — đã grilling xong với user, không còn quyết định thiết
kế mở. Backlog này chỉ tách task theo đúng nội dung spec, không tự thêm/đổi quyết định.

## Task FC1: Scaffold `src/commands/fix-pr.md` — frontmatter + Bước 0-2 (verify + bootstrap)
- Acceptance:
  - Frontmatter đúng: `allowed-tools` theo ĐÚNG danh sách mục 5 SPEC.md (không thêm/thiếu pattern
    nào), `argument-hint: <GitHub PR URL> [chỉ dẫn tự do]`, `description` ngắn phân biệt rõ với
    `/tms:review-pr` (dev-facing, sửa code thật).
  - Bước 0 (validate ARGUMENTS) + block context lấy URL/owner/repo/pull_number — PHẢI dùng heredoc
    quote-delimiter (`<<'DELIM'`) khi đọc `$ARGUMENTS`, copy đúng kỹ thuật từ block "Ngữ cảnh" của
    `src/commands/review-pr.md` (KHÔNG splice `$ARGUMENTS` thô vào double-quote/echo — đây là bug
    đã fix thật ở `review-pr.md`, không lặp lại).
  - Bước verify an toàn (mục 2 SPEC.md bước 1): `git remote` khớp owner/repo, branch hiện tại khớp
    `headRefName` PR (fetch qua `gh pr view --json headRefName`), branch hiện tại KHÔNG khớp CHÍNH
    XÁC (case-insensitive, không substring) 1 trong danh sách bảo vệ ở SPEC.md mục 2 bước 1. Sai 1
    trong 3 → in lỗi cụ thể, DỪNG hẳn, không tự sửa gì.
  - Bootstrap (mục 2 SPEC.md bước 2): file `notebooks/review/<repo>/fix-pr-meta.json` (schema
    mục 6 SPEC.md) chưa tồn tại → hỏi đúng 2 câu (`decline_needs_confirmation` default `true`,
    `auto_push` default `false`) trong 1 lượt, kèm recommend, chờ trả lời, ghi file. Đã tồn tại →
    đọc thẳng, không hỏi.
  - Test case: (a) branch sai → dừng đúng, không đụng file nào; (b) branch bảo vệ (vd `develop`) →
    dừng đúng; (c) branch feature tên `feature/develop-x` → KHÔNG bị chặn (verify match chính xác,
    không substring); (d) lần đầu trên repo → hỏi đúng 2 câu, ghi đúng file; (e) lần 2 → không hỏi
    lại.
- Dependency: không (điểm bắt đầu).

## Task FC2: Bước 3-4 — nhận diện finding cần xử lý + đọc convention dự án
- Acceptance:
  - Bước 3: `gh api user --jq .login` → lọc comment top-level khớp account + marker
    `<!-- bot-finding -->` (hoặc fallback pre-marker) — **tái dùng nguyên văn logic marker/fallback
    của `src/cases/re-review.md` mục "Kiểm tra finding cũ..."** (không copy-paste lại, viết dạng
    "áp dụng đúng logic khớp marker/fallback đã mô tả trong `re-review.md`, `Read` file đó nếu cần
    đối chiếu"). GraphQL `reviewThreads` (đọc `isResolved`) loại thread đã resolve.
  - Áp `[chỉ dẫn tự do]` (nếu ARGUMENTS có ngoài URL) để thu hẹp danh sách finding — agent tự hiểu
    theo ngữ nghĩa, không cần cú pháp cứng.
  - Bước 4: với mỗi file có finding, map stack qua `src/stack-detection.md`, đọc LOCAL
    `notebooks/review/<repo>/ALWAYS_RULE.md` + `memory.md`/`memories/*.md` liên quan + template
    stack LOCAL (nếu `notebooks/review/<repo>/` không tồn tại — repo chưa từng `/tms:review-pr` —
    bỏ qua bước này, fix theo phán đoán thường, KHÔNG chặn/báo lỗi).
  - Test case: PR có finding từ 1 human comment thường (không marker) → KHÔNG bị agent coi là bot
    finding, không xử lý; PR toàn bộ thread đã resolve → danh sách rỗng, sang bước báo "không có gì
    để fix", DỪNG gọn (không tiếp tục các bước sau).
- Dependency: FC1.

## Task FC3: Bước 5-7 — quyết định fix/decline theo severity + gộp câu hỏi + sửa code
- Acceptance:
  - Với MỖI finding: đọc finding gốc + MỌI reply đã có trên đúng thread. Thread có human reply rõ
    ràng (đồng ý/không cần fix) → bỏ qua hoàn toàn finding đó, không hỏi lại, không tự fix đè.
  - 🔴/🟠 → default FIX; agent tự thấy sai/không hợp lý → rẽ theo `decline_needs_confirmation`
    (đọc từ `fix-pr-meta.json`): `true` hỏi dev trước khi quyết decline, `false` tự quyết.
  - 🔵/📝 → KHÔNG bao giờ tự quyết (bất kể setting) — LUÔN nêu recommend (nên/không nên + lý do +
    phạm vi) cho dev, KHÔNG hành động cho tới khi có trả lời.
  - Gộp TẤT CẢ câu hỏi 🔵/📝 (nếu có) thành 1 câu duy nhất, hỏi TRƯỚC, chờ dev trả lời đầy đủ, rồi
    MỚI qua bước sửa code cho toàn bộ finding đã quyết fix (không sửa code nào trước khi có đủ
    quyết định của TẤT CẢ finding trong lượt này).
  - Code sửa đúng convention đọc ở FC2 (naming, structure theo template stack + `ALWAYS_RULE.md`).
  - Test case: 1 PR có cả 🔴 và 🔵 → phải thấy câu hỏi về 🔵 xuất hiện TRƯỚC khi bất kỳ file nào bị
    `Edit`; 1 finding có human đã reply "đây là behavior có chủ đích" → verify finding đó KHÔNG bị
    sửa code, không bị hỏi lại.
- Dependency: FC2.

## Task FC4: Bước 8-9 — commit (1 commit/lượt, không amend) + push theo `auto_push`
- Acceptance:
  - `git add` CHỈ đúng file đã `Edit` cho lượt fix này (liệt kê rõ path, KHÔNG `git add -A`/`.`).
  - 1 commit DUY NHẤT cho toàn bộ finding đã fix trong lượt — message theo convention đã học ở
    FC2 nếu có, fallback `fix: address review comments (PR #<n>)` + bullet tóm tắt mỗi finding.
    TUYỆT ĐỐI KHÔNG `git commit --amend`.
  - `auto_push: false` (default) → DỪNG ở local, báo dev 1 câu ngắn (mẫu SPEC.md mục 2 bước 9),
    KHÔNG tiến hành bước reply (FC5) tới khi dev gõ ý định push (match theo ý định, không string
    cứng) — dev gõ xong → `git push` (KHÔNG `--force`), rồi mới qua FC5.
  - `auto_push: true` → `git push` (KHÔNG `--force`) ngay sau commit, rồi qua FC5 luôn trong lượt.
  - Test case: working tree có sẵn 1 file KHÁC đang sửa dở (không liên quan finding) → verify file
    đó KHÔNG bị đưa vào commit; gọi lệnh push giả lập (`--force`/`--force-with-lease` không có mặt
    trong bất kỳ lệnh git nào được gọi).
- Dependency: FC3.

## Task FC5: Bước 10-11 — reply lên PR (marker `<!-- bot-reply -->`) + lesson-saving + reconfigure trigger
- Acceptance:
  - Reply CHỈ chạy sau khi code đã lên remote thật (sau FC4 hoàn tất push, không phải ngay sau
    commit local).
  - Finding LINE-level → `POST /pulls/comments/{comment_id}/replies`, nội dung ngắn (không kể lể
    quá trình — xem SPEC.md mục 2 bước 10 + "Tone"), kết `<!-- bot-reply -->`.
  - Finding OVERVIEW-level (không `line`/`path`) → `POST /repos/{owner}/{repo}/issues/{pull_number}/comments`
    (endpoint MỚI, không dùng cho line-level), nội dung dẫn link
    `https://github.com/<owner>/<repo>/pull/<n>#pullrequestreview-<review_id>` — KHÔNG blockquote
    nguyên văn review, kết `<!-- bot-reply -->`.
  - Finding decline (không fix) → reply/comment tương tự đúng loại LINE/OVERVIEW, nêu lý do ngắn,
    cũng kết `<!-- bot-reply -->`.
  - KHÔNG bao giờ tự resolve thread (không có nhánh code nào gọi `resolveReviewThread` trong file
    này).
  - Lesson-saving: phát hiện finding phản ánh convention chung → đề xuất trong chat (nội dung + tag
    stack + Recommend + lý do), chờ dev xác nhận, chỉ ghi sau đồng ý, theo Phần E `setup-flow.md`.
  - Reconfigure trigger: dev gõ ý định "đổi cấu hình fix-pr" (hay tương đương) → in giá trị
    hiện tại `fix-pr-meta.json`, hỏi field muốn đổi, ghi ngay.
  - Test case: reply 1 LINE finding + 1 OVERVIEW finding trong cùng lượt → verify đúng 2 endpoint
    khác nhau được gọi, cả 2 reply đều có marker; review lại nội dung reply không chứa câu kể lể
    kiểu "đã đọc file X rồi kiểm tra Y".
- Dependency: FC4.

## Task FC6: `src/cases/re-review.md` — thêm marker `<!-- bot-reply -->` vào reply xác nhận có sẵn
- Acceptance:
  - Câu reply xác nhận đã fix hiện có ("Xác nhận đã fix, cảm ơn bạn!"/"Confirmed fixed, thanks!",
    nhánh "Đã fix" trong mục "Kiểm tra finding cũ...") → thêm marker `<!-- bot-reply -->` ngay sau
    câu đó, giống cách `<!-- bot-finding -->` được đặt cuối khung finding ở `review-pr.md`.
  - Không đổi logic khác của file (chỉ thêm marker, không đổi hành vi resolve/reaction).
- Dependency: không (độc lập nội dung với FC1-FC5, có thể làm song song) — nhưng nên làm TRƯỚC
  FC5 để khi viết ví dụ/tham chiếu marker trong `fix-pr.md` đã đúng thực tế 2 nơi đều có.

## Task FC7: `CLAUDE.md` — thêm `fix-pr.md` vào bảng cấu trúc + mục kiến trúc
- Acceptance:
  - Bảng cấu trúc (mục "Cấu trúc") thêm dòng `src/commands/fix-pr.md` theo đúng format cột
    hiện có (mô tả ngắn, phân biệt rõ với `review-pr.md`: dev-facing, sửa code thật, không qua
    worktree).
  - Mục "Kiến trúc cốt lõi": thêm đoạn mô tả kiến trúc `fix-pr.md` theo đúng văn phong các
    đoạn hiện có (bullet đậm mở đầu + giải thích, không kể lể lịch sử/lý do bug — phần đó để riêng
    nếu có).
  - Nếu marker `<!-- bot-reply -->` cần giải thích xuyên suốt 2 lệnh → thêm đúng 1 đoạn mô tả, tránh
    lặp lại đoạn đã có về `<!-- bot-finding -->`.
- Dependency: FC1-FC5 (mô tả đúng hành vi thật đã build, không mô tả trước khi code xong).

## Task FC8: `README.md` / `README.en.md` / `README.ja.md` — giới thiệu `/tms:fix-pr`
- Acceptance:
  - Thêm 1 mục ngắn (đồng bộ cả 3 bản ngôn ngữ, đúng cấu trúc heading tương ứng đã có) giới thiệu
    `/tms:fix-pr`: dùng khi nào (đã có review, muốn fix), khác gì `/tms:review-pr` (dev-facing,
    sửa code thật, không phải bot review), ví dụ lệnh gọi.
  - Không lặp lại toàn bộ chi tiết luồng (đó là việc của `SPEC.md`/`CLAUDE.md`) — README chỉ giới
    thiệu ở mức người dùng cuối cần biết để bắt đầu dùng.
- Dependency: FC1-FC5.

## Thứ tự: FC1 → FC2 → FC3 → FC4 → FC5, với FC6 làm song song (trước hoặc trong lúc FC1-FC5,
khuyến nghị trước FC5) → FC7, FC8 làm SAU CÙNG (mô tả đúng cái đã build xong).
