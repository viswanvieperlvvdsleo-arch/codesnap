import '../models/user.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../models/learn_content.dart';
import '../models/user_profile.dart';

class MockData {
  static final User defaultUser = User(
    id: 'user-1',
    name: 'Alex Johnson',
    email: 'user@codesnap.com',
    section: 'A',
    avatarUrl: 'https://picsum.photos/seed/user2/100/100',
  );

  static final List<User> mockUsers = [
    defaultUser,
    User(
      id: 'user-2',
      name: 'Sarah Miller',
      email: 'sarah@codesnap.com',
      section: 'B',
      avatarUrl: 'https://picsum.photos/seed/user3/100/100',
    ),
  ];

  static final List<String> courses = [
    'Web Development',
    'Data Structures',
    'Algorithms',
    'Database Management'
  ];
  static final List<String> branches = [
    'Computer Science',
    'Information Technology',
    'Electronics'
  ];
  static final List<String> sections = ['A', 'B', 'C', 'D'];
  static final List<String> years = ['1', '2', '3', '4'];

  static final List<Task> mockTasks = [
    Task(
      id: 'task-1',
      title: 'Global AI Agents & Mobile IDE Hackathon 2026',
      description: 'Build revolutionary mobile-first developer tools where budget phones orchestrate cloud AI agents, remote builds, and live debugging with zero latency.',
      course: 'AI & Agents',
      branch: 'Mobile / Flutter',
      section: 'A',
      year: '2026',
      deadline: DateTime.now().add(const Duration(days: 4, hours: 14)).toIso8601String(),
      createdAt: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      ownerId: 'bug-foundation',
      submissionCount: 38,
      prizePool: '₹50,000',
      eventType: 'Hackathon',
      status: 'LIVE',
      tags: ['AI Agents', 'Flutter', 'Cloud Sandbox', 'Open Source'],
      teamsCount: 38,
      totalVotes: 1840,
      teams: [
        TeamShowdown(
          id: 'team-1',
          teamName: 'NeuroCoder',
          projectTitle: 'Gemini Agentic Mobile Runner',
          growthUpdate: 'Just deployed remote WebSockets runner with 45ms latency and live auto-test fixing!',
          votes: 980,
          memberAvatars: [
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&q=80',
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80',
          ],
        ),
        TeamShowdown(
          id: 'team-2',
          teamName: 'CloudSnap Prime',
          projectTitle: 'Zero-Battery Remote Compiler Sandbox',
          growthUpdate: 'Integrated ephemeral Docker containers on Modal. 0% phone battery drain while building Flutter web!',
          votes: 860,
          memberAvatars: [
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&q=80',
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&q=80',
          ],
        ),
      ],
      starterCode: '''<!DOCTYPE html>
<html>
<head>
  <title>AI Agent Mobile IDE</title>
  <style>
    body { background: #09090b; color: #fff; font-family: monospace; padding: 20px; }
    .terminal { background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.15); border-radius: 12px; padding: 16px; }
    .badge { color: #54c5f8; font-weight: bold; }
  </style>
</head>
<body>
  <h2>🚀 AI Mobile Runner Sandbox</h2>
  <div class="terminal">
    <p><span class="badge">[AI-AGENT]</span> Initializing cloud container...</p>
    <p><span class="badge">[DOCKER]</span> Container ready. Zero local CPU usage.</p>
  </div>
</body>
</html>''',
    ),
    Task(
      id: 'task-2',
      title: 'Mobile Cloud Terminal & WebAssembly Bounty',
      description: 'Implement an ultra-responsive WebAssembly terminal client that executes code directly in a sandboxed view without charging host compute bills.',
      course: 'Systems',
      branch: 'WebAssembly',
      section: 'B',
      year: '2026',
      deadline: DateTime.now().add(const Duration(days: 2, hours: 8)).toIso8601String(),
      createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      ownerId: 'sponsor-wasm',
      submissionCount: 19,
      prizePool: '₹25,000',
      eventType: 'Bounty',
      status: 'LIVE',
      tags: ['WASM', 'Terminal', 'Python', 'FastAPI'],
      teamsCount: 19,
      totalVotes: 940,
      teams: [
        TeamShowdown(
          id: 'team-3',
          teamName: 'PyWasm Core',
          projectTitle: 'In-Browser Python REPL',
          growthUpdate: 'Compiled Pyodide with NumPy support. Runs 100% offline inside mobile WebView!',
          votes: 520,
          memberAvatars: [
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&q=80',
          ],
        ),
        TeamShowdown(
          id: 'team-4',
          teamName: 'TermiZen',
          projectTitle: 'ANSI PTY Streamer',
          growthUpdate: 'Full 256-color support with spring scroll and keyboard shortcuts for mobile coding.',
          votes: 420,
          memberAvatars: [
            'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100&q=80',
          ],
        ),
      ],
      starterCode: '''<style>
  body { font-family: monospace; background-color: #0d1117; color: #58a6ff; padding: 20px; }
  .prompt { color: #7ee787; }
</style>
<h3>WebAssembly Terminal v1.0</h3>
<p><span class="prompt">guest@wasm-sandbox:~\$</span> python3 --version</p>
<p>Python 3.11.2 (WASM Micro-Engine)</p>''',
    ),
    Task(
      id: 'task-3',
      title: 'Liquid Glass UI / UX Design Arena',
      description: 'Design and implement the ultimate dark-mode liquid frosted glass UI elements with spring physics, neon borders, and zero frame drops on 60/120Hz displays.',
      course: 'UI / UX',
      branch: 'Design Engineering',
      section: 'A',
      year: '2026',
      deadline: DateTime.now().add(const Duration(hours: 36)).toIso8601String(),
      createdAt: DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
      ownerId: 'design-collective',
      submissionCount: 24,
      prizePool: '₹15,000',
      eventType: 'Challenge',
      status: 'VOTING',
      tags: ['Flutter', 'Glassmorphism', 'Design', 'Animations'],
      teamsCount: 24,
      totalVotes: 2310,
      teams: [
        TeamShowdown(
          id: 'team-5',
          teamName: 'AeroGlass',
          projectTitle: 'Dynamic Blur with Physics Gestures',
          growthUpdate: 'Achieved locked 120 FPS on Snapdragon 680 with custom backdrop filter caching.',
          votes: 1240,
          memberAvatars: [
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100&q=80',
            'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=100&q=80',
          ],
        ),
        TeamShowdown(
          id: 'team-6',
          teamName: 'PrismUI',
          projectTitle: 'Hyper-Realistic Frosted Glass',
          growthUpdate: 'Added chromatic refraction edges and liquid highlights for dark mode themes.',
          votes: 1070,
          memberAvatars: [
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&q=80',
          ],
        ),
      ],
      starterCode: '''<!DOCTYPE html>
<html>
<head>
  <style>
    body { background: #000; color: #fff; display: flex; justify-content: center; align-items: center; height: 100vh; font-family: sans-serif; }
    .glass-card { background: rgba(255, 255, 255, 0.08); backdrop-filter: blur(20px); border: 1px solid rgba(255, 255, 255, 0.18); border-radius: 20px; padding: 30px; box-shadow: 0 8px 32px rgba(0,0,0,0.37); }
  </style>
</head>
<body>
  <div class="glass-card">
    <h2>Liquid Glass Element</h2>
    <p>Spring-animated responsive card design.</p>
  </div>
</body>
</html>''',
    ),
    Task(
      id: 'task-4',
      title: 'Autonomous Bug Hunter & Git Watcher',
      description: 'Create an autonomous AI daemon that monitors project commits, catches compile bugs, generates tests, and submits pull requests without developer intervention.',
      course: 'AI & Agents',
      branch: 'DevOps',
      section: 'C',
      year: '2026',
      deadline: DateTime.now().add(const Duration(days: 10)).toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
      ownerId: 'dev-foundation',
      submissionCount: 14,
      prizePool: '₹35,000',
      eventType: 'Hackathon',
      status: 'UPCOMING',
      tags: ['LLMs', 'Git Hooks', 'CI/CD', 'Security'],
      teamsCount: 14,
      totalVotes: 480,
      teams: [
        TeamShowdown(
          id: 'team-7',
          teamName: 'Sentinel AI',
          projectTitle: 'Autonomous PR Reviewer Bot',
          growthUpdate: 'Architecture plan finalized. Integrating GitHub Webhooks + Gemini 1.5 Flash.',
          votes: 260,
          memberAvatars: [
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100&q=80',
          ],
        ),
        TeamShowdown(
          id: 'team-8',
          teamName: 'BugSlayer',
          projectTitle: 'Real-time AST Code Analyzer',
          growthUpdate: 'Building tree-sitter bindings for Dart and Python.',
          votes: 220,
          memberAvatars: [
            'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=100&q=80',
          ],
        ),
      ],
      starterCode: '''// Bug Hunter Starter Code
function analyzeDiff(gitPatch) {
  console.log("Scanning patch for runtime exceptions...");
  return { issuesFound: 0, status: "Clean" };
}
console.log(analyzeDiff("diff --git a/app.dart b/app.dart"));''',
    ),
    Task(
      id: 'task-5',
      title: 'Peer-to-Peer Micro-Bounty Escrow',
      description: 'Build a trustless peer-to-peer bounty escrow where builders and creators lock in milestones and automatically release prize pools upon community consensus.',
      course: 'Web3 & Security',
      branch: 'Fullstack',
      section: 'A',
      year: '2026',
      deadline: DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      ownerId: 'crypto-dao',
      submissionCount: 16,
      prizePool: '₹20,000',
      eventType: 'Bounty',
      status: 'LIVE',
      tags: ['Escrow', 'Smart Contracts', 'Solidity', 'P2P'],
      teamsCount: 16,
      totalVotes: 780,
      teams: [
        TeamShowdown(
          id: 'team-9',
          teamName: 'EscrowDAO',
          projectTitle: 'Milestone Multi-Sig Escrow',
          growthUpdate: 'Tested automated release triggers based on verified GitHub pull requests.',
          votes: 430,
          memberAvatars: [
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&q=80',
          ],
        ),
        TeamShowdown(
          id: 'team-10',
          teamName: 'CodePledge',
          projectTitle: 'ZK Contribution Verification',
          growthUpdate: 'Prototyped cryptographic proofs of test suite passage.',
          votes: 350,
          memberAvatars: [
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&q=80',
          ],
        ),
      ],
      starterCode: '''// Trustless Bounty Escrow
contract BountyEscrow {
    address public sponsor;
    uint256 public prizeAmount = 20000;
    bool public isReleased = false;

    function releaseReward(address winner) public {
        isReleased = true;
    }
}''',
    ),
  ];

  static final List<Project> mockProjects = [
    // 1. E-Commerce Store UI
    Project(
      id: "proj-1",
      title: "E-Commerce Store UI",
      category: "E-Commerce",
      difficulty: "Advanced",
      description: "A responsive product listing page with a sidebar for filtering and a main content area for product cards, including a functional cart counter and cart management.",
      features: [
        "Responsive product grid",
        "Sidebar with category filters",
        "Add to cart functionality & quantity counter",
        "Dynamic cart drawer with checkout calculation"
      ],
      techStack: ["HTML", "CSS", "JS"],
      estimatedTime: "12 Hours",
      thumbnailUrl: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80",
      isFeatured: true,
      htmlTemplate: '''<header class="header">
  <h2>MyStore</h2>
  <div class="cart">Cart: <span id="cart-count">0</span></div>
</header>
<main class="container">
  <aside class="sidebar">
    <h3>Filters</h3>
    <p>Electronics</p>
    <p>Accessories</p>
    <p>Footwear</p>
  </aside>
  <section id="product-grid" class="product-grid">
    <!-- Product cards populated by JS -->
  </section>
</main>''',
      cssTemplate: '''body { font-family: system-ui, sans-serif; margin: 0; background: #09090b; color: #fff; }
.header { display: flex; justify-content: space-between; align-items: center; padding: 1.2rem 2.5rem; background: rgba(255,255,255,0.05); border-bottom: 1px solid rgba(255,255,255,0.1); backdrop-filter: blur(20px); }
.container { display: flex; padding: 2rem; gap: 2rem; }
.sidebar { flex: 0 0 220px; background: rgba(255,255,255,0.03); padding: 1.5rem; border-radius: 16px; border: 1px solid rgba(255,255,255,0.08); }
.product-grid { flex: 1; display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 1.5rem; }
.product-card { border: 1px solid rgba(255,255,255,0.12); border-radius: 16px; background: rgba(255,255,255,0.05); padding: 1.2rem; text-align: center; backdrop-filter: blur(12px); }
.product-card img { width: 100%; height: 180px; object-fit: cover; border-radius: 12px; }
.product-card button { background: #54c5f8; color: #000; font-weight: bold; border: none; padding: 0.6rem 1.2rem; border-radius: 10px; cursor: pointer; margin-top: 1rem; }''',
      jsTemplate: '''const products = [
  { id: 1, name: "Mechanical Keyboard", price: 129, image: "https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=400&q=80" },
  { id: 2, name: "Wireless Headphones", price: 199, image: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&q=80" },
  { id: 3, name: "Minimalist Watch", price: 149, image: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80" },
];
const grid = document.getElementById('product-grid');
let cartCount = 0;
const cartCountEl = document.getElementById('cart-count');

products.forEach(p => {
  const card = document.createElement('div');
  card.className = 'product-card';
  card.innerHTML = `
    <img src="\${p.image}" alt="\${p.name}">
    <h3>\${p.name}</h3>
    <p>\$\${p.price}</p>
    <button onclick="cartCount++; cartCountEl.innerText = cartCount;">Add to Cart</button>
  `;
  grid.appendChild(card);
});''',
    ),

    // 2. Admin Dashboard Layout
    Project(
      id: "proj-2",
      title: "Admin Dashboard Layout",
      category: "Dashboard",
      difficulty: "Advanced",
      description: "A classic admin dashboard layout with a collapsible sidebar, a header, and a main content area featuring stat cardes and a data table.",
      features: [
        "Collapsible sidebar with icon menu",
        "Metric cards for revenue, users, and churn",
        "Interactive responsive data table",
        "Dark glass navigation header"
      ],
      techStack: ["HTML", "CSS", "JS"],
      estimatedTime: "10 Hours",
      thumbnailUrl: "https://images.unsplash.com/photo-1516483638261-f4dbaf036963?w=800&q=80",
      htmlTemplate: '''<div class="dashboard">
  <aside class="sidebar">
    <div class="logo">⚡ AdminPro</div>
    <nav>
      <a class="active">Overview</a>
      <a>Analytics</a>
      <a>Customers</a>
      <a>Settings</a>
    </nav>
  </aside>
  <main class="content">
    <header class="topbar">
      <h2>Platform Performance</h2>
    </header>
    <div class="metrics">
      <div class="card"><h3>Users</h3><p>24,892</p></div>
      <div class="card"><h3>Revenue</h3><p>\$89,200</p></div>
      <div class="card"><h3>Uptime</h3><p>99.98%</p></div>
    </div>
  </main>
</div>''',
      cssTemplate: '''body { margin: 0; font-family: system-ui, sans-serif; background: #09090b; color: #fff; }
.dashboard { display: flex; min-height: 100vh; }
.sidebar { width: 240px; background: rgba(255,255,255,0.03); border-right: 1px solid rgba(255,255,255,0.08); padding: 1.5rem; }
.sidebar .logo { font-size: 1.25rem; font-weight: 800; margin-bottom: 2rem; color: #54c5f8; }
.sidebar nav a { display: block; padding: 0.75rem 1rem; color: rgba(255,255,255,0.6); text-decoration: none; border-radius: 8px; margin-bottom: 0.25rem; }
.sidebar nav a.active { background: rgba(255,255,255,0.1); color: #fff; font-weight: bold; }
.content { flex: 1; padding: 2rem; }
.metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1.5rem; margin-top: 1.5rem; }
.card { background: rgba(255,255,255,0.05); padding: 1.5rem; border-radius: 16px; border: 1px solid rgba(255,255,255,0.08); }
.card p { font-size: 1.8rem; font-weight: bold; color: #54c5f8; margin: 0.5rem 0 0; }''',
      jsTemplate: '''console.log("Admin Dashboard Loaded.");''',
    ),

    // 3. To-Do Productivity App
    Project(
      id: "proj-3",
      title: "To-Do Productivity App",
      category: "Productivity Tools",
      difficulty: "Beginner",
      description: "A classic To-Do list application that allows users to add, delete, and mark tasks as complete. Data persists in the browser using Local Storage.",
      features: [
        "Create & complete tasks with spring checkboxes",
        "Persistent localStorage sync",
        "Filter active and completed tasks",
        "Clean glass container UI"
      ],
      techStack: ["HTML", "CSS", "JS"],
      estimatedTime: "3 Hours",
      thumbnailUrl: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80",
      htmlTemplate: '''<div class="todo-container">
  <h1>Focus List</h1>
  <div class="input-row">
    <input type="text" id="task-input" placeholder="What needs to get done?">
    <button id="add-btn">Add</button>
  </div>
  <ul id="task-list"></ul>
</div>''',
      cssTemplate: '''body { margin: 0; min-height: 100vh; display: grid; place-content: center; background: #09090b; font-family: system-ui, sans-serif; color: #fff; }
.todo-container { width: 380px; background: rgba(255,255,255,0.05); padding: 2rem; border-radius: 20px; border: 1px solid rgba(255,255,255,0.12); backdrop-filter: blur(24px); }
.input-row { display: flex; gap: 0.5rem; margin-bottom: 1.5rem; }
input { flex: 1; padding: 0.75rem 1rem; background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.15); border-radius: 12px; color: #fff; }
button { padding: 0.75rem 1.25rem; background: #54c5f8; border: none; border-radius: 12px; font-weight: bold; cursor: pointer; }
ul { list-style: none; padding: 0; margin: 0; }
li { padding: 0.75rem 1rem; background: rgba(255,255,255,0.03); border-radius: 10px; margin-bottom: 0.5rem; display: flex; justify-content: space-between; align-items: center; border: 1px solid rgba(255,255,255,0.06); }''',
      jsTemplate: '''const input = document.getElementById('task-input');
const btn = document.getElementById('add-btn');
const list = document.getElementById('task-list');
btn.addEventListener('click', () => {
  if (!input.value.trim()) return;
  const li = document.createElement('li');
  li.innerHTML = `<span>\${input.value}</span><button style="padding:4px 8px; background:rgba(255,255,255,0.2); color:#fff;" onclick="this.parentElement.remove()">✕</button>`;
  list.appendChild(li);
  input.value = '';
});''',
    ),

    // 4. Weather App
    Project(
      id: "proj-4",
      title: "Weather App",
      category: "Education",
      difficulty: "Intermediate",
      description: "A simple weather application that fetches real-time data from an API and shows current weather, location and forecast.",
      features: [
        "Live temperature & atmospheric condition display",
        "5-day forecast horizontal slider",
        "Dynamic background mood matching current condition",
        "Search by city and automatic geolocation"
      ],
      techStack: ["HTML", "CSS", "JS"],
      estimatedTime: "8 Hours",
      thumbnailUrl: "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80",
      htmlTemplate: '''<div class="weather-card">
  <div class="location">Kyoto, Japan</div>
  <div class="temp">18°C</div>
  <div class="condition">Partly Cloudy</div>
  <div class="forecast">
    <div class="day"><span>Mon</span> 19°</div>
    <div class="day"><span>Tue</span> 21°</div>
    <div class="day"><span>Wed</span> 16°</div>
  </div>
</div>''',
      cssTemplate: '''body { margin: 0; min-height: 100vh; display: grid; place-content: center; background: #09090b; font-family: system-ui, sans-serif; color: #fff; }
.weather-card { width: 340px; background: rgba(255,255,255,0.06); padding: 2.5rem; border-radius: 24px; border: 1px solid rgba(255,255,255,0.15); backdrop-filter: blur(28px); text-align: center; }
.location { font-size: 1.25rem; font-weight: 700; color: rgba(255,255,255,0.8); }
.temp { font-size: 4rem; font-weight: 800; color: #54c5f8; margin: 1rem 0 0.5rem; }
.condition { font-size: 1rem; color: rgba(255,255,255,0.7); margin-bottom: 2rem; }
.forecast { display: flex; justify-content: space-around; border-top: 1px solid rgba(255,255,255,0.1); padding-top: 1.5rem; }
.day span { display: block; font-size: 0.8rem; color: rgba(255,255,255,0.5); }''',
      jsTemplate: '''console.log("Weather service active.");''',
    ),

    // 5. Portfolio Website
    Project(
      id: "proj-5",
      title: "Portfolio Website",
      category: "Portfolio",
      difficulty: "Intermediate",
      description: "A personal portfolio website with smooth scrolling, dark mode, animations and a clean modern design.",
      features: [
        "Hero section with typing effect & avatar glow",
        "Projects showcase with hover scale effect",
        "Experience timeline with milestone markers",
        "Responsive contact form"
      ],
      techStack: ["HTML", "CSS", "JS"],
      estimatedTime: "6 Hours",
      thumbnailUrl: "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80",
      htmlTemplate: '''<header class="hero">
  <div class="badge">Available for projects</div>
  <h1>Building Fluid Glass Experiences</h1>
  <p>Full-Stack Developer & Interface Architect.</p>
  <div class="actions">
    <a class="btn primary">View Work</a>
    <a class="btn glass">Contact Me</a>
  </div>
</header>''',
      cssTemplate: '''body { margin: 0; background: #09090b; font-family: system-ui, sans-serif; color: #fff; min-height: 100vh; display: grid; place-content: center; text-align: center; }
.badge { display: inline-block; padding: 6px 14px; background: rgba(84,197,248,0.15); border: 1px solid rgba(84,197,248,0.4); border-radius: 20px; font-size: 12px; color: #54c5f8; margin-bottom: 1.5rem; font-weight: bold; }
h1 { font-size: 3rem; font-weight: 800; letter-spacing: -1px; margin: 0 0 1rem; }
p { font-size: 1.25rem; color: rgba(255,255,255,0.7); max-width: 500px; margin: 0 auto 2rem; }
.actions { display: flex; gap: 1rem; justify-content: center; }
.btn { padding: 0.8rem 1.8rem; border-radius: 12px; font-weight: 700; text-decoration: none; cursor: pointer; }
.btn.primary { background: #54c5f8; color: #000; }
.btn.glass { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.2); color: #fff; }''',
      jsTemplate: '''console.log("Portfolio ready.");''',
    ),

    // 6. Blog Platform
    Project(
      id: "proj-6",
      title: "Blog Platform",
      category: "Social Media",
      difficulty: "Advanced",
      description: "A full-featured blog platform with authentication, post creation, comments and a clean reading experience.",
      features: [
        "Markdown post editor with real-time preview",
        "Reader comments with nested replies",
        "Author profiles with bio and social links",
        "Category tag indexing and full-text search"
      ],
      techStack: ["HTML", "CSS", "JS"],
      estimatedTime: "14 Hours",
      thumbnailUrl: "https://images.unsplash.com/photo-1448375240586-882707db888b?w=800&q=80",
      htmlTemplate: '''<article class="post">
  <div class="meta">Engineering · 5 min read</div>
  <h1>Architecting Scalable Micro-Frontends</h1>
  <p>Modern frontend engineering demands modularity, isolated lifecycles, and seamless team boundaries.</p>
  <div class="author">
    <div class="avatar"></div>
    <div><strong>Alex Vance</strong> · Staff Engineer</div>
  </div>
</article>''',
      cssTemplate: '''body { margin: 0; background: #09090b; font-family: system-ui, sans-serif; color: #fff; min-height: 100vh; display: grid; place-content: center; }
.post { max-width: 600px; padding: 2.5rem; background: rgba(255,255,255,0.04); border-radius: 24px; border: 1px solid rgba(255,255,255,0.12); backdrop-filter: blur(24px); }
.meta { color: #54c5f8; font-size: 13px; font-weight: bold; margin-bottom: 1rem; }
h1 { font-size: 2.2rem; font-weight: 800; margin: 0 0 1rem; line-height: 1.25; }
p { color: rgba(255,255,255,0.8); line-height: 1.6; margin-bottom: 2rem; }
.author { display: flex; align-items: center; gap: 12px; border-top: 1px solid rgba(255,255,255,0.1); padding-top: 1.5rem; }
.avatar { width: 40px; height: 40px; border-radius: 50%; background: #54c5f8; }''',
      jsTemplate: '''console.log("Blog reader mounted.");''',
    ),
  ];

  static final List<LearnContent> learnContent = [
    LearnContent(
      day: 1,
      category: "HTML",
      title: "Introduction to HTML",
      theory: "HTML (HyperText Markup Language) is the standard markup language for documents designed to be displayed in a web browser. It forms the structural skeleton of web pages. An HTML document is made up of nested elements, which are represented by tags like h1, p, div, and span.",
      codeExample: '''<!DOCTYPE html>
<html>
<head>
  <title>My First Page</title>
</head>
<body>
  <h1>Hello World</h1>
  <p>This is a paragraph.</p>
</body>
</html>''',
      task: "Create a simple HTML page structure with a custom page title and a heading tag containing your name.",
    ),
    LearnContent(
      day: 2,
      category: "HTML",
      title: "Headings, Paragraphs, and Text Styling",
      theory: "HTML offers structured text tags. Headings range from h1 (most important) to h6 (least important). Paragraphs are written with the p tag. You can add bold emphasis using the strong tag and italics using the em (emphasis) tag.",
      codeExample: '''<h1>Main Heading</h1>
<h2>Subheading</h2>
<p>This is a regular paragraph with <strong>bold</strong> and <em>italicized</em> text styled within it.</p>''',
      task: "Write a short 3-sentence description of your favorite hobbies, bolding the name of each hobby.",
    ),
    LearnContent(
      day: 10,
      category: "CSS",
      title: "Introduction to CSS & Styling",
      theory: "CSS (Cascading Style Sheets) controls the visual presentation, styling, layout, and colors of your HTML documents. Colors can be applied using Hex codes (like #2B124C), RGB values, or preset color names. You target elements using HTML tags, classes, or IDs.",
      codeExample: '''<style>
  body {
    background-color: #FBE4D8;
    color: #190019;
    font-family: sans-serif;
  }
  h1 {
    color: #2B124C;
    border-bottom: 2px solid #DFB6B2;
  }
</style>
<h1>Beautiful Palette Page</h1>
<p>Styling elements with warm tones.</p>''',
      task: "Create a styling block that changes the text color of all h2 headers to purple and gives the background a soft peach off-white hue.",
    ),
    LearnContent(
      day: 21,
      category: "JavaScript",
      title: "JavaScript Basics: Variables and Console Log",
      theory: "JavaScript adds dynamic interactivity to web pages. Variables allow you to store values using keywords like let, const, or var. You can log values and debug code directly inside the console panel using console.log().",
      codeExample: '''<script>
  const appName = "CodeSnap IDE";
  let userStreak = 15;
  
  console.log("Welcome to " + appName);
  console.log("Your current learning streak is: " + userStreak + " days!");
</script>''',
      task: "Create a script that stores your name in a variable called 'developerName' and logs a greeting using that variable.",
    ),
  ];

  static final List<UserProfile> mockPeople = [
    // 1. Elena Rostova
    UserProfile(
      id: "user-elena",
      name: "Elena Rostova",
      handle: "@elena_codes",
      avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80",
      bannerUrl: "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=1200&q=80",
      headline: "Senior Systems Architect & Flutter Core Contributor",
      bio: "Obsessed with fluid 120fps UI design, Dart compilers, and high-throughput microservices. Building CodeSnap VisionOS Liquid Glass components.",
      roleBadge: "Core Contributor",
      department: "Computer Science · Stanford",
      location: "San Francisco, CA",
      followersCount: 3420,
      followingCount: 412,
      postsCount: 56,
      skills: ["Flutter", "Dart", "Rust", "WebAssembly", "UI/UX"],
      isOnline: true,
      isFollowing: false,
      mediaItems: [
        UserMediaItem(
          id: "m-elena-1",
          title: "Liquid Glass UI Architecture diagram",
          type: "image",
          mediaUrl: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500&q=80",
          fileSize: "2.4 MB",
          likesCount: 284,
          viewsCount: 1420,
          timestamp: "2 hours ago",
        ),
        UserMediaItem(
          id: "m-elena-2",
          title: "Fluid Morph Animation Demo",
          type: "video",
          mediaUrl: "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=500&q=80",
          fileSize: "18.5 MB",
          duration: "0:42",
          likesCount: 512,
          viewsCount: 3200,
          timestamp: "Yesterday",
        ),
        UserMediaItem(
          id: "m-elena-3",
          title: "Custom Shader Render Pipeline",
          type: "image",
          mediaUrl: "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=500&q=80",
          fileSize: "3.1 MB",
          likesCount: 198,
          viewsCount: 940,
          timestamp: "3 days ago",
        ),
        UserMediaItem(
          id: "m-elena-4",
          title: "Next-Gen Terminal Stream Prototype",
          type: "video",
          mediaUrl: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=500&q=80",
          fileSize: "24.2 MB",
          duration: "1:15",
          likesCount: 740,
          viewsCount: 4100,
          timestamp: "5 days ago",
        ),
        UserMediaItem(
          id: "m-elena-5",
          title: "VisionOS Frosted Window Mockups",
          type: "image",
          mediaUrl: "https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=500&q=80",
          fileSize: "4.8 MB",
          likesCount: 389,
          viewsCount: 1850,
          timestamp: "1 week ago",
        ),
      ],
      posts: [
        UserPostItem(
          id: "p-elena-1",
          content: "Achieved 120fps physics animations in our CustomPainter liquid glass canvas. The secret is caching the blur shader matrix and driving scale via SpringSimulation overshoot curves!",
          codeSnippet: '''final simulation = SpringSimulation(
  SpringDescription(mass: 1.0, stiffness: 220.0, damping: 18.0),
  _controller.value, 1.0, - velocity,
);
_controller.animateWith(simulation);''',
          language: "dart",
          likesCount: 142,
          commentsCount: 23,
          timestamp: "4 hours ago",
        ),
      ],
      projects: [
        UserProjectItem(
          id: "prj-elena-1",
          title: "VisionOS-Flutter-Kit",
          description: "Open-source glassmorphic widgets and morph transitions designed for spatial UI.",
          stars: 1240,
          forks: 189,
          techStack: ["Dart", "Flutter", "GLSL"],
        ),
      ],
    ),

    // 2. Marcus Chen
    UserProfile(
      id: "user-marcus",
      name: "Marcus Chen",
      handle: "@marcus_dev",
      avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80",
      bannerUrl: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1200&q=80",
      headline: "AI Systems Researcher & Deep Learning Engineer",
      bio: "Focusing on efficient LLM inference, local quantizations, and biological sequence modeling. Core maintainer of open AI tooling.",
      roleBadge: "AI Mentor",
      department: "AI & Robotics · MIT",
      location: "Boston, MA",
      followersCount: 5180,
      followingCount: 290,
      postsCount: 84,
      skills: ["Python", "PyTorch", "C++", "CUDA", "Docker"],
      isOnline: true,
      isFollowing: true,
      mediaItems: [
        UserMediaItem(
          id: "m-marcus-1",
          title: "Transformer Cross-Attention Heatmap",
          type: "image",
          mediaUrl: "https://images.unsplash.com/photo-1509228468518-180dd4864904?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1509228468518-180dd4864904?w=500&q=80",
          fileSize: "1.8 MB",
          likesCount: 340,
          viewsCount: 1800,
          timestamp: "Yesterday",
        ),
        UserMediaItem(
          id: "m-marcus-2",
          title: "Local Llama 3 8B Inference on GPU",
          type: "video",
          mediaUrl: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=500&q=80",
          fileSize: "32.1 MB",
          duration: "1:40",
          likesCount: 820,
          viewsCount: 5400,
          timestamp: "2 days ago",
        ),
        UserMediaItem(
          id: "m-marcus-3",
          title: "Cluster Multi-GPU Training Loss Curve",
          type: "image",
          mediaUrl: "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=500&q=80",
          fileSize: "2.2 MB",
          likesCount: 412,
          viewsCount: 2200,
          timestamp: "4 days ago",
        ),
      ],
      posts: [
        UserPostItem(
          id: "p-marcus-1",
          content: "Released our 4-bit KV-cache quantization benchmark. We managed to fit a 32k context window in just 6GB of VRAM with zero perplexity degradation.",
          codeSnippet: '''import torch
from transformers import AutoModelForCausalLM

model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Meta-Llama-3-8B",
    torch_dtype=torch.float16,
    device_map="auto",
    load_in_4bit=True
)''',
          language: "python",
          likesCount: 310,
          commentsCount: 45,
          timestamp: "1 day ago",
        ),
      ],
      projects: [
        UserProjectItem(
          id: "prj-marcus-1",
          title: "Fast-Inference-Engine",
          description: "Ultra-low latency C++ streaming inference backend for local LLMs.",
          stars: 2890,
          forks: 340,
          techStack: ["C++", "CUDA", "Python"],
        ),
      ],
    ),

    // 3. Aria Tanaka
    UserProfile(
      id: "user-aria",
      name: "Aria Tanaka",
      handle: "@ariatanaka",
      avatarUrl: "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&q=80",
      bannerUrl: "https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=1200&q=80",
      headline: "Lead UI/UX Designer & Creative Technologist",
      bio: "Designing spatial computing layouts, fluid morphing micro-interactions, and dark holographic themes. Living between Tokyo & Figma.",
      roleBadge: "Design Lead",
      department: "Human-Computer Interaction",
      location: "Tokyo, Japan",
      followersCount: 8910,
      followingCount: 340,
      postsCount: 112,
      skills: ["Figma", "WebGL", "Three.js", "CSS Glass", "SwiftUI"],
      isOnline: false,
      isFollowing: false,
      mediaItems: [
        UserMediaItem(
          id: "m-aria-1",
          title: "VisionOS Spatial Glass Dashboard",
          type: "image",
          mediaUrl: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500&q=80",
          fileSize: "5.2 MB",
          likesCount: 920,
          viewsCount: 7100,
          timestamp: "3 days ago",
        ),
        UserMediaItem(
          id: "m-aria-2",
          title: "Specular Light Reflection Walkthrough",
          type: "video",
          mediaUrl: "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=500&q=80",
          fileSize: "28.4 MB",
          duration: "0:58",
          likesCount: 1120,
          viewsCount: 8900,
          timestamp: "4 days ago",
        ),
      ],
      posts: [
        UserPostItem(
          id: "p-aria-1",
          content: "Remember: good glassmorphism is NOT just blur. It requires a 1px specular inner highlight at rgba(255,255,255,0.18) and a soft ambient occlusion drop shadow.",
          likesCount: 420,
          commentsCount: 38,
          timestamp: "2 days ago",
        ),
      ],
      projects: [
        UserProjectItem(
          id: "prj-aria-1",
          title: "Liquid-UI-Design-System",
          description: "Curated Figma tokens, CSS shaders, and glassmorphic motion curves.",
          stars: 4300,
          forks: 620,
          techStack: ["Figma", "CSS", "SVG"],
        ),
      ],
    ),

    // 4. Devon Vance
    UserProfile(
      id: "user-devon",
      name: "Devon Vance",
      handle: "@devon_v",
      avatarUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&q=80",
      bannerUrl: "https://images.unsplash.com/photo-1519681393784-d120267933ba?w=1200&q=80",
      headline: "Full-Stack Engineer & Cloud Infrastructure Architect",
      bio: "High-performance web architecture, zero-downtime distributed systems, and real-time WebSockets. Building tools for developers.",
      roleBadge: "Mentor",
      department: "Software Engineering · Berkeley",
      location: "Seattle, WA",
      followersCount: 2750,
      followingCount: 520,
      postsCount: 39,
      skills: ["TypeScript", "Next.js", "Go", "Kubernetes", "PostgreSQL"],
      isOnline: true,
      isFollowing: false,
      mediaItems: [
        UserMediaItem(
          id: "m-devon-1",
          title: "Microservices Network Mesh Benchmark",
          type: "image",
          mediaUrl: "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=500&q=80",
          fileSize: "2.1 MB",
          likesCount: 165,
          viewsCount: 890,
          timestamp: "5 days ago",
        ),
      ],
      posts: [
        UserPostItem(
          id: "p-devon-1",
          content: "Migrated our live WebSocket cluster to Go with gorilla/websocket. Memory consumption plummeted from 1.8GB to 180MB for 50,000 concurrent sockets!",
          likesCount: 215,
          commentsCount: 19,
          timestamp: "3 days ago",
        ),
      ],
      projects: [
        UserProjectItem(
          id: "prj-devon-1",
          title: "Go-WebSocket-Mesh",
          description: "Distributed real-time pub/sub mesh over Redis & WebSockets.",
          stars: 980,
          forks: 110,
          techStack: ["Go", "Redis", "Docker"],
        ),
      ],
    ),

    // 5. Sophia Alvarez
    UserProfile(
      id: "user-sophia",
      name: "Sophia Alvarez",
      handle: "@sophia_codes",
      avatarUrl: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80",
      bannerUrl: "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=1200&q=80",
      headline: "Mobile Engineer & Community Organizer",
      bio: "Crafting delightful mobile experiences on iOS & Android. Speaker at mobile tech conferences. Mentoring women in tech.",
      roleBadge: "Campus Lead",
      department: "Information Technology",
      location: "Austin, TX",
      followersCount: 4320,
      followingCount: 610,
      postsCount: 63,
      skills: ["Flutter", "Swift", "Kotlin", "Firebase", "GraphQL"],
      isOnline: true,
      isFollowing: true,
      mediaItems: [
        UserMediaItem(
          id: "m-sophia-1",
          title: "Fluid Bottom Card Morph Architecture",
          type: "image",
          mediaUrl: "https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=500&q=80",
          fileSize: "3.4 MB",
          likesCount: 312,
          viewsCount: 1920,
          timestamp: "Yesterday",
        ),
        UserMediaItem(
          id: "m-sophia-2",
          title: "Gesture-Driven Card Dismiss Simulation",
          type: "video",
          mediaUrl: "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=500&q=80",
          fileSize: "14.8 MB",
          duration: "0:28",
          likesCount: 640,
          viewsCount: 4100,
          timestamp: "3 days ago",
        ),
      ],
      posts: [
        UserPostItem(
          id: "p-sophia-1",
          content: "Always add mouse-drag support to your PageViews on Flutter desktop! With MouseTracker and PointerDeviceKind, your Windows desktop app feels as responsive as mobile.",
          likesCount: 280,
          commentsCount: 31,
          timestamp: "2 days ago",
        ),
      ],
      projects: [
        UserProjectItem(
          id: "prj-sophia-1",
          title: "Gesture-Card-Flow",
          description: "Production-ready 2D interactive dragging and dismissal cards for Flutter.",
          stars: 1840,
          forks: 210,
          techStack: ["Dart", "Flutter"],
        ),
      ],
    ),

    // 6. Kavya Patel
    UserProfile(
      id: "user-kavya",
      name: "Kavya Patel",
      handle: "@kavyapatel",
      avatarUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&q=80",
      bannerUrl: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1200&q=80",
      headline: "Algorithm Specialist & Competitive Programmer",
      bio: "Master on Codeforces. Teaching advanced graph algorithms, dynamic programming, and computational geometry to students worldwide.",
      roleBadge: "DSA Mentor",
      department: "Computer Engineering · IIT Bombay",
      location: "Mumbai, India",
      followersCount: 6840,
      followingCount: 180,
      postsCount: 95,
      skills: ["C++", "Java", "DSA", "Algorithms", "Python"],
      isOnline: false,
      isFollowing: false,
      mediaItems: [
        UserMediaItem(
          id: "m-kavya-1",
          title: "Red-Black Tree Self-Balancing Flowchart",
          type: "image",
          mediaUrl: "https://images.unsplash.com/photo-1509228468518-180dd4864904?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1509228468518-180dd4864904?w=500&q=80",
          fileSize: "1.9 MB",
          likesCount: 520,
          viewsCount: 3100,
          timestamp: "4 days ago",
        ),
        UserMediaItem(
          id: "m-kavya-2",
          title: "Dijkstra vs A* Algorithm Visualizer",
          type: "video",
          mediaUrl: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=1000&q=80",
          thumbnailUrl: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=500&q=80",
          fileSize: "38.6 MB",
          duration: "1:52",
          likesCount: 940,
          viewsCount: 6800,
          timestamp: "1 week ago",
        ),
      ],
      posts: [
        UserPostItem(
          id: "p-kavya-1",
          content: "Quick reminder: Priority queues with binary heaps run in O(log N). If you need O(1) find-min and amortized O(1) decrease-key, consider Fibonacci heaps!",
          likesCount: 390,
          commentsCount: 28,
          timestamp: "3 days ago",
        ),
      ],
      projects: [
        UserProjectItem(
          id: "prj-kavya-1",
          title: "DSA-Visualizer-Web",
          description: "Interactive animated step-through of 40+ fundamental computer science algorithms.",
          stars: 3120,
          forks: 480,
          techStack: ["TypeScript", "Canvas", "HTML5"],
        ),
      ],
    ),
  ];

  static UserProfile getUserProfileForAuthor({
    required String username,
    String? avatarUrl,
    String? location,
  }) {
    final clean = username.toLowerCase().replaceAll('@', '').trim();
    for (final person in mockPeople) {
      final handleClean = person.handle.toLowerCase().replaceAll('@', '').trim();
      final nameClean = person.name.toLowerCase().trim();
      if (handleClean == clean ||
          nameClean.contains(clean) ||
          clean.contains(handleClean)) {
        return person;
      }
    }

    final id = 'user-${username.replaceAll('.', '-').replaceAll('@', '')}';
    final fallbackAvatar = (avatarUrl != null && avatarUrl.isNotEmpty)
        ? avatarUrl
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80';

    final displayName = username.contains('.')
        ? username
            .split('.')
            .map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '')
            .join(' ')
        : (username.isNotEmpty ? '${username[0].toUpperCase()}${username.substring(1)}' : 'Creator');

    return UserProfile(
      id: id,
      name: displayName,
      handle: '@${username.replaceAll('@', '')}',
      avatarUrl: fallbackAvatar,
      bannerUrl: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=1200&q=80',
      headline: 'Developer & Creator · Bug Community',
      bio: 'Sharing moments, code architectures, and developer experiments. Building fluid liquid glass experiences.',
      roleBadge: 'Creator',
      department: 'Software Engineering',
      location: location ?? 'Global',
      followersCount: 1420,
      followingCount: 310,
      postsCount: 18,
      skills: const ['Flutter', 'Mobile', 'Design', 'Dart'],
      isOnline: true,
      isFollowing: false,
      mediaItems: [
        UserMediaItem(
          id: 'm-$id-1',
          title: 'Latest Post Media',
          type: 'image',
          mediaUrl: fallbackAvatar,
          thumbnailUrl: fallbackAvatar,
          fileSize: '2.8 MB',
          likesCount: 290,
          viewsCount: 1400,
          timestamp: 'Just now',
        ),
      ],
      posts: [
        UserPostItem(
          id: 'p-$id-1',
          content: 'Building next-generation apps with fluid 120fps animations on Bug!',
          likesCount: 184,
          commentsCount: 22,
          timestamp: '3 hours ago',
        ),
      ],
      projects: [
        UserProjectItem(
          id: 'prj-$id-1',
          title: 'Bug-Mobile-Lab',
          description: 'Experiments with high-fps liquid glass shaders and gesture physics.',
          stars: 420,
          forks: 64,
          techStack: const ['Flutter', 'Dart'],
        ),
      ],
    );
  }

  static final UserProfile selfUser = UserProfile(
    id: 'user-alexj',
    name: 'Alex Johnson',
    handle: '@alexj',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
    bannerUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1200&q=80',
    headline: 'Core Contributor · CSE 3rd Yr · Mobile Systems',
    bio: 'Crafting fluid reactive interfaces and liquid glass micro-interactions on Bug. Exploring native compilers and gesture physics.',
    roleBadge: 'Core Contributor',
    department: 'CSE · Section A',
    location: 'San Francisco, CA',
    followersCount: 1840,
    followingCount: 320,
    postsCount: 12,
    skills: ['Flutter', 'Dart', 'Liquid Glass', 'C++', 'System Design', 'GLSL Shaders'],
    isOnline: true,
    isFollowing: false,
    mediaItems: [
      UserMediaItem(
        id: 'self-media-1',
        title: 'Liquid Glass 120fps Shader Demo',
        type: 'video',
        mediaUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800&q=80',
        thumbnailUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800&q=80',
        fileSize: '14.2 MB',
        duration: '0:34',
        likesCount: 524,
        viewsCount: 3100,
        timestamp: '2 hours ago',
      ),
      UserMediaItem(
        id: 'self-media-2',
        title: 'Kyoto Alleyway Night Walk',
        type: 'image',
        mediaUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800&q=80',
        thumbnailUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800&q=80',
        fileSize: '3.1 MB',
        likesCount: 890,
        viewsCount: 4200,
        timestamp: 'Yesterday',
      ),
      UserMediaItem(
        id: 'self-media-3',
        title: 'Obsidian Code Engine Architecture',
        type: 'image',
        mediaUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800&q=80',
        thumbnailUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800&q=80',
        fileSize: '2.4 MB',
        likesCount: 340,
        viewsCount: 1950,
        timestamp: '3 days ago',
      ),
      UserMediaItem(
        id: 'self-media-4',
        title: 'Multi-threaded Terminal Workspace',
        type: 'video',
        mediaUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80',
        thumbnailUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80',
        fileSize: '18.9 MB',
        duration: '1:12',
        likesCount: 412,
        viewsCount: 2600,
        timestamp: '5 days ago',
      ),
    ],
    posts: [
      UserPostItem(
        id: 'self-post-1',
        content: 'Just deployed the new Liquid Glass UI architecture on Bug! Super clean refraction effects, sub-millisecond gesture tracking, and zero stutter.',
        codeSnippet: 'void main() {\n  runApp(BugApp(\n    theme: LiquidGlassTheme.obsidian,\n    refreshRate: 120,\n  ));\n}',
        language: 'dart',
        likesCount: 215,
        commentsCount: 34,
        timestamp: '1 hour ago',
      ),
      UserPostItem(
        id: 'self-post-2',
        content: 'Building split-screen desktop experiences for developer workflows. Side-by-side terminal, live feed preview, and glass modals feel so intuitive.',
        likesCount: 178,
        commentsCount: 19,
        timestamp: '1 day ago',
      ),
    ],
    projects: [
      UserProjectItem(
        id: 'self-prj-1',
        title: 'Bug-Glass-Engine',
        description: 'High performance glass refraction and spring physics renderer for cross-platform apps.',
        stars: 840,
        forks: 112,
        techStack: ['Flutter', 'Dart', 'C++', 'OpenGL'],
      ),
      UserProjectItem(
        id: 'self-prj-2',
        title: 'Reactive-Workspace-CLI',
        description: 'Autonomous multi-tasking workspace terminal with instant file hot-reload.',
        stars: 430,
        forks: 56,
        techStack: ['Rust', 'Shell'],
      ),
    ],
  );
}
