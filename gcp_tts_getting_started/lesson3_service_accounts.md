# GCP TTS Onboarding - Lesson 3: Generating Credentials

To make sure random scripts can't call your Google Cloud account and charge you money, Google requires your code to use a **Service Account Key** (a credentials file) to authenticate itself.

---

## 1. What is a Service Account?
*   **User Account:** A username and password for a human (like you logging into Gmail).
*   **Service Account:** A special "robot account" designed for code. 
*   **JSON Key File:** A secure text file containing encrypted passwords that allows your Node.js script to log in as the "Service Account robot" and run the TTS API.

---

## 2. Step-by-Step Guide to Generate your JSON Key

Perform these steps in your Google Cloud Console:

### Step 1: Navigate to IAM & Service Accounts
1.  Open the Google Cloud Console and select your `college-Announcements` project.
2.  Click the **Navigation Menu** (three horizontal lines in top-left).
3.  Go to **IAM & Admin > Service Accounts**.

### Step 2: Create the Service Account
1.  Click the **Create Service Account** button at the top.
2.  **Service account name:** Type `tts-dispatcher` (the ID will auto-fill).
3.  Click **Create and Continue**.
4.  **Role Selection:** In the "Select a role" dropdown, search for and choose **Cloud Text-to-Speech API User** (this ensures the robot only has permission to convert text, protecting your account from other changes).
5.  Click **Continue**, then click **Done**.

### Step 3: Download the JSON Key File
1.  In the service account list, look for your new `tts-dispatcher` email row.
2.  Under the **Actions** column (three dots on the right), click **Manage keys**.
3.  Click **Add Key > Create new key**.
4.  Choose **JSON** format and click **Create**.
5.  A file named `[project-name]-[key-id].json` will automatically download to your computer.
6.  **Rename this file** to `credentials.json` and move it into your `~/Desktop/tts_test` folder we created in Lesson 1.

---

## 3. Expected Outcome
Your `~/Desktop/tts_test` folder should now look like this:
```
tts_test/
├── hello.js
├── package.json
└── credentials.json   <-- (Your secret Google key file)
```

Once this file is in place, proceed to **[Lesson 4: Synthesizing Speech](file:///Users/junaid/Desktop/AT/Announcement-system/gcp_tts_getting_started/lesson4_calling_tts_api.md)**!
