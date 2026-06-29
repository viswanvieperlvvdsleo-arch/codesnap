import type { LearnContent } from './types';

export const learnContent: LearnContent[] = [
  // HTML: Day 1-20
  {
    day: 1,
    category: "HTML",
    title: "Introduction to HTML",
    theory: "HTML (HyperText Markup Language) is the standard markup language for documents designed to be displayed in a web browser. It forms the structure of web pages. An HTML document is made up of elements, which are represented by tags.",
    codeExample: `<!DOCTYPE html>
<html>
<head>
  <title>My First Page</title>
</head>
<body>
  <h1>Hello World</h1>
  <p>This is a paragraph.</p>
</body>
</html>`,
    task: "Create a simple HTML file named index.html. It should have a title of 'My Portfolio' and contain a heading with your name and a paragraph about yourself."
  },
  {
    day: 2,
    category: "HTML",
    title: "Headings, Paragraphs, and Formatting",
    theory: "HTML offers various tags to structure text. Headings range from <h1> (most important) to <h6> (least important). Paragraphs are created with <p>. You can add emphasis with <strong> (bold) and <em> (italic), or use <b> and <i> for non-semantic formatting.",
    codeExample: `<h1>Main Heading</h1>
<h2>Subheading</h2>
<p>This is a regular paragraph.</p>
<p>This paragraph contains <strong>important</strong> text and <em>emphasized</em> text.</p>`,
    task: "Create a blog post structure. Use an <h1> for the article title, <h2> for sections, and format some text within paragraphs using <strong> and <em>."
  },
  {
    day: 3,
    category: "HTML",
    title: "Links and Anchor Tags",
    theory: "The anchor tag <a> is used to create hyperlinks. The `href` attribute specifies the destination URL. Links can point to external websites, other pages on your site, or even specific sections on the same page (using element IDs).",
    codeExample: `<!-- External Link -->
<a href="https://www.google.com">Go to Google</a>

<!-- Internal Link to another page -->
<a href="/about.html">About Us</a>

<!-- Link to a section on the same page -->
<a href="#section-one">Jump to Section One</a>
<h2 id="section-one">Section One</h2>`,
    task: "Create two HTML pages, 'home.html' and 'about.html'. Add navigation links on both pages that allow users to switch between them."
  },
  {
    day: 4,
    category: "HTML",
    title: "Images and Attributes",
    theory: "The <img> tag is used to embed images. It's an empty tag, meaning it has no closing tag. Key attributes are `src` (the image URL), `alt` (alternative text for accessibility), `width`, and `height`.",
    codeExample: `<img src="https://picsum.photos/400/200" alt="A random placeholder image" width="400" height="200">`,
    task: "Create a 'gallery.html' page and display three different images from picsum.photos. Ensure each image has appropriate `alt` text."
  },
  {
    day: 5,
    category: "HTML",
    title: "Lists: Unordered and Ordered",
    theory: "HTML provides two main types of lists. Unordered lists (<ul>) are for items where the order doesn't matter (like a shopping list). Ordered lists (<ol>) are for items where the sequence is important (like steps in a recipe). Each item in a list is defined with the <li> tag.",
    codeExample: `<h4>Shopping List</h4>
<ul>
  <li>Milk</li>
  <li>Bread</li>
  <li>Cheese</li>
</ul>

<h4>How to Make Tea</h4>
<ol>
  <li>Boil water.</li>
  <li>Add tea bag to cup.</li>
  <li>Pour boiling water into cup.</li>
</ol>`,
    task: "Create a recipe page for your favorite dish. Use an <ul> for the ingredients and an <ol> for the step-by-step instructions."
  },
  {
    day: 6,
    category: "HTML",
    title: "Tables",
    theory: "HTML tables are used to display data in a tabular format. The main tags are <table>, <tr> (table row), <td> (table data/cell), and <th> (table header).",
    codeExample: `<table border="1">
  <tr>
    <th>Name</th>
    <th>Grade</th>
  </tr>
  <tr>
    <td>Alex</td>
    <td>A</td>
  </tr>
  <tr>
    <td>Ben</td>
    <td>B</td>
  </tr>
</table>`,
    task: "Create a table showing the names and marks of five students in three different subjects."
  },
  {
    day: 7,
    category: "HTML",
    title: "Forms Basics",
    theory: "HTML forms are used to collect user input. The <form> element is a container for different types of input elements. The <label> tag improves accessibility by linking text to a specific input field.",
    codeExample: `<form>
  <label for="username">Username:</label><br>
  <input type="text" id="username" name="username"><br>
  <label for="email">Email:</label><br>
  <input type="email" id="email" name="email">
</form>`,
    task: "Create a simple contact form with fields for 'Name' and 'Message'."
  },
  {
    day: 8,
    category: "HTML",
    title: "More Input Types",
    theory: "HTML provides a wide variety of input types beyond just text, including `password`, `email`, `number`, `date`, `radio` (for single selection), and `checkbox` (for multiple selections).",
    codeExample: `<form>
  <label for="password">Password:</label>
  <input type="password" id="password"><br>

  <p>Gender:</p>
  <input type="radio" id="male" name="gender" value="male">
  <label for="male">Male</label><br>
  <input type="radio" id="female" name="gender" value="female">
  <label for="female">Female</label><br>

  <p>Hobbies:</p>
  <input type="checkbox" id="reading" name="hobbies" value="reading">
  <label for="reading">Reading</label><br>
  <input type="checkbox" id="music" name="hobbies" value="music">
  <label for="music">Music</label>
</form>`,
    task: "Build a registration form for a fictional event. It should include fields for name, email, password, date of birth, and gender (using radio buttons)."
  },
  {
    day: 9,
    category: "HTML",
    title: "Buttons and Submit",
    theory: "Buttons allow users to trigger actions. The `<button>` tag or `<input type='submit'>` can be used. A submit button inside a `<form>` will attempt to send the form data to a server.",
    codeExample: `<form action="/register" method="post">
  <label for="name">Name:</label>
  <input type="text" id="name" name="name">
  <br><br>
  <button type="submit">Submit</button>
  <button type="reset">Reset</button>
</form>`,
    task: "Add 'Submit' and 'Reset' buttons to the registration form you created yesterday."
  },
  {
    day: 10,
    category: "HTML",
    title: "Semantic HTML",
    theory: "Semantic HTML tags clearly describe their meaning to both the browser and the developer. Using tags like `<header>`, `<footer>`, `<nav>`, `<section>`, `<article>`, and `<aside>` improves SEO and accessibility, making your code easier to read and maintain.",
    codeExample: `<header>
  <h1>My Awesome Blog</h1>
  <nav>...</nav>
</header>
<main>
  <article>
    <h2>Article Title</h2>
    <p>Article content...</p>
  </article>
</main>
<footer>
  <p>Copyright 2024</p>
</footer>`,
    task: "Re-structure your personal portfolio from Day 1 using semantic HTML tags like `<header>`, `<main>`, `<section>`, and `<footer>`."
  },
  {
    day: 11,
    category: "HTML",
    title: "Div and Span",
    theory: "<div> (division) is a block-level generic container used to group other elements for styling or layout purposes. <span> is an inline-level generic container used to group text or other inline elements, often to apply styles to a part of a sentence.",
    codeExample: `<div class="card">
  <h2>Card Title</h2>
  <p>This is some text inside a div. <span class="highlight">This part is highlighted.</span></p>
</div>`,
    task: "Create a product card layout using a `div`. Inside, have an image, a title, a description, and a price. Use a `span` to make the price a different color."
  },
  {
    day: 12,
    category: "HTML",
    title: "ID and Class Attributes",
    theory: "The `id` attribute provides a unique identifier for an element on a page (must be unique). The `class` attribute is used to specify one or more class names for an element, allowing multiple elements to be styled or selected together.",
    codeExample: `<h1 id="main-title">Main Title</h1>

<p class="intro-text">This is an introduction.</p>
<p class="intro-text">This is also an introduction.</p>`,
    task: "Go back to your portfolio page. Add a unique `id` to the main header and a common `class` to all section headings."
  },
  {
    day: 13,
    category: "HTML",
    title: "Iframes",
    theory: "An `<iframe>` (inline frame) is used to embed another HTML document within the current one. It's commonly used for embedding maps, videos, or content from other websites.",
    codeExample: `<iframe 
  src="https://www.youtube.com/embed/dQw4w9WgXcQ" 
  width="560" 
  height="315" 
  title="YouTube video player" 
  frameborder="0" 
  allowfullscreen>
</iframe>`,
    task: "Embed a Google Map location and a YouTube video of your choice on a new 'contact.html' page."
  },
  {
    day: 14,
    category: "HTML",
    title: "Audio and Video",
    theory: "HTML5 introduced the `<audio>` and `<video>` tags, allowing you to embed media directly without plugins. The `controls` attribute provides default play/pause/volume controls.",
    codeExample: `<h4>Audio Player</h4>
<audio controls src="audio.mp3">
  Your browser does not support the audio element.
</audio>

<h4>Video Player</h4>
<video controls width="400" src="video.mp4">
  Your browser does not support the video tag.
</video>`,
    task: "Create a page that includes a video with controls. Since you might not have a video file, you can just set the `src` attribute and see the player render."
  },
  {
    day: 15,
    category: "HTML",
    title: "Meta Tags",
    theory: "`<meta>` tags provide metadata about the HTML document. They don't display on the page but are machine-readable. Common uses include setting character set (`charset`), `description` for SEO, and `viewport` for responsive design.",
    codeExample: `<head>
  <meta charset="UTF-8">
  <meta name="description" content="A brief summary of the page content.">
  <meta name="keywords" content="HTML, CSS, JavaScript">
  <meta name="author" content="John Doe">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>`,
    task: "Add appropriate `meta` tags for description, keywords, and author to all the pages you have created so far."
  },
  {
    day: 16,
    category: "HTML",
    title: "HTML5 New Elements",
    theory: "HTML5 introduced many new semantic elements to better structure web content, such as `<main>`, `<nav>`, `<aside>`, `<figure>`, and `<figcaption>`. Using them makes your code more meaningful.",
    codeExample: `<nav>...</nav>

<main>
  <article>
    <figure>
      <img src="image.jpg" alt="Description">
      <figcaption>Fig.1 - A caption for the image.</figcaption>
    </figure>
  </article>
</main>

<aside>
  <h3>Related Links</h3>
</aside>`,
    task: "Review your portfolio project and replace generic `<div>` tags with more appropriate HTML5 semantic elements where possible (e.g., use `<figure>` for images with captions)."
  },
  {
    day: 17,
    category: "HTML",
    title: "Accessibility (a11y) Basics",
    theory: "Web accessibility (a11y) is the practice of ensuring your websites are usable by everyone, including people with disabilities. Simple practices include using `alt` text for images, using `<label>` for form inputs, and using semantic HTML.",
    codeExample: `<!-- Good: Descriptive alt text -->
<img src="pup.jpg" alt="A golden retriever puppy playing with a red ball.">

<!-- Bad: Non-descriptive alt text -->
<img src="pup.jpg" alt="image">

<!-- Good: Label connected to input -->
<label for="email">Email:</label>
<input type="email" id="email">`,
    task: "Audit one of your previous projects (like the gallery or form) and ensure all images have descriptive `alt` text and all form inputs have associated `<label>`s."
  },
  {
    day: 18,
    category: "HTML",
    title: "HTML Best Practices",
    theory: "Writing clean, maintainable HTML is crucial. Best practices include: using lowercase for tags and attributes, indenting code for readability, closing all tags, using semantic tags, and validating your HTML.",
    codeExample: `<!-- Good Practice -->
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Clean Code</title>
  </head>
  <body>
    <header>
      <h1>Readable HTML</h1>
    </header>
  </body>
</html>`,
    task: "Choose one of your previous projects and refactor the code to follow HTML best practices. Check for proper indentation and use of semantic tags."
  },
  {
    day: 19,
    category: "HTML",
    title: "Multi-Page Website Structure",
    theory: "A typical website structure involves a root folder with `index.html` (the homepage), and other HTML files for different pages (e.g., `about.html`, `contact.html`). Assets like CSS, JavaScript, and images are often organized into their own subfolders.",
    codeExample: `Project Folder/
|-- index.html
|-- about.html
|-- contact.html
|-- css/
|   |-- style.css
|-- images/
|   |-- logo.png
|-- js/
    |-- script.js`,
    task: "Create a folder structure for a new 3-page website (Home, Services, Contact). Create the three empty HTML files and link them together using a navigation menu on each page."
  },
  {
    day: 20,
    category: "HTML",
    title: "Mini Project: HTML Portfolio",
    theory: "Combine everything you've learned about HTML to build a complete, multi-page personal portfolio website. This project will serve as the foundation for the upcoming CSS and JavaScript sections.",
    codeExample: `<!-- This is a project day. The code is up to you! -->
<!-- Structure your home page with a header, main sections for bio/skills, and a footer. -->
<!-- Create separate pages for 'Projects' and 'Contact'. -->`,
    task: "Build a multi-page personal portfolio website using only HTML. It must have at least three pages: Home, Projects, and Contact. Use semantic tags, forms, tables, lists, and images appropriately."
  },

  // CSS: Day 21-40
  {
    day: 21,
    category: "CSS",
    title: "Introduction to CSS",
    theory: "CSS (Cascading Style Sheets) is used to style and lay out web pages. There are three ways to include CSS: inline (using the `style` attribute), internal (using a `<style>` tag in the `<head>`), and external (linking to a `.css` file), which is the best practice.",
    codeExample: `/* External CSS (style.css) */
body {
  background-color: #f0f0f0;
  font-family: sans-serif;
}

h1 {
  color: navy;
}`,
    task: "Create an external stylesheet named `style.css` and link it to your portfolio project. Add basic styles to change the background color of the body and the text color of the headings."
  },
  {
    day: 22,
    category: "CSS",
    title: "Selectors, Properties, and Values",
    theory: "CSS rules consist of a selector and a declaration block. Selectors target HTML elements (e.g., `p`, `.my-class`, `#my-id`). The declaration block contains properties (e.g., `color`) and values (e.g., `red`).",
    codeExample: `/* Element selector */
p {
  font-size: 16px;
}

/* Class selector */
.highlight {
  background-color: yellow;
}

/* ID selector */
#main-header {
  border-bottom: 2px solid black;
}`,
    task: "In your portfolio's CSS, use element selectors to style all paragraphs, a class selector to style specific cards or sections, and an ID selector to style the main page title."
  },
  {
    day: 23,
    category: "CSS",
    title: "Colors and Backgrounds",
    theory: "CSS offers several ways to specify colors: color names (e.g., `red`), HEX codes (e.g., `#FF0000`), RGB (e.g., `rgb(255, 0, 0)`), and HSL. You can set the `color` of text and the `background-color` of elements.",
    codeExample: `body {
  background-color: #1a1a1a;
  color: #ffffff;
}

.special-text {
  color: hsl(210, 100%, 50%); /* A nice blue */
}`,
    task: "Create a dark theme color scheme for your portfolio. Set a dark background color for the `body` and a light color for the text."
  },
  {
    day: 24,
    category: "CSS",
    title: "The Box Model",
    theory: "Every HTML element is a rectangular box. The CSS box model consists of: the content, padding (space around content), border (a line around padding), and margin (space outside the border). Understanding this is fundamental to layout.",
    codeExample: `.box {
  width: 200px;
  padding: 20px;
  border: 5px solid black;
  margin: 40px;
}`,
    task: "Create a `div` with a class of 'card'. Give it a fixed width, and then add padding, a border, and a margin to see how the box model affects its size and spacing."
  },
  {
    day: 25,
    category: "CSS",
    title: "Display and Visibility",
    theory: "`display` is a key CSS property. `block` elements (like `div`, `p`) take up the full width available and start on a new line. `inline` elements (like `span`, `a`) only take up as much width as necessary and sit on the same line. `display: none;` hides an element completely, while `visibility: hidden;` hides it but it still takes up space.",
    codeExample: `.block-element { display: block; }
.inline-element { display: inline; }
.hidden-element { display: none; }`,
    task: "Create a navigation menu using an unordered list `<ul>`. By default, `<li>` items are block-level. Change their `display` property to `inline` or `inline-block` to create a horizontal menu."
  },
  {
    day: 26,
    category: "CSS",
    title: "Positioning",
    theory: "The `position` property controls how an element is placed. `static` is the default. `relative` allows you to offset an element from its normal position. `absolute` positions an element relative to its nearest positioned ancestor. `fixed` positions an element relative to the viewport (it stays in place when scrolling).",
    codeExample: `.parent {
  position: relative;
  height: 200px;
}
.child {
  position: absolute;
  bottom: 10px;
  right: 10px;
}`,
    task: "Create a 'Back to Top' button that is always visible in the bottom-right corner of the screen, even when the user scrolls. Use `position: fixed;`."
  },
  {
    day: 27,
    category: "CSS",
    title: "Flexbox Basics",
    theory: "Flexbox is a one-dimensional layout model for arranging items in rows or columns. By setting `display: flex;` on a container, you can easily align and distribute space among its children using properties like `justify-content` (for horizontal alignment) and `align-items` (for vertical alignment).",
    codeExample: `.container {
  display: flex;
  justify-content: space-between; /* space-around, center */
  align-items: center;
}`,
    task: "Use Flexbox to perfectly center a `div` both horizontally and vertically inside its parent container. Then, use it to create your main site header, aligning the logo to the left and navigation links to the right."
  },
  {
    day: 28,
    category: "CSS",
    title: "Flexbox Advanced",
    theory: "Flexbox offers more powerful features like `flex-direction` (to switch between row and column), `flex-wrap` (to allow items to wrap onto new lines), `flex-grow` and `flex-shrink` (to control how items resize).",
    codeExample: `.container {
  display: flex;
  flex-wrap: wrap;
}
.item {
  flex-grow: 1; /* Allows item to grow and fill available space */
  flex-basis: 200px; /* Sets the initial size of the item */
}`,
    task: "Create a responsive gallery of cards. On wide screens, the cards should appear in a row. On smaller screens, they should wrap to the next line. Use `flex-wrap: wrap;`."
  },
  {
    day: 29,
    category: "CSS",
    title: "CSS Grid Basics",
    theory: "CSS Grid is a two-dimensional layout system, perfect for creating complex layouts with rows and columns. You define a grid on a container with `display: grid;` and then use `grid-template-columns` and `grid-template-rows` to define the tracks.",
    codeExample: `.grid-container {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr; /* Three equal columns */
  gap: 10px;
}`,
    task: "Create a simple 3x3 grid of colored boxes using CSS Grid."
  },
  {
    day: 30,
    category: "CSS",
    title: "CSS Grid Advanced",
    theory: "Grid becomes even more powerful when you name grid lines and areas (`grid-template-areas`) or use functions like `repeat()` and `minmax()` for responsive track sizes. You can place items precisely using `grid-column` and `grid-row`.",
    codeExample: `.wrapper {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  grid-template-rows: auto;
  grid-template-areas: 
    "header header header"
    "main main sidebar"
    "footer footer footer";
}
.header { grid-area: header; }`,
    task: "Re-create a classic 'Holy Grail' layout (Header, Main Content, Left Nav, Right Ad, Footer) using `grid-template-areas`."
  },
  {
    day: 31,
    category: "CSS",
    title: "Responsive Design Principles",
    theory: "Responsive web design is about making your site look good on all devices (desktops, tablets, phones). Key principles include using fluid grids (with percentages or `fr` units), flexible images (`max-width: 100%`), and media queries.",
    codeExample: `img {
  max-width: 100%;
  height: auto;
}`,
    task: "Go to your portfolio project and ensure all images are responsive by setting their `max-width` to 100%."
  },
  {
    day: 32,
    category: "CSS",
    title: "Media Queries",
    theory: "Media queries allow you to apply CSS styles only when certain conditions are met, such as the screen width being above or below a certain size. This is the core technology behind responsive design.",
    codeExample: `/* For screens 600px wide or less */
@media (max-width: 600px) {
  .container {
    flex-direction: column;
  }
}`,
    task: "Add a media query to your portfolio's CSS. For screen widths below 768px, change your multi-column layout (created with Flexbox or Grid) into a single-column layout."
  },
  {
    day: 33,
    category: "CSS",
    title: "Pseudo-classes and Hover Effects",
    theory: "Pseudo-classes are keywords added to selectors that specify a special state of the element. `:hover` is one of the most common, allowing you to apply styles when a user's mouse is over an element. Others include `:focus`, `:active`, and `:nth-child()`.",
    codeExample: `button:hover {
  background-color: blue;
  color: white;
}

a:focus {
  outline: 2px solid blue;
}`,
    task: "Add a `:hover` effect to all the buttons and links in your portfolio. Change their background or text color when the user hovers over them."
  },
  {
    day: 34,
    category: "CSS",
    title: "Transitions",
    theory: "CSS transitions provide a way to control the speed of property changes, creating smooth animations. You can specify which property to animate (`transition-property`), how long it should take (`transition-duration`), and the timing function (`transition-timing-function`).",
    codeExample: `.box {
  width: 100px;
  height: 100px;
  background-color: red;
  transition: background-color 0.5s ease-in-out;
}
.box:hover {
  background-color: blue;
}`,
    task: "Apply a smooth `transition` to the `:hover` effects you created yesterday. Make the color change take 0.3 seconds."
  },
  {
    day: 35,
    category: "CSS",
    title: "Transforms",
    theory: "The `transform` property lets you modify the coordinate space of an element. You can `translate()` (move), `rotate()`, `scale()` (resize), and `skew()` elements in 2D or 3D space.",
    codeExample: `.element:hover {
  transform: scale(1.1) rotate(5deg);
  transition: transform 0.3s;
}`,
    task: "On your portfolio's project cards, add a `transform` that slightly scales up the card when the user hovers over it. Combine this with a `transition` for a smooth effect."
  },
  {
    day: 36,
    category: "CSS",
    title: "CSS Variables (Custom Properties)",
    theory: "CSS Variables allow you to define reusable values (like colors or sizes) in your stylesheet. They are defined with a `--` prefix (e.g., `--main-color: blue;`) and used with the `var()` function (e.g., `color: var(--main-color);`).",
    codeExample: `:root {
  --primary-color: #3b82f6;
  --text-color: #333;
}

body {
  color: var(--text-color);
}

button {
  background-color: var(--primary-color);
}`,
    task: "Refactor your portfolio's CSS to use variables for your main color palette and font sizes. Define them in the `:root` selector."
  },
  {
    day: 37,
    category: "CSS",
    title: "Styling Forms",
    theory: "Styling form elements can be tricky but is essential for a good user experience. You can style inputs, buttons, and labels just like other elements. Pseudo-classes like `:focus` are very important for showing the user which field is active.",
    codeExample: `input[type="text"] {
  padding: 10px;
  border: 1px solid #ccc;
  border-radius: 4px;
}

input[type="text"]:focus {
  border-color: #3b82f6;
  outline: none;
  box-shadow: 0 0 5px rgba(59, 130, 246, 0.5);
}`,
    task: "Go back to the form you created in the HTML section and give it a complete visual overhaul. Style the input fields, labels, and buttons to match your portfolio's theme."
  },
  {
    day: 38,
    category: "CSS",
    title: "Shadows and Depth",
    theory: "You can add depth and realism to your layout using `box-shadow` for elements and `text-shadow` for text. A `box-shadow` takes values for horizontal offset, vertical offset, blur radius, spread radius, and color.",
    codeExample: `.card {
  box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2);
}

h1 {
  text-shadow: 2px 2px 4px #000000;
}`,
    task: "Add a subtle `box-shadow` to your project cards to make them appear lifted off the page."
  },
  {
    day: 39,
    category: "CSS",
    title: "CSS Best Practices",
    theory: "Keep your CSS organized and maintainable. Best practices include: organizing your code into logical sections, using comments, using a consistent naming convention (like BEM), and avoiding overly specific selectors.",
    codeExample: `/* Good: Low specificity, reusable */
.card-title { ... }

/* Bad: High specificity, hard to override */
body #main .content div.card h2 { ... }`,
    task: "Review and refactor the CSS for your portfolio. Organize properties logically (e.g., positioning, box model, typography), add comments for complex sections, and simplify any overly complex selectors."
  },
  {
    day: 40,
    category: "CSS",
    title: "Mini Project: Styled Portfolio",
    theory: "Apply all your CSS knowledge to the HTML portfolio you built. Make it fully styled, responsive, and interactive with hover effects and transitions.",
    codeExample: `/* This is a project day. The code is up to you! */
/* Focus on creating a clean, modern, and professional design. */
/* Ensure it looks great on both desktop and mobile devices. */`,
    task: "Completely style your multi-page portfolio website. It should be fully responsive, have a consistent color scheme and typography, include hover effects and transitions, and feature well-styled forms and other elements."
  },

  // JavaScript: Day 41-60
  {
    day: 41,
    category: "JavaScript",
    title: "Introduction to JavaScript",
    theory: "JavaScript is a programming language that enables you to create dynamically updating content, control multimedia, and animate images. It can be run in the browser's console, in a `<script>` tag in your HTML, or in an external `.js` file.",
    codeExample: `// You can open the browser console (Ctrl+Shift+J) and type this:
console.log("Hello from JavaScript!");`,
    task: "Link an external `script.js` file to your portfolio's HTML. In the script file, use `console.log()` to print five different messages to the browser console."
  },
  {
    day: 42,
    category: "JavaScript",
    title: "Variables and Data Types",
    theory: "Variables are containers for storing data values. In modern JavaScript, we use `let` for variables that can be reassigned and `const` for constants (variables that cannot be reassigned). JavaScript has several data types: String, Number, Boolean, Null, Undefined, and Object.",
    codeExample: `let name = "Alice"; // String
const age = 30; // Number
let isStudent = true; // Boolean

console.log(name, age, isStudent);`,
    task: "In your script file, declare a `const` for your name and a `let` for your age. Log a sentence to the console that includes both variables."
  },
  {
    day: 43,
    category: "JavaScript",
    title: "Data Types",
    theory: "JavaScript has several primitive data types: `String` (text), `Number` (numeric values), `Boolean` (true or false), `null` (intentional absence of value), and `undefined` (value has not been assigned). There are also complex types like `Object` and `Array`.",
    codeExample: `let str = "Hello";
let num = 123;
let bool = false;
let empty = null;
let notAssigned; // undefined
let person = { name: "Bob", age: 42 }; // Object`,
    task: "Declare variables for each of the primitive data types and log their `typeof` to the console to see what JavaScript identifies them as."
  },
  {
    day: 44,
    category: "JavaScript",
    title: "Operators",
    theory: "JavaScript includes arithmetic operators (+, -, *, /), assignment operators (=, +=), comparison operators (==, ===, !=, >), and logical operators (&& for AND, || for OR, ! for NOT).",
    codeExample: `let x = 10;
let y = 5;
console.log(x + y); // 15
console.log(x > y); // true
console.log(x > 0 && y > 0); // true`,
    task: "Create a simple calculator logic. Declare two numbers, then calculate and log their sum, difference, product, and quotient."
  },
  {
    day: 45,
    category: "JavaScript",
    title: "Conditional Statements",
    theory: "Conditional statements are used to perform different actions based on different conditions. The `if...else` statement is the most common way to control program flow.",
    codeExample: `let age = 18;
if (age >= 18) {
  console.log("You are an adult.");
} else {
  console.log("You are a minor.");
}`,
    task: "Write a script that checks a person's age. If they are 65 or older, log 'You are a senior'. If they are 18 or older, log 'You are an adult'. Otherwise, log 'You are a minor'."
  },
  {
    day: 46,
    category: "JavaScript",
    title: "Loops",
    theory: "Loops are used to execute a block of code a number of times. The `for` loop is great for when you know how many times you want to loop. The `while` loop is used when you want to loop as long as a condition is true.",
    codeExample: `// For loop
for (let i = 0; i < 5; i++) {
  console.log("The number is " + i);
}

// While loop
let i = 0;
while (i < 5) {
  console.log("The number is " + i);
  i++;
}`,
    task: "Use a `for` loop to print all the even numbers from 1 to 100 to the console."
  },
  {
    day: 47,
    category: "JavaScript",
    title: "Functions",
    theory: "Functions are blocks of reusable code that you can call to perform a specific task. They can take inputs (parameters) and return an output. Functions help organize your code and make it more efficient.",
    codeExample: `function greet(name) {
  return "Hello, " + name + "!";
}

let greeting = greet("Alice");
console.log(greeting); // "Hello, Alice!"`,
    task: "Write a function named `calculateArea` that takes two parameters, `width` and `height`, and returns their product. Call the function with different values and log the results."
  },
  {
    day: 48,
    category: "JavaScript",
    title: "Arrays",
    theory: "Arrays are special variables which can hold more than one value at a time. You can access items by their index (starting from 0) and use methods like `.push()` (add to end), `.pop()` (remove from end), and `.length` (get size).",
    codeExample: `let fruits = ["Apple", "Banana", "Cherry"];
console.log(fruits[0]); // Apple

fruits.push("Orange");
console.log(fruits.length); // 4

// Loop through an array
fruits.forEach(function(fruit) {
  console.log(fruit);
});`,
    task: "Create an array of your favorite movies. Then, write a `for` loop to print each movie title to the console."
  },
  {
    day: 49,
    category: "JavaScript",
    title: "Objects",
    theory: "Objects are variables that can contain many values, written as name:value pairs (properties). They are used to group related data and are fundamental to JavaScript.",
    codeExample: `let car = {
  make: "Ford",
  model: "Mustang",
  year: 2022,
  start: function() {
    console.log("Engine started!");
  }
};

console.log(car.model); // Mustang
car.start(); // "Engine started!"`,
    task: "Create a `student` object with properties for `name`, `age`, `grade`, and an array of `courses`."
  },
  {
    day: 50,
    category: "JavaScript",
    title: "DOM Manipulation",
    theory: "The DOM (Document Object Model) is a programming interface for web documents. JavaScript can access and change all the HTML elements, attributes, and CSS styles in the document. You can select elements using methods like `getElementById` and `querySelector`.",
    codeExample: `// Get an element by its ID
const titleElement = document.getElementById("main-title");

// Change its text content
titleElement.textContent = "New Title!";

// Change its style
titleElement.style.color = "blue";`,
    task: "On your portfolio page, create a button. Write JavaScript to select the main `<h1>` heading and change its text content to 'Welcome to my Interactive Portfolio!' when the button is clicked."
  },
  {
    day: 51,
    category: "JavaScript",
    title: "Event Listeners",
    theory: "Event listeners allow your script to react to user actions like clicks, mouse movements, or key presses. You use the `.addEventListener()` method on an HTML element to attach a function that runs when the event occurs.",
    codeExample: `const myButton = document.getElementById("my-btn");

myButton.addEventListener("click", function() {
  alert("Button was clicked!");
});`,
    task: "Create a button and a counter display (`<p>`). Every time the button is clicked, increment a counter variable and update the text in the paragraph to show the new count."
  },
  {
    day: 52,
    category: "JavaScript",
    title: "Form Validation",
    theory: "You can use JavaScript to validate form input before it's submitted. This provides a better user experience than server-side validation alone. You typically listen for the form's `submit` event, prevent the default submission, check the values, and then show error messages if needed.",
    codeExample: `const form = document.getElementById("my-form");

form.addEventListener("submit", function(event) {
  const emailInput = document.getElementById("email");
  if (emailInput.value === "") {
    event.preventDefault(); // Stop form submission
    alert("Email cannot be empty!");
  }
});`,
    task: "On your contact form, add JavaScript validation. If the name or message field is empty when the user clicks submit, prevent the form from submitting and display an alert."
  },
  {
    day: 53,
    category: "JavaScript",
    title: "setTimeout and setInterval",
    theory: "`setTimeout` executes a function once after a specified delay (in milliseconds). `setInterval` repeatedly executes a function at a specified interval. These are used for creating timers, delays, and animations.",
    codeExample: `// Run once after 2 seconds
setTimeout(function() {
  console.log("Hello after 2 seconds!");
}, 2000);

// Run every 1 second
let count = 0;
const intervalId = setInterval(function() {
  console.log("Tick " + count);
  count++;
  if (count > 5) {
    clearInterval(intervalId); // Stop the interval
  }
}, 1000);`,
    task: "Create a simple digital clock. Use `setInterval` to update the text of an element on your page with the current time every second."
  },
  {
    day: 54,
    category: "JavaScript",
    title: "Fetch API Basics",
    theory: "The Fetch API provides a modern, promise-based interface for making network requests (e.g., getting data from a server). It's the standard way to perform AJAX operations in modern web development.",
    codeExample: `fetch('https://jsonplaceholder.typicode.com/todos/1')
  .then(response => response.json())
  .then(data => console.log(data))
  .catch(error => console.error('Error:', error));`,
    task: "Use the Fetch API to get a list of users from `https://jsonplaceholder.typicode.com/users`. Log the resulting array of users to the console."
  },
  {
    day: 55,
    category: "JavaScript",
    title: "Local Storage",
    theory: "Web storage (`localStorage` and `sessionStorage`) allows you to store key/value pairs in the user's browser. `localStorage` persists even after the browser is closed, while `sessionStorage` is cleared when the session ends.",
    codeExample: `// Save data to localStorage
localStorage.setItem("username", "Alice");

// Get data from localStorage
const user = localStorage.getItem("username");
console.log(user); // "Alice"

// Remove data
localStorage.removeItem("username");`,
    task: "Create two buttons, 'Light Theme' and 'Dark Theme'. When a button is clicked, save the theme preference to `localStorage` and change the background color of the page."
  },
  {
    day: 56,
    category: "JavaScript",
    title: "ES6 Features (Arrow Functions, Template Literals)",
    theory: "ES6 (ECMAScript 2015) introduced many powerful features. Arrow functions (`=>`) provide a shorter syntax for writing functions. Template literals (using back-ticks ``) allow for easier string interpolation and multi-line strings.",
    codeExample: `// Arrow Function
const add = (a, b) => a + b;

// Template Literal
const name = "Bob";
const message = \`Hello, \${name}!\`;
console.log(message);`,
    task: "Refactor the `greet` function from Day 47 to use an arrow function. Then, rewrite the log message from Day 42 to use a template literal."
  },
  {
    day: 57,
    category: "JavaScript",
    title: "Modules",
    theory: "JavaScript modules allow you to split your code into separate files. You can `export` functions, objects, or variables from one file and `import` them into another. This is essential for organizing large applications.",
    codeExample: `// utils.js
export const PI = 3.14;
export function add(a, b) { return a + b; }

// main.js
import { PI, add } from './utils.js';
console.log(add(5, 10) * PI);`,
    task: "Create two JS files, `math.js` and `main.js`. In `math.js`, export functions for `add` and `subtract`. In `main.js`, import those functions and use them."
  },
  {
    day: 58,
    category: "JavaScript",
    title: "Error Handling",
    theory: "The `try...catch` statement allows you to test a block of code for errors and handle them gracefully without crashing your application. The `try` block contains the code to be run, and the `catch` block executes if an error occurs.",
    codeExample: `try {
  // Code that might cause an error
  let user = JSON.parse('{"name": "Alice", "age": 30,}'); // Invalid JSON
  console.log(user.name);
} catch (error) {
  console.error("An error occurred:", error.message);
}`,
    task: "Write a function that tries to parse a potentially invalid JSON string. Use a `try...catch` block to handle any parsing errors and log a friendly message to the console if the JSON is invalid."
  },
  {
    day: 59,
    category: "JavaScript",
    title: "Mini Project: To-Do App",
    theory: "Build a simple To-Do List application using HTML, CSS, and JavaScript. This will require combining your knowledge of DOM manipulation, event listeners, and array/object management.",
    codeExample: `<!-- HTML Structure -->
<input type="text" id="todo-input" placeholder="Add a new task">
<button id="add-btn">Add</button>
<ul id="todo-list"></ul>`,
    task: "Create a To-Do App. Users should be able to type a task into an input field, click an 'Add' button to add it to a list, and click on a task in the list to mark it as completed (e.g., by adding a line-through style)."
  },
  {
    day: 60,
    category: "JavaScript",
    title: "Final Project: Interactive Portfolio",
    theory: "This is the culmination of your 60-day journey. Combine everything you've learned from HTML, CSS, and JavaScript to build a fully interactive, responsive, and beautifully designed personal portfolio website.",
    codeExample: `// This is a project day. The code is up to you!
// - Use semantic HTML for structure.
// - Use Flexbox/Grid for a responsive layout.
// - Add a theme switcher (light/dark) that uses localStorage.
// - Fetch your project data from a mock JSON file using Fetch API.
// - Add smooth scrolling and other subtle animations.`,
    task: "Upgrade your portfolio website to be fully interactive. Implement a theme switcher, fetch project details from a mock API (you can use `jsonplaceholder` or create your own local JSON file), and add dynamic behavior to your contact form."
  }
];
