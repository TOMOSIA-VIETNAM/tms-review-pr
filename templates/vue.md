Vue 2/3, Nuxt

#### 1. Lỗi & Vấn đề logic

- Có bug rõ ràng hoặc lỗi logic nào không?
- Các trường hợp biên (null/undefined, mảng rỗng, giá trị giới hạn) có được xử lý đúng không?
- Xử lý lỗi cho các thao tác async (Promise, async/await, axios) có phù hợp không?
- Dữ liệu từ API có được validate trước khi render không?

#### 2. Bảo mật

- Có nguy cơ XSS qua `v-html` không (dữ liệu user input không được escape)?
- Code có chứa thông tin nhạy cảm (API key, token, mật khẩu) không? Kiểm tra file `.env` không được commit.
- Các API call có gắn token xác thực đúng không?

#### 3. Hiệu suất

- Có re-render không cần thiết không? Kiểm tra `computed` thay vì `methods` cho giá trị phụ thuộc reactive.
- `v-for` có dùng `:key` đúng (không dùng index làm key khi danh sách có thể thay đổi thứ tự) không?
- Có API call thừa không? Có thể cache bằng Vuex hay `computed` không?
- Instance Component có được destroy đúng trong `beforeDestroy` không?
- Ảnh và static asset có được tối ưu không?

#### 4. Chất lượng code

- Tên biến/hàm/component có rõ ràng và theo convention của dự án không?
- Có code bị lặp không (nguyên tắc DRY)? Xem xét tách thành mixin hoặc composable.
- TypeScript type có được định nghĩa đúng không (không lạm dụng `any`)? Interface nên đặt trong thư mục `interfaces/`.
- Hằng số có được đặt trong thư mục `constants/` không?
- Utility function có được đặt trong thư mục `utils/` không?

#### 5. Nuxt 2 / Vue 2 cụ thể

- **Component**: Dùng `@Component` decorator (nuxt-property-decorator) đúng cách không? `@Prop`, `@Watch`, `@Emit` có được dùng thay vì Options API thuần không?
- **Vuex**: Action/mutation/getter có được đặt đúng module không? Tránh commit mutation trực tiếp từ component, dùng action thay thế.
- **Routing**: Dùng `nuxt-link` thay `router-link`, `this.$router.push` có xử lý lỗi không?
- **Lifecycle hooks**: `mounted` vs `created` có được dùng đúng ngữ cảnh (SSR-aware) không? Tránh DOM access trong `created`.
- **API calls**: Dùng `@nuxtjs/axios` (`this.$axios`) thống nhất không? Error handling có dùng try/catch hoặc `.catch()` không?
- **Ant Design Vue**: Component import có đúng không? Event listener dùng `@change` / `@click` thay vì `v-on` thuần không?
- **SCSS**: Style có scoped (`<style scoped>`) không? Tránh override global style không cần thiết. Biến SCSS có import từ `assets/` không?
- **nuxt.config.js**: Nếu có thay đổi config, kiểm tra plugin/module đăng ký đúng không, tránh thêm thư viện nặng vào `head` global.

#### 6. Khả năng bảo trì & Dễ đọc

- Component có quá lớn không? Nên tách nếu vượt ~300 dòng.
- Có comment ở những nơi logic phức tạp (ví dụ: tính toán chart, xử lý dữ liệu IoT) không?
- Thiết kế có đủ linh hoạt để đáp ứng thay đổi trong tương lai không?
- ESLint/Prettier có pass không? Không nên có `// eslint-disable` mà không có lý do.
