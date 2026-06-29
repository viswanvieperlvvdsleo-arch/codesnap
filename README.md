# 🖥️ CodeSnap — Collaborative Coding Platform

> A modern, full-featured collaborative coding platform built for **teachers and students**. CodeSnap allows teachers to create and assign coding tasks, students to write and submit code in a live editor, and everyone to explore a rich project library — all in one place.

---

## 🚀 Tech Stack

| Technology | Purpose |
|---|---|
| **Next.js 15** | React framework with App Router |
| **React 19** | UI component library |
| **TypeScript** | Type-safe JavaScript |
| **Tailwind CSS** | Utility-first styling |
| **shadcn/ui + Radix UI** | Accessible, composable UI components |
| **Monaco Editor** | VS Code-style in-browser code editor |
| **Framer Motion** | Animations and transitions |
| **Lucide React** | Icon library |
| **Recharts** | Data visualization charts |
| **Zod + React Hook Form** | Form validation |

---

## 📁 Project Structure

```
codesnap/
├── src/
│   ├── app/                     # Next.js App Router pages
│   │   ├── (dashboard)/         # Protected dashboard routes
│   │   │   ├── layout.tsx       # Dashboard shell (auth guard + header)
│   │   │   ├── page.tsx         # Redirects / → /tasks
│   │   │   ├── tasks/           # Tasks management page
│   │   │   ├── learn/           # Learning curriculum page
│   │   │   ├── projects/        # Project library page
│   │   │   ├── workspace/       # Live code editor page
│   │   │   └── profile/         # User profile page
│   │   ├── login/               # Login page
│   │   ├── register/            # Register page
│   │   ├── layout.tsx           # Root HTML layout (fonts, providers)
│   │   ├── globals.css          # Global CSS & Tailwind directives
│   │   ├── providers.tsx        # App-level context providers
│   │   └── template.tsx         # Page transition wrapper
│   ├── components/              # Reusable UI components
│   │   ├── layout/              # Header & sidebar navigation
│   │   ├── cards/               # TaskCard component
│   │   ├── editor/              # Monaco code editor wrapper
│   │   ├── workspace/           # Submit & upload modals
│   │   ├── tasks/               # Task modals and drawers
│   │   ├── projects/            # Project cards and modals
│   │   ├── learn/               # Learning section components
│   │   └── ui/                  # Base shadcn/ui primitives
│   ├── contexts/                # React context providers
│   │   ├── auth-provider.tsx    # Auth state (login/logout/user)
│   │   └── theme-provider.tsx   # Dark/light/system theme
│   ├── hooks/                   # Custom React hooks
│   │   ├── use-toast.ts         # Toast notification system
│   │   └── use-mobile.tsx       # Mobile viewport detection
│   └── lib/                     # Utilities and data
│       ├── types.ts             # TypeScript type definitions
│       ├── mock-data.ts         # All mock users, tasks, projects, etc.
│       ├── learn-content.ts     # 30-day coding curriculum content
│       ├── utils.ts             # Tailwind class merge utility
│       ├── placeholder-images.ts # Image URL helpers
│       └── placeholder-images.json
├── .gitignore                   # Git ignore rules
├── next.config.ts               # Next.js configuration
├── tailwind.config.ts           # Tailwind CSS configuration
├── components.json              # shadcn/ui component config
├── tsconfig.json                # TypeScript configuration
└── package.json                 # Dependencies and scripts
```

---

## 📄 File-by-File Explanation

### 🏗️ Root Configuration Files

#### `package.json`
Defines all dependencies and scripts:
- `npm run dev` — Start development server
- `npm run build` — Build for production
- `npm run start` — Run production build
- `npm run lint` — Lint the codebase
- `npm run typecheck` — Type check without emitting files

#### `next.config.ts`
Next.js configuration:
- Disables TypeScript and ESLint build errors (for rapid prototyping)
- Allows images from `picsum.photos` for placeholder thumbnails

#### `tailwind.config.ts`
Tailwind CSS config with custom design tokens, color palette, and animation extensions used throughout the app.

#### `tsconfig.json`
TypeScript compiler options. Uses path alias `@/*` → `./src/*` so imports like `@/components/ui/button` work cleanly.

#### `components.json`
shadcn/ui configuration — defines where UI components live, which CSS variables are used, and the icon library (lucide).

---

### 🗂️ `src/app/` — Pages (Next.js App Router)

#### `layout.tsx` *(Root Layout)*
The outermost HTML shell. Sets:
- `dark` mode as the default color scheme
- **Inter** (body) and **JetBrains Mono** (code) Google Fonts
- Wraps all pages in `<Providers>` and includes `<Toaster>` for global toast notifications

**Output:** Every page inherits this layout — dark background, correct fonts, and toast support.

---

#### `providers.tsx`
Wraps the app with `AuthProvider` (user session) and `ThemeProvider` (dark/light/system switching).

---

#### `template.tsx`
Applies a **Framer Motion fade-in animation** every time you navigate to a new page.

**Output:** Smooth page transitions when navigating between routes.

---

#### `globals.css`
Global CSS with Tailwind base directives and CSS custom properties (design tokens) for the color palette — primary, background, foreground, card, muted, accent, etc.

---

### 🔐 `src/app/login/` — Login Page

**Route:** `/login`

**What it does:**
- Displays a centered card with the CodeSnap logo
- Users pick a role: **Student** or **Teacher** (tab switcher)
- Enter email and password, click **Login**
- Authenticates against `mockUsers` in `mock-data.ts`
- Stores the logged-in user in `sessionStorage` and redirects to `/tasks`

**Output:** A login card with role selector tabs, email/password fields, animated entrance, and a register link.

> ⚠️ This is a **mock auth system** — no real backend. Any valid email format works.

---

### 📝 `src/app/register/` — Register Page

**Route:** `/register`

**What it does:**
- Provides a registration form (mock — no real account creation)
- Links back to `/login`

---

### 🛡️ `src/app/(dashboard)/layout.tsx` — Dashboard Layout

All routes inside `(dashboard)/` use this layout. It:
- Checks if a user is logged in via `useAuth()`
- If not logged in, redirects to `/login`
- If checking (loading), shows a **spinning loader**
- If logged in, renders `<Header />` above the page content

**Output:** Protected layout with top navigation bar visible on all dashboard pages.

---

### ✅ `src/app/(dashboard)/tasks/` — Tasks Page

**Route:** `/tasks`

**What it shows:**

| Role | View |
|---|---|
| **Teacher** | All tasks with edit/delete/view submissions controls |
| **Student** | Only tasks assigned to their section |

**Features:**
- 🔍 Search tasks by title
- 🗂️ Filter by Course, Branch, Section, Year
- ➕ Teachers can **Import (create/edit)** tasks via a modal
- ⚙️ Teachers can **Manage Academic Options** (add/remove courses, branches, sections, years)
- 📋 Teachers can **view all student submissions** for a task in a side drawer
- 📭 Empty state shown when no tasks match filters

**Output:** A responsive grid of task cards, each showing title, deadline, course, section, and action buttons.

---

### 🎓 `src/app/(dashboard)/learn/` — Learn Page

**Route:** `/learn`

**What it does:**
- Presents a **30-day structured coding curriculum** (from `learn-content.ts`)
- Covers HTML, CSS, and JavaScript day by day
- Each day has:
  - 📖 Theory explanation
  - 💻 Code example (syntax highlighted)
  - 🧩 A mini coding task

**Output:** An interactive learning hub with daily lessons organized by topic category.

---

### 🗂️ `src/app/(dashboard)/projects/` — Projects Library Page

**Route:** `/projects`

**What it does:**
- Displays a library of **pre-built project templates** (from `mock-data.ts`)
- Filter by: **Category** (E-Commerce, Dashboard, Portfolio, etc.) and **Difficulty** (Beginner / Intermediate / Advanced)
- Search by project title
- Each project card has:
  - 👁️ **Preview** button — opens a live preview in a modal
  - 📋 **Details** button — shows full project info, tech stack, features, estimated time

**Output:** A searchable, filterable 3-column grid of project cards with live preview support.

---

### 💻 `src/app/(dashboard)/workspace/` — Code Workspace Page

**Route:** `/workspace` (or `/workspace?taskId=...` or `/workspace?projectId=...`)

**What it does:**
The core coding environment. Uses **Monaco Editor** (the engine powering VS Code).

| Feature | Description |
|---|---|
| **Monaco Editor** | Full VS Code-like code editor with syntax highlighting |
| **Live Preview** | Renders HTML/CSS/JS code in a live `<iframe>` |
| **Console Logs** | Captures and displays `console.log`, warnings, errors |
| **Undo / Redo** | Code history navigation |
| **File Upload** | Load a local `.html` file into the editor |
| **File Download** | Save the current code as a `.html` file |
| **Submit** | Students can submit code for a task (opens confirmation modal) |
| **Upload to Project** | Save workspace code to a project template |
| **Open in New Tab** | Opens the live preview in a separate browser tab |

When opened with a `?taskId=` param, it pre-loads the task's **starter code**.  
When opened with a `?projectId=` param, it pre-loads the full project template.

**Output:** A split-panel IDE with editor on the left and live HTML preview + console on the right.

---

### 👤 `src/app/(dashboard)/profile/` — Profile Page

**Route:** `/profile`

**What it shows:**
- Logged-in user's name, email, role, section
- Avatar and account information

---

## 🧩 `src/components/` — Reusable Components

### `layout/Header.tsx`
The sticky top navigation bar. Contains:
- **CodeSnap logo** (links to `/tasks`)
- **Nav links:** Tasks, Learn, Projects, Workspace (highlighted based on current route)
- **Breadcrumb** trail showing the current page path
- **Share button** — copies the current URL to clipboard with a toast
- **Notification bell** — with animated ping indicator
- **User avatar dropdown** — shows Profile, Theme switcher (Light/Dark/System), and Logout

### `layout/SidebarNav.tsx`
An icon-only sidebar used in some layout variants. Shows tooltip labels on hover for Tasks, Learn, Projects, and Workspace.

### `cards/TaskCard.tsx`
A card component for each task. Displays:
- Title, description, course, section, year, branch, deadline
- Submission count badge
- **Teacher controls:** Edit, Delete, View Submissions buttons
- **Student controls:** Open in Workspace button
- Color-coded deadline indicator (red if past due)

### `editor/CodeEditor.tsx`
A thin wrapper around `@monaco-editor/react`. Configures the editor with:
- Dark theme (`vs-dark`)
- HTML language mode
- Word wrap enabled
- Minimap enabled

### `workspace/SubmitModal.tsx`
A confirmation dialog shown before a student submits their code. Confirms the submission action.

### `workspace/UploadToProjectModal.tsx`
A modal that lets users save their workspace code back to a project template in the library.

### `tasks/ImportTaskModal.tsx`
A form modal (used by teachers) to **create or edit** a task. Fields include title, description, course, branch, section, year, deadline, and optional starter code.

### `tasks/ManageAcademicOptionsModal.tsx`
A settings modal for teachers to **add or remove** courses, branches, sections, and years from the dropdown options used in task creation and filtering.

### `tasks/SubmissionsDrawer.tsx`
A slide-in side drawer (used by teachers) that lists all student submissions for a selected task. Shows student name, submission time, status (pending/approved/rejected), and the submitted code.

### `tasks/TaskDetailsModal.tsx`
A read-only modal that shows full task details including description, deadline, and starter code.

### `projects/ProjectCard.tsx`
A card for each project in the library. Shows thumbnail, title, difficulty badge, category, tech stack tags, estimated time, and Preview/Details buttons.

### `projects/ProjectDetailsModal.tsx`
A modal with full project information: description, features list, tech stack, and an "Open in Workspace" button.

### `projects/ProjectPreviewModal.tsx`
A modal that renders the project's HTML/CSS/JS template in a live `<iframe>` preview.

### `ui/` *(shadcn/ui primitives)*
All base UI components — Button, Card, Input, Select, Dialog, Drawer, Tabs, Toast, Avatar, Badge, Tooltip, Dropdown, etc. These are from the [shadcn/ui](https://ui.shadcn.com/) library built on top of Radix UI primitives.

---

## 🔌 `src/contexts/` — React Context Providers

### `auth-provider.tsx`
Manages the global authentication state.

| Export | Description |
|---|---|
| `AuthProvider` | Wraps the app, manages `user` state |
| `useAuth()` | Hook to access `user`, `login()`, `logout()` |

- On mount, restores session from `sessionStorage`
- `login(email, role)` — finds the matching mock user and stores them
- `logout()` — clears the session and redirects to `/login`

### `theme-provider.tsx`
Manages the `light` / `dark` / `system` theme toggle.

| Export | Description |
|---|---|
| `ThemeProvider` | Wraps the app, applies the theme class to `<html>` |
| `useTheme()` | Hook to access `theme` and `setTheme()` |

---

## 🪝 `src/hooks/` — Custom Hooks

### `use-toast.ts`
A complete toast notification system. Manages a queue of toast messages with auto-dismiss. Used via `useToast()` hook — call `toast({ title, description, variant })` anywhere in the app.

### `use-mobile.tsx`
Returns `true` if the viewport width is less than `768px`. Used in the workspace to adapt the layout for mobile screens.

---

## 📚 `src/lib/` — Utilities & Data

### `types.ts`
All TypeScript type definitions used across the app:

| Type | Description |
|---|---|
| `User` | id, name, email, role (teacher/student), section, avatarUrl |
| `Task` | id, title, description, course, branch, section, year, deadline, starterCode |
| `Submission` | id, taskId, studentId, code, status (pending/approved/rejected) |
| `Project` | id, title, category, difficulty, features, techStack, htmlTemplate, cssTemplate, jsTemplate |
| `Notification` | id, userId, message, type |
| `LearnContent` | day, category, title, theory, codeExample, task |
| `AcademicOptions` | courses[], branches[], sections[], years[] |

### `mock-data.ts`
All the app's data lives here (no backend). Contains:
- `mockUsers` — 2 demo users (1 teacher, 1 student)
- `mockTasks` — Sample coding assignments
- `mockSubmissions` — Sample student code submissions
- `mockProjects` — Pre-built project templates with full HTML/CSS/JS code
- `mockAcademicOptions` — Default courses, branches, sections, years
- `mockNotifications` — Sample notification messages

### `learn-content.ts`
A 30-day coding curriculum. Each entry contains:
- `day` number
- `category` (HTML / CSS / JavaScript)
- `title` of the lesson
- `theory` — markdown text explanation
- `codeExample` — sample code to study
- `task` — a mini exercise to complete

### `utils.ts`
Exports a single `cn()` utility that merges Tailwind CSS class names intelligently using `clsx` and `tailwind-merge`.

### `placeholder-images.ts` / `placeholder-images.json`
Helpers for generating placeholder image URLs from `picsum.photos` for project thumbnails.

---

## 🔄 Application Flow

```
User visits app
    │
    ▼
/login  ──── select role (Teacher / Student)
    │         enter credentials → login()
    │
    ▼
sessionStorage stores user
    │
    ▼
Redirect to /tasks
    │
    ├── /tasks        → View/manage coding tasks
    ├── /learn        → Study 30-day curriculum
    ├── /projects     → Browse project library
    ├── /workspace    → Write, preview, submit code
    └── /profile      → View account info
```

---

## 👤 Demo Credentials

> Since this is a mock app, credentials are pre-set. Use any email format — the role tab determines who you log in as.

| Role | Email | Password |
|---|---|---|
| **Student** | `student@codesnap.com` | *(any)* |
| **Teacher** | `teacher@codesnap.com` | *(any)* |

---

## 🛠️ Getting Started

### Prerequisites
- Node.js 18+
- npm

### Installation

```bash
# Clone the repository
git clone https://github.com/viswanvieperlvvdsleo-arch/codesnap.git
cd codesnap

# Install dependencies
npm install

# Start development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Build for Production

```bash
npm run build
npm run start
```

---

## 📸 Key Pages & Their Output

| Page | URL | Output |
|---|---|---|
| **Login** | `/login` | Animated login card with role selector |
| **Tasks** | `/tasks` | Grid of task cards with search & filters |
| **Learn** | `/learn` | 30-day curriculum with theory + code |
| **Projects** | `/projects` | Filterable project library with live preview |
| **Workspace** | `/workspace` | Monaco editor + live HTML preview + console |
| **Profile** | `/profile` | User account information |

---

## 📜 License

This project is private and for educational demonstration purposes.
