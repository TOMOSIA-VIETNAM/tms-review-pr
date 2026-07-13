AWS Lambda (serverless — overlay)

> File này CHỒNG THÊM (overlay) lên template ngôn ngữ nền — `python.md` khi handler là Python,
> `nodejs.md` khi handler là Node.js — áp dụng CẢ HAI khi review 1 file lambda handler, KHÔNG thay
> thế template ngôn ngữ nền. File này chỉ chứa tiêu chí ĐẶC THÙ serverless, không lặp lại tiêu chí
> ngôn ngữ nền đã có ở `python.md`/`nodejs.md`.

#### 1. Lỗi & Vấn đề logic

- Idempotency khi Lambda bị retry có được đảm bảo không — side-effect (ghi DB, gọi API ngoài, publish message) có an toàn khi handler bị gọi lại nhiều lần với cùng event không?
- Xử lý batch event (SQS/SNS/Kinesis/DynamoDB Streams) có đúng partial-failure không — có trả về đúng item bị lỗi (batch item failure) thay vì fail nguyên batch nếu framework/runtime hỗ trợ không?

#### 2. Bảo mật

- IAM policy trong `serverless.yml`/`template.yaml`/SAM có tuân theo least-privilege không — có dùng `*` cho action/resource một cách tùy tiện không?
- Env var nhạy cảm (API key, connection string, secret) có được lấy qua Parameter Store/Secrets Manager thay vì hardcode trong config/env plaintext không?

#### 3. Hiệu suất

- Cold start có được tối ưu không — logic khởi tạo nặng (kết nối DB, load SDK client, load model) có được đặt ở module-level/global scope thay vì bên trong handler (khởi tạo lại mỗi lần invoke) không?
- Timeout config có hợp lý so với thời gian thực thi thực tế của logic bên trong không (không quá ngắn gây timeout giả, không quá dài gây tốn chi phí khi hang)?
- Memory sizing có phù hợp với workload không (quá thấp gây chậm/OOM, quá cao gây lãng phí chi phí)?
- Kích thước deployment package/layer có được kiểm soát không (tránh package quá to làm cold start nặng hơn)?

#### 4. Chất lượng code

- Cấu hình hạ tầng (`serverless.yml`/`template.yaml`/SAM) có tách rõ theo environment (dev/staging/prod) không, tránh hardcode giá trị theo môi trường?
- Handler có tách rõ phần "adapter" (parse event, format response) khỏi business logic thuần không, để dễ test độc lập với runtime Lambda?

#### 5. Đặc thù Lambda/Serverless

- Structured logging có phù hợp với CloudWatch không (log dạng JSON, có kèm request id/correlation id để trace theo invocation)?
- Layer/dependency dùng chung giữa nhiều function có được tách qua Lambda Layer thay vì duplicate trong từng package không?
- Trigger/event source mapping (API Gateway, SQS, EventBridge, S3...) có cấu hình đúng (batch size, concurrency limit, DLQ cho message lỗi) không?

#### 6. Khả năng bảo trì & Dễ đọc

- Có comment giải thích lý do chọn memory/timeout/concurrency cụ thể (nếu có giá trị bất thường) không?
- Thiết kế có đủ linh hoạt để thêm trigger/event source mới trong tương lai không?
