# Stack detection

Ánh xạ mỗi file trong diff sang (các) stack review áp dụng. Một PR có thể trộn nhiều stack; giữ
danh sách cặp `(file, [stack áp dụng])`, không gán chung 1 stack cho cả PR khi các file thuộc stack
khác nhau.

## Bảng mapping đuôi file / path → stack nền

| Điều kiện file | Stack |
|---|---|
| `.rb`, `.erb`, `.haml` | `rails` |
| `.vue` | `vue` |
| `.jsx`, `.tsx` (không phải `.vue`; heuristic hỗ trợ: path chứa `src/components`, `pages/`, hoặc file có import `react`) | `react` |
| `.py` | `python` |
| `.js`, `.ts` còn lại (không thuộc `.vue` / `.jsx` / `.tsx` / thư mục FE nêu trên) | `nodejs` |
| `.sh`, `.bash` | `shell` |
| `Makefile`, `makefile`, `*.mk` | `makefile` |
| `.php` (không rơi vào overlay Laravel/WordPress bên dưới) | `php` |
| `.md` là chỉ dẫn cho AI agent, không phải docs cho người đọc (xem chú thích dưới bảng) | `agent-instructions` |

_Nhận diện `agent-instructions`: phán đoán qua NỘI DUNG, không phải chỉ đuôi file — giọng imperative
hướng dẫn hành động, không phải tường thuật cho người đọc. Ví dụ path/tên file minh hoạ, không giới
hạn ở đây: `.claude/commands/`, `.claude/skills/`, `.cursor/rules/`, `CLAUDE.md`, `AGENTS.md`,
`*.cursorrules`, `copilot-instructions.md`._

## Overlay (cộng thêm lên stack nền, không thay thế)

- **Lambda** — path chứa `lambda`/`lambdas`/`functions/`, HOẶC repo có `serverless.yml` /
  `template.yaml` / `sam.yaml`, HOẶC filename `handler.py`/`handler.js`/`index.py`/`index.js` nằm
  cạnh một trong các file config trên → cộng thêm `lambda-common` lên `python` (file `.py`) hoặc
  `nodejs` (file `.js`/`.ts`).
- **Laravel** — repo có `artisan`, `composer.json` chứa `laravel/framework`, hoặc path
  `app/Http/Controllers`, `resources/views/*.blade.php` → cộng thêm `laravel` lên `php`.
- **WordPress** — repo có `wp-config.php`, path `wp-content/plugins/` hoặc `wp-content/themes/`,
  hoặc `style.css` có theme header → cộng thêm `wordpress` lên `php`.
