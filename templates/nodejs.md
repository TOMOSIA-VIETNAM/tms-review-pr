Node.js (backend runtime — không cover JSX/component, xem `react.md`)

> Tiêu chí dưới đây BỔ SUNG cho baseline chung trong `ALWAYS_RULE.md` (áp dụng mọi stack) — không
> lặp lại các mục đã có ở đó.

#### 1. Lỗi & Vấn đề logic

- Async/await có xử lý lỗi đầy đủ không — có `try/catch` quanh `await`, có tránh unhandled promise rejection (Promise không được `await`/`.catch()`) không?
- Callback có xử lý error-first convention đúng không (nếu còn dùng callback style)?

#### 2. Bảo mật

- Có dùng `dotenv`/secret manager thay vì hardcode secret không?
- Input từ client có được validate trước khi vào business logic không (Joi/Zod/express-validator hay tự kiểm tra tay có thiếu sót không)?
- Có nguy cơ injection (SQL/NoSQL/command injection) qua input không được sanitize không?

#### 3. Hiệu suất

- Có vấn đề N+1 query nếu dùng ORM (Sequelize/Prisma/TypeORM) không — có thiếu `include`/eager loading không?
- Có block event loop bởi tác vụ đồng bộ nặng (CPU-bound) không? Có nên đẩy ra worker thread/queue không?

#### 4. Chất lượng code

JavaScript và TypeScript là 2 ngôn ngữ nền ngang hàng cho Node.js backend trong dự án này (`.js`
lẫn `.ts` đều được review đầy đủ) — nhóm tiêu chí bên dưới chia rõ phần áp dụng chung và phần chỉ
áp dụng khi file là TypeScript.

Áp dụng chung cho cả `.js` và `.ts`:

- Module boundary có rõ ràng không — tránh circular dependency, tránh "God file" gom quá nhiều trách nhiệm?
- Error object/custom error class có được định nghĩa nhất quán không (không throw string/object tuỳ tiện)?

Riêng khi file là `.ts` (TypeScript):

- Type/interface cho input, output, DTO có được định nghĩa rõ ràng không, tránh lạm dụng `any`?
- Type của layer bên ngoài (request body, query param, response từ API/DB) có được validate/narrow đúng runtime type trước khi tin tưởng static type không (tránh chỉ tin type declare mà không có validate thật ở boundary)?
- Generic type có được dùng hợp lý cho hàm/class tái sử dụng không?

#### 5. Đặc thù Node.js

- Structured logging có được dùng không (Winston/Pino) thay vì `console.log` tuỳ tiện trong code production?
- Cấu hình/env var có được quản lý tập trung (config module) thay vì đọc `process.env` rải rác không?
- Middleware/handler có tách rõ trách nhiệm (routing, validation, business logic, data access) không?

#### 6. Khả năng bảo trì & Dễ đọc

- Test có dùng Jest/Mocha không?
