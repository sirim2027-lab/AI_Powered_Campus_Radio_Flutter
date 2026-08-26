# GCP TTS Onboarding - Lesson 1: Introduction to Node.js

Welcome to the cloud backend setup! Before we write any code that communicates with Google Cloud, we must understand the core environment we will be running on your computer.

---

## 1. What is Node.js and NPM?
*   **Javascript:** Originally, Javascript could only run inside web browsers (like Chrome or Safari) to make webpages interactive.
*   **Node.js:** A runtime environment that lets you execute Javascript code directly on your computer's operating system—just like Python, C++, or Java.
*   **NPM (Node Package Manager):** A software library containing millions of pre-written code packages. Instead of writing complex APIs from scratch, we use NPM to install libraries (like Google's official TTS helper package).

---

## 2. Your First Node.js Program (Task)

We will set up a workspace folder on your desktop and run a simple Javascript script.

### Step 1: Create a Project Directory
Open your Mac Terminal and run:
```bash
# 1. Navigate to your Desktop
cd ~/Desktop

# 2. Create a new folder named tts_test
mkdir tts_test

# 3. Enter the folder
cd tts_test
```

### Step 2: Initialize NPM
To turn this folder into a Node.js project, run:
```bash
npm init -y
```
*This creates a configuration file named `package.json` inside your folder.*

### Step 3: Write the Code
Create a file named `hello.js` inside the `tts_test` folder, and write this simple code in it:

```javascript
// Define a text variable
const welcomeMessage = "Hello Students! Your Node.js environment is working perfectly.";

// Print the message to the console screen
console.log(welcomeMessage);
```

### Step 4: Run the Script
Go back to your Terminal and execute:
```bash
node hello.js
```

---

## 3. Expected Outcome
You should see:
`Hello Students! Your Node.js environment is working perfectly.`
printed in your terminal log. 

Once this works, proceed to **[Lesson 2: Setting up Google Cloud Console](file:///Users/junaid/Desktop/AT/Announcement-system/gcp_tts_getting_started/lesson2_gcp_project_setup.md)**!
