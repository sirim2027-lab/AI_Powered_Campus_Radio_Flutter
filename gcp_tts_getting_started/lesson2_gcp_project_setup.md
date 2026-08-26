# GCP TTS Onboarding - Lesson 2: Enabling the API in Google Cloud

Now that Node.js is running locally, we need to activate the **Google Cloud Text-to-Speech API** in Google's cloud system.

---

## 1. What is Google Cloud Platform (GCP)?
Google Cloud Platform is a suite of cloud computing services offered by Google. It runs on the same infrastructure that Google uses internally for its end-user products (such as Google Search and YouTube).

To use Google's advanced Text-to-Speech AI engines, we must create a project inside GCP and turn on the TTS service.

---

## 2. Step-by-Step Guide to Enable the API

Follow these instructions to configure your project online:

### Step 1: Create a Google Cloud Account
1.  Go to the [Google Cloud Console](https://console.cloud.google.com/).
2.  Log in using any Google account. 
3.  If this is your first time, agree to the terms of service. (Google offers a **free trial** with $300 in credits, but the TTS free tier is always available).

### Step 2: Create a New Project
1.  In the top menu bar, click the **Project Dropdown** (it might say "Select a project" or show a default project name).
2.  Click **New Project** in the top right of the modal.
3.  Enter a project name (e.g. `college-Announcements`) and click **Create**.
4.  Wait 10 seconds, then click the Project Dropdown again and select your newly created project.

### Step 3: Search and Enable the TTS API
1.  In the search bar at the very top of the Google Cloud console, type: **Text-to-Speech API**.
2.  Click on the search result titled **Cloud Text-to-Speech API**.
3.  Click the blue **Enable** button.
4.  Wait for the page to load the API Dashboard. The service is now active in your project!

---

## 3. Expected Outcome
The page will reload and show a dashboard with graphs for "Traffic," "Errors," and "Latency," indicating the Text-to-Speech API is successfully active and waiting for request calls.

Once this is enabled, proceed to **[Lesson 3: Generating Service Account Keys](file:///Users/junaid/Desktop/AT/Announcement-system/gcp_tts_getting_started/lesson3_service_accounts.md)**!
