React (component + hooks)

> Tiêu chí dưới đây BỔ SUNG cho baseline chung trong `ALWAYS_RULE.md` (áp dụng mọi stack) — không
> lặp lại các mục đã có ở đó.

#### 1. Lỗi & Vấn đề logic

- Loading/error state có được xử lý đúng không?
- `useEffect`/`useMemo`/`useCallback` có khai báo đủ dependency array không, hay thiếu dep dẫn tới stale closure, hoặc dư dep dẫn tới chạy lại không cần thiết?
- Cleanup side-effect khi component unmount có đầy đủ không (huỷ subscription, remove event listener, clear timer/interval trong return của `useEffect`)?

#### 2. Bảo mật

- Có nguy cơ XSS qua `dangerouslySetInnerHTML` không (dữ liệu user input được render ra HTML mà không sanitize)?
- Dữ liệu từ API có được validate/escape trước khi hiển thị không?

#### 3. Hiệu suất

- Có re-render thừa không? Props/callback truyền xuống component con có được bọc `useMemo`/`useCallback`/`React.memo` khi cần không?
- Danh sách render (`.map()`) có dùng `key` ổn định (id thực) thay vì index khi list có thể thêm/xoá/đổi thứ tự không?
- Có tính toán nặng chạy lại mỗi render mà đáng lẽ nên `useMemo` không?
- Có gọi API thừa không (nên dùng react-query/SWR thay vì fetch lặp lại)?

#### 4. Chất lượng code

JavaScript và TypeScript là 2 ngôn ngữ nền ngang hàng của React trong dự án này (`.jsx` lẫn `.tsx`
đều được review đầy đủ) — nhóm tiêu chí bên dưới chia rõ phần áp dụng chung và phần chỉ áp dụng khi
file là TypeScript.

Áp dụng chung cho cả `.jsx` và `.tsx`:

- Xem xét tách custom hook hoặc component dùng chung khi thấy lặp.
- State lifting/prop drilling có bị đẩy quá sâu qua nhiều tầng component không? Có nên dùng Context hoặc state management (Redux/Zustand/Recoil) thay thế không?

Riêng khi file là `.tsx`/`.ts` (TypeScript):

- Props/state/return type có được định nghĩa rõ ràng bằng interface/type không, tránh lạm dụng `any`?
- Generic type có được dùng hợp lý cho component/hook tái sử dụng không?
- Union type/discriminated union có được tận dụng để loại trừ state không hợp lệ (thay vì nhiều boolean rời rạc) không?

#### 5. Đặc thù React

- Component có error boundary bao bọc khi có khả năng throw (render lỗi, lỗi từ child) không?
- Custom hook có tuân thủ Rules of Hooks không (không gọi hook trong điều kiện/loop)?
- Controlled vs uncontrolled component có nhất quán không?
- Context API có bị lạm dụng gây re-render toàn cây khi chỉ 1 phần state đổi không?

#### 6. Khả năng bảo trì & Dễ đọc

- Component có quá lớn không? Nên tách nếu logic/JSX quá dài.
- Test có dùng React Testing Library/Jest không?
