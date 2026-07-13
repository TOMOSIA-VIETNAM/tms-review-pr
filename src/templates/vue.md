# Vue 2/3, Nuxt

_Bổ sung cho baseline `ALWAYS_RULE.md`; chỉ liệt kê tiêu chí đặc thù stack, không lặp baseline._

#### 1. Lỗi & Vấn đề logic

- Xử lý lỗi cho các thao tác async (Promise, async/await, axios) có phù hợp không?
- Dữ liệu từ API có được validate trước khi render không?

#### 2. Bảo mật

- Có nguy cơ XSS qua `v-html` không (dữ liệu user input không được escape)?
- Kiểm tra file `.env` không được commit.
- Các API call có gắn token xác thực đúng không?

#### 3. Hiệu suất

- Có re-render không cần thiết không? Kiểm tra `computed` thay vì `methods` cho giá trị phụ thuộc reactive.
- `v-for` có dùng `:key` đúng (không dùng index làm key khi danh sách có thể thay đổi thứ tự) không?
- Instance Component có được destroy đúng trong `beforeDestroy` không?
- Ảnh và static asset có được tối ưu không?

#### 4. Chất lượng code

- Xem xét tách code lặp thành mixin hoặc composable.
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
- ESLint/Prettier có pass không? Không nên có `// eslint-disable` mà không có lý do.
