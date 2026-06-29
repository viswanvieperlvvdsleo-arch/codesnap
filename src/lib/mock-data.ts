import type { User, Task, AcademicOptions, Project, Notification, Submission } from './types';

export const mockUsers: User[] = [
  { id: '1', name: 'Dr. Evelyn Reed', email: 'teacher@codesnap.com', role: 'teacher', avatarUrl: 'https://picsum.photos/seed/user1/100/100' },
  { id: '2', name: 'Alex Johnson', email: 'student@codesnap.com', role: 'student', section: 'A', avatarUrl: 'https://picsum.photos/seed/user2/100/100' },
  { id: '3', name: 'Ben Carter', email: 'student2@codesnap.com', role: 'student', section: 'B', avatarUrl: 'https://picsum.photos/seed/user3/100/100' },
];

export const mockTasks: Task[] = [
  {
    id: 'task-1',
    title: 'HTML Basics: Create a Personal Portfolio',
    description: 'Create a single-page portfolio using fundamental HTML tags like h1, p, img, and a. Make sure to include a profile picture, a short bio, and links to your social media.',
    course: 'Web Development',
    branch: 'Computer Science',
    section: 'A',
    year: '1',
    deadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    createdAt: new Date().toISOString(),
    ownerId: '1',
    submissionCount: 23,
    starterCode: `<!DOCTYPE html>
<html>
<head>
  <title>Your Name - Portfolio</title>
</head>
<body>
  <!-- Your code goes here -->
</body>
</html>`,
  },
  {
    id: 'task-2',
    title: 'CSS Styling: Style Your Portfolio',
    description: 'Use CSS to style your personal portfolio. Focus on selectors, box model, and basic layout properties. Try to use a color scheme and make it visually appealing.',
    course: 'Web Development',
    branch: 'Computer Science',
    section: 'A',
    year: '1',
    deadline: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(),
    createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
    ownerId: '1',
    submissionCount: 18,
    starterCode: `<style>
  body {
    font-family: sans-serif;
  }
</style>`,
  },
    {
    id: 'task-3',
    title: 'Advanced HTML Forms',
    description: 'Build a complex registration form with various input types (text, email, password, date, radio, checkbox) and validation attributes. The form should be for a fictional event registration.',
    course: 'Web Development',
    branch: 'Information Technology',
    section: 'B',
    year: '2',
    deadline: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
    createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
    ownerId: '1',
    submissionCount: 30,
  },
];

export const mockProjects: Project[] = [
  {
    id: "proj-1",
    title: "E-Commerce Store UI",
    category: "E-Commerce",
    difficulty: "Advanced",
    description: "A responsive product listing page with a sidebar for filtering and a main content area for product cards, including a functional cart counter.",
    features: ["Responsive product grid", "Sidebar with filters", "Add to cart functionality (UI only)", "Dynamic cart count in header"],
    techStack: ["HTML", "CSS", "JS"],
    estimatedTime: "12 Hours",
    thumbnailUrl: "https://picsum.photos/seed/ecom/600/400",
    htmlTemplate: `
<header class="header">
  <h2>MyStore</h2>
  <div class="cart">Cart: <span id="cart-count">0</span></div>
</header>
<main class="container">
  <aside class="sidebar">
    <h3>Filters</h3>
    <p>Category 1</p>
    <p>Category 2</p>
  </aside>
  <section id="product-grid" class="product-grid">
    <!-- Product cards will be inserted here by JS -->
  </section>
</main>
    `,
    cssTemplate: `
body { font-family: sans-serif; margin: 0; background: #f4f4f4; }
.header { display: flex; justify-content: space-between; align-items: center; padding: 1rem 2rem; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
.container { display: flex; padding: 2rem; }
.sidebar { flex-basis: 20%; padding-right: 2rem; }
.product-grid { flex-basis: 80%; display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 1.5rem; }
.product-card { border: 1px solid #ddd; border-radius: 8px; background: white; padding: 1rem; text-align: center; }
.product-card img { max-width: 100%; height: 200px; object-fit: cover; border-radius: 4px; }
.product-card button { background: #007bff; color: white; border: none; padding: 0.5rem 1rem; border-radius: 4px; cursor: pointer; margin-top: 1rem; }
    `,
    jsTemplate: `
const products = [
  { id: 1, name: "Stylish Watch", price: 150, image: "https://picsum.photos/seed/p1/400/400" },
  { id: 2, name: "Leather Bag", price: 200, image: "https://picsum.photos/seed/p2/400/400" },
  { id: 3, name: "Running Shoes", price: 120, image: "https://picsum.photos/seed/p3/400/400" },
  { id: 4, name: "Sunglasses", price: 80, image: "https://picsum.photos/seed/p4/400/400" },
];
const grid = document.getElementById('product-grid');
let cartCount = 0;
const cartCountEl = document.getElementById('cart-count');

products.forEach(product => {
  const card = document.createElement('div');
  card.className = 'product-card';
  card.innerHTML = \`
    <img src="\${product.image}" alt="\${product.name}">
    <h3>\${product.name}</h3>
    <p>$\${product.price}</p>
    <button class="add-to-cart" data-id="\${product.id}">Add to Cart</button>
  \`;
  grid.appendChild(card);
});

grid.addEventListener('click', (e) => {
  if (e.target.classList.contains('add-to-cart')) {
    cartCount++;
    cartCountEl.textContent = cartCount;
  }
});
    `,
  },
  {
    id: "proj-2",
    title: "Admin Dashboard Layout",
    category: "Dashboard",
    difficulty: "Advanced",
    description: "A classic admin dashboard layout with a collapsible sidebar, a header, and a main content area featuring stat cards and a data table.",
    features: ["Collapsible sidebar", "Data cards for stats", "Data table", "Responsive design"],
    techStack: ["HTML", "CSS", "JS"],
    estimatedTime: "10 Hours",
    thumbnailUrl: "https://picsum.photos/seed/dash/600/400",
    htmlTemplate: `
<div class="dashboard-container">
  <aside id="sidebar" class="sidebar">
    <div class="sidebar-header"><h2>Dashboard</h2></div>
    <nav>
      <a>Home</a>
      <a>Analytics</a>
      <a>Users</a>
      <a>Settings</a>
    </nav>
  </aside>
  <main class="main-content">
    <header class="header">
      <button id="toggle-sidebar">☰</button>
      <input type="text" placeholder="Search..." />
    </header>
    <section class="stats">
      <div class="stat-card">...</div>
      <div class="stat-card">...</div>
      <div class="stat-card">...</div>
    </section>
    <section class="data-table">
      <table>...</table>
    </section>
  </main>
</div>
`,
    cssTemplate: `
:root { --sidebar-width: 250px; }
body { margin: 0; font-family: sans-serif; background: #f0f2f5; }
.dashboard-container { display: flex; }
.sidebar { width: var(--sidebar-width); background: #1f2937; color: white; height: 100vh; transition: width 0.3s; }
.sidebar.collapsed { width: 0; }
.sidebar nav a { display: block; padding: 1rem; text-decoration: none; color: #d1d5db; }
.main-content { flex-grow: 1; display: flex; flex-direction: column; }
.header { background: white; padding: 1rem; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
.stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; padding: 1rem; }
.stat-card { background: white; padding: 1.5rem; border-radius: 8px; }
`,
    jsTemplate: `
const toggleBtn = document.getElementById('toggle-sidebar');
const sidebar = document.getElementById('sidebar');
toggleBtn.addEventListener('click', () => {
  sidebar.classList.toggle('collapsed');
});
`,
  },
  {
    id: "proj-3",
    title: "Social Media Feed UI",
    category: "Social Media",
    difficulty: "Intermediate",
    description: "A clean UI for a social media feed, including post cards with user info, images, and action buttons for like, comment, and share.",
    features: ["Dynamic post card generation", "Like button with counter", "Comment section placeholder"],
    techStack: ["HTML", "CSS", "JS"],
    estimatedTime: "6 Hours",
    thumbnailUrl: "https://picsum.photos/seed/social/600/400",
    htmlTemplate: `<div class="feed-container" id="feed"></div>`,
    cssTemplate: `
body { background: #e9ebee; font-family: sans-serif; }
.feed-container { max-width: 600px; margin: 2rem auto; }
.post-card { background: white; border-radius: 8px; margin-bottom: 1.5rem; border: 1px solid #dddfe2; }
.post-header { display: flex; align-items: center; padding: 12px 16px; }
.post-header img { width: 40px; height: 40px; border-radius: 50%; margin-right: 12px; }
.post-body img { width: 100%; max-height: 600px; object-fit: cover; }
.post-actions { padding: 8px 16px; display: flex; gap: 16px; }
.action-btn { background: none; border: none; cursor: pointer; font-size: 1.5rem; }
.action-btn.liked { color: #ed4956; }
`,
    jsTemplate: `
const posts = [
  { user: 'User1', avatar: 'https://picsum.photos/seed/u1/50', image: 'https://picsum.photos/seed/post1/600' },
  { user: 'User2', avatar: 'https://picsum.photos/seed/u2/50', image: 'https://picsum.photos/seed/post2/600' }
];
const feed = document.getElementById('feed');
posts.forEach(post => {
  feed.innerHTML += \`
    <div class="post-card">
      <div class="post-header">
        <img src="\${post.avatar}" />
        <span>\${post.user}</span>
      </div>
      <div class="post-body"><img src="\${post.image}" /></div>
      <div class="post-actions">
        <button class="action-btn like-btn">♡</button>
        <button class="action-btn">💬</button>
      </div>
    </div>
  \`;
});
feed.addEventListener('click', e => {
  if (e.target.classList.contains('like-btn')) {
    e.target.classList.toggle('liked');
    e.target.textContent = e.target.classList.contains('liked') ? '♥' : '♡';
  }
})
`,
  },
  {
    id: "proj-7",
    title: "Portfolio Website",
    category: "Portfolio",
    difficulty: "Beginner",
    description: "A classic, clean, and responsive personal portfolio website template. Includes a hero section, project gallery, and a contact form.",
    features: ["Responsive layout", "Hero section", "Project gallery grid", "Contact form UI"],
    techStack: ["HTML", "CSS", "JS"],
    estimatedTime: "5 Hours",
    thumbnailUrl: "https://picsum.photos/seed/port/600/400",
    htmlTemplate: `
<header>
    <nav>
        <h1>My Portfolio</h1>
        <ul>
            <li><a href="#about">About</a></li>
            <li><a href="#projects">Projects</a></li>
            <li><a href="#contact">Contact</a></li>
        </ul>
    </nav>
</header>
<section id="hero">
    <h2>Welcome! I'm a Web Developer.</h2>
</section>
<section id="projects">
    <h3>My Projects</h3>
    <div class="gallery">
        <div class="project-item">Project 1</div>
        <div class="project-item">Project 2</div>
    </div>
</section>
<section id="contact">
    <h3>Contact Me</h3>
    <form></form>
</section>
<footer><p>&copy; 2024</p></footer>`,
    cssTemplate: `
body { font-family: system-ui, sans-serif; line-height: 1.6; margin: 0; }
header, footer { background: #333; color: white; text-align: center; padding: 1rem 0; }
nav { display: flex; justify-content: space-around; align-items: center; }
nav ul { list-style: none; display: flex; gap: 1rem; }
nav a { color: white; text-decoration: none; }
#hero { min-height: 400px; display: grid; place-content: center; background: #555; color: white; }
section { padding: 4rem 2rem; }
.gallery { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
.project-item { border: 1px solid #ccc; padding: 2rem; }
`,
    jsTemplate: `
// Smooth scrolling for navigation links
document.querySelectorAll('nav a').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        document.querySelector(this.getAttribute('href')).scrollIntoView({
            behavior: 'smooth'
        });
    });
});
`,
  },
  {
    id: "proj-8",
    title: "To-Do Productivity App",
    category: "Productivity Tools",
    difficulty: "Beginner",
    description: "A classic To-Do list application that allows users to add, delete, and mark tasks as complete. Data persists in the browser using Local Storage.",
    features: ["Add tasks", "Delete tasks", "Mark tasks as complete", "Data saved in Local Storage"],
    techStack: ["HTML", "CSS", "JS"],
    estimatedTime: "3 Hours",
    thumbnailUrl: "https://picsum.photos/seed/todo/600/400",
    htmlTemplate: `
<div class="todo-app">
    <h1>My To-Do List</h1>
    <div class="input-section">
        <input type="text" id="todo-input" placeholder="Add a new task...">
        <button id="add-task-btn">Add</button>
    </div>
    <ul id="todo-list"></ul>
</div>
`,
    cssTemplate: `
.todo-app { max-width: 500px; margin: 2rem auto; background: white; padding: 2rem; border-radius: 8px; }
#todo-list { list-style: none; padding: 0; }
#todo-list li { padding: 0.8rem; border-bottom: 1px solid #eee; display: flex; justify-content: space-between; align-items: center; }
#todo-list li.completed { text-decoration: line-through; color: #aaa; }
.delete-btn { background: #ff4d4d; color: white; border: none; padding: 5px 8px; border-radius: 4px; cursor: pointer; }
`,
    jsTemplate: `
const input = document.getElementById('todo-input');
const addBtn = document.getElementById('add-task-btn');
const list = document.getElementById('todo-list');
let todos = JSON.parse(localStorage.getItem('todos')) || [];

function renderTodos() {
    list.innerHTML = '';
    todos.forEach((todo, index) => {
        const li = document.createElement('li');
        li.textContent = todo.text;
        if (todo.completed) li.classList.add('completed');
        li.addEventListener('click', () => toggleComplete(index));
        
        const delBtn = document.createElement('button');
        delBtn.textContent = 'Delete';
        delBtn.className = 'delete-btn';
        delBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            deleteTodo(index);
        });
        
        li.appendChild(delBtn);
        list.appendChild(li);
    });
}

function addTodo() {
    if (input.value.trim() === '') return;
    todos.push({ text: input.value, completed: false });
    input.value = '';
    saveAndRender();
}

function deleteTodo(index) {
    todos.splice(index, 1);
    saveAndRender();
}

function toggleComplete(index) {
    todos[index].completed = !todos[index].completed;
    saveAndRender();
}

function saveAndRender() {
    localStorage.setItem('todos', JSON.stringify(todos));
    renderTodos();
}

addBtn.addEventListener('click', addTodo);
renderTodos();
`,
  },
  {
    id: "proj-4",
    title: "Online Exam Portal",
    category: "Education",
    difficulty: "Advanced",
    description: "A functional online exam UI with multiple-choice questions, a countdown timer, and a final score calculation screen.",
    features: ["MCQ questions", "Countdown timer", "Automatic scoring", "Show correct/incorrect answers"],
    techStack: ["HTML", "CSS", "JS"],
    estimatedTime: "9 Hours",
    thumbnailUrl: "https://picsum.photos/seed/exam/600/400",
    htmlTemplate: `...`,
    cssTemplate: `...`,
    jsTemplate: `...`,
  },
  {
    id: "proj-5",
    title: "Restaurant Booking System",
    category: "Restaurant & Booking",
    difficulty: "Intermediate",
    description: "A frontend for a restaurant booking system, including a reservation form with date and time pickers and a menu display page.",
    features: ["Date and time selection", "Form validation", "Responsive menu page"],
    techStack: ["HTML", "CSS", "JS"],
    estimatedTime: "7 Hours",
    thumbnailUrl: "https://picsum.photos/seed/resto/600/400",
    htmlTemplate: `...`,
    cssTemplate: `...`,
    jsTemplate: `...`,
  },
  {
    id: "proj-6",
    title: "Multi-Step Form Application",
    category: "Forms & Authentication",
    difficulty: "Intermediate",
    description: "A multi-step form with a progress bar, validation for each step, and navigation between steps.",
    features: ["Step-by-step progression", "Progress indicator", "Per-step validation", "Summary screen"],
    techStack: ["HTML", "CSS", "JS"],
    estimatedTime: "6 Hours",
    thumbnailUrl: "https://picsum.photos/seed/form/600/400",
    htmlTemplate: `...`,
    cssTemplate: `...`,
    jsTemplate: `...`,
  },
  {
    id: "proj-9",
    title: "Blog CMS Frontend",
    category: "Dashboard",
    difficulty: "Advanced",
    description: "The frontend UI for a blog content management system. Features include a post listing with statuses, a rich text editor placeholder, and category filtering.",
    features: ["Post list with status badges", "Rich text editor area", "Category and tag management UI", "Client-side filtering"],
    techStack: ["HTML", "CSS", "JS"],
    estimatedTime: "11 Hours",
    thumbnailUrl: "https://picsum.photos/seed/blogcms/600/400",
    htmlTemplate: `...`,
    cssTemplate: `...`,
    jsTemplate: `...`,
  },
  {
    id: "proj-10",
    title: "Chat Interface UI",
    category: "Social Media",
    difficulty: "Intermediate",
    description: "A responsive chat application UI with a contact list, message area, and a message input form. Includes layouts for sent and received messages.",
    features: ["Two-column chat layout", "Styled message bubbles", "Contact list with statuses", "Responsive design"],
    techStack: ["HTML", "CSS", "JS"],
    estimatedTime: "6 Hours",
    thumbnailUrl: "https://picsum.photos/seed/chat/600/400",
    htmlTemplate: `...`,
    cssTemplate: `...`,
    jsTemplate: `...`,
  }
].map(p => {
  // Fill in empty templates for brevity in this example
  if (p.htmlTemplate === '...') {
    p.htmlTemplate = `<h1>${p.title}</h1><p>Code placeholder for ${p.title}</p>`;
    p.cssTemplate = `body { font-family: sans-serif; display: grid; place-content: center; height: 100vh; text-align: center; }`;
    p.jsTemplate = `console.log("Hello from ${p.title}");`;
  }
  return p;
});


export const mockAcademicOptions: AcademicOptions = {
  courses: ['Web Development', 'Data Structures', 'Algorithms', 'Database Management'],
  branches: ['Computer Science', 'Information Technology', 'Electronics'],
  sections: ['A', 'B', 'C', 'D'],
  years: ['1', '2', '3', '4'],
};

export const mockNotifications: Notification[] = [
    { id: 'notif-1', userId: '1', message: 'Alex Johnson submitted a task: HTML Basics.', createdAt: new Date().toISOString(), read: false, type: 'submission' },
    { id: 'notif-2', userId: '2', message: 'Your task "CSS Styling" has been approved.', createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(), read: true, type: 'approval' },
];

export const mockSubmissions: Submission[] = [
    { id: 'sub-1', taskId: 'task-1', studentId: '2', studentName: 'Alex Johnson', code: '<h1>My Portfolio</h1>', submittedAt: new Date().toISOString(), status: 'pending', versionCount: 1 },
    { id: 'sub-2', taskId: 'task-1', studentId: '3', studentName: 'Ben Carter', code: '<h1>BC Portfolio</h1>', submittedAt: new Date(Date.now() - 60*60*1000).toISOString(), status: 'approved', versionCount: 2 },
    { id: 'sub-3', taskId: 'task-2', studentId: '2', studentName: 'Alex Johnson', code: '<style>body { background: #eee; }</style>', submittedAt: new Date(Date.now() - 2*60*60*1000).toISOString(), status: 'rejected', versionCount: 3 },
    { id: 'sub-4', taskId: 'task-3', studentId: '3', studentName: 'Ben Carter', code: '<form>...</form>', submittedAt: new Date(Date.now() - 3*60*60*1000).toISOString(), status: 'pending', versionCount: 1 },
];
