# CollabQuest: The Project Hub

An app that helps with organizing your group project and connect with other members. Features include "beeping" others for attention, task tracking, reminders, push notifications, peer reviews, and using Bluetooth for physical meetings.

# Group Information

## Member Details

| No. | Name                                          | Matric Number  | 
|-----|-----------------------------------------------|----------------|
| 1   | Ahmad Nur Zafran Shah Bin Ahmad Shahrizal (L) | 2213645        |      
| 2   | Danish Haikal bin Mohammad                    | 2219885        | 
| 3   | Ahmad Zulfahmi Bin Zainal                     | 2219235        | 
| 4   | Ahmad Hakimi Bin Adnan                        | 2212529        | 

---

## Task Distribution

| Stage | Zafran | Hakimi | Zul | Danish |
|-------|--------|--------|-----|--------|
| **Project Ideation & Initiation** | Draft app title & background of the problem | Write purpose/objectives & target user | Define preferred platform & features/functionalities | Justification of app selection |
| **Requirement Analysis & Planning** | Evaluate technical feasibility & CRUD operations | Plan backend structure & select packages/plugins | Ensure platform compatibility & database structure | Create sequence diagram & screen navigation flow |
| **Timeline Management** | Project Initiation stage | Requirement Analysis stage | Design stage | Development & Presentation stage |
| **Project Design (UI/UX)** | Design Home screen & Login screen UI | Design Main Feature screens UI | Apply UX principles: navigation flow & intuitiveness | Ensure consistency: color scheme, logo, forms | 
| **Development** | Task page, Chat page (Tasks and Messaging features) | Home page, Project page (Bluetooth meeting, Project Management features) | Notification widget, Profile Page (Peer review, Project history features) | Welcoming Page, Login Page, Sign Up Page (Authentication, Firestore Database) |

# Project Documentation

# 1. Project Overview

## **1.1 Mobile App Details**

### **a. Title**
**CollabQuest: The Project Hub**

### **b. Background of the Problem**
* **The Problem:** Many students face "social loafing" where some members contribute less than others, coupled with scattered communication across multiple apps.
* **Importance:** Group projects are critical for academic success, but poor coordination leads to last-minute stress and unfair grading.
* **User Impact:** Leads to frustration, lack of clear visibility on project progress, and administrative overhead.

### **c. Objective**
- To streamline group project management by improving communication and collaboration among team members through features like real time notifications, task tracking, peer reviews, and location based meeting assistance.  
- To enhance the efficiency and effectiveness of group project collaboration by providing tools for real time communication, task management, reminders, peer feedback, and in person coordination through sensors and Bluetooth.  

### **d. Target Users**
- Students working on group projects in colleges or universities.
- Remote and hybrid teams needing efficient collaboration tools.
- Small project-based teams requiring coordination.

### **e. Platform**
* **Platform:** Android and iOS (Flutter)
* **Reasoning:** Cross-platform development from a single codebase minimizes development time while delivering native performance.

### **f. Features & Functionalities**
* **Task Tracking & Status Updates:** Displays tasks, deadlines, and current status.
* **Real-time Communication & "Beep":** Project task with an urgent, high-priority "beep" via push notification.
* **Collaborative Review System:** Allows members to upload work for others to provide structured ratings and feedback.
* **Location-Based Check-in:** Uses Bluetooth to verify attendance at physical group meetings.

## **1.2 Justification of the App**
The Group Project Monitoring App is designed to solve collaboration problems by focusing on simplicity and accountability.

* **Why this app?** To address uneven workload distribution and scattered communication.
* **The Idea:** Born from the frustration of lack of visibility in group work ("social loafing").
* **Existing Solutions & Gaps:** Tools like Trello or Jira are often too complex, expensive, or overkill for simple student projects.
* **Uniqueness:** * **Accountability Score:** Visualizes individual contribution based on task completion and peer feedback.
* **Simplicity:** A mobile-first, low-friction tool designed specifically for short-term, academic collaboration.

---

# 2. Technical Architecture

## **2.1 Backend & Infrastructure**

### **Backend Components**
* **Database (Cloud Firestore):** NoSQL database for real-time `Users`, `Projects`, `Tasks`, and `Reviews` data.
* **Authentication (Firebase Auth):** Secure identity management (Email/Password, Google Sign-In).
* **Cloud Logic (Firebase Cloud Functions):** Serverless backend code (e.g., updating Accountability Scores).
* **Push Notifications (FCM):** Powers the "Beep" feature.

### **Security & Privacy**
* **Encryption:** Chat messages and peer reviews are encrypted.
* **Transport Security:** TLS for data in transit.
* **Access Control:** Firestore Security Rules restrict access to project members only.

### **Key Packages**
| Package | Purpose |
| :--- | :--- |
| `firebase_core` | Firebase initialization |
| `cloud_firestore` | Real-time Database |
| `firebase_auth` | User Authentication |
| `firebase_messaging` | Push Notifications ("Beep") |
| `cloud_functions` | Serverless Logic |
| `provider` | State Management |
| `encrypt` | AES-256 Encryption |

## **2.2 Platform Compatibility**
Describe:
- **Compatibility with smartphones**: 
  - **Android**: Fully compatible with Android devices running Android 5.0 (Lollipop) or higher (API Level 21+).
  - **iOS**: Fully compatible with iPhone devices running iOS 15.0 or higher.
- **Compatibility with wearables**: 
  - Not currently compatible with Wear OS or Apple Watch.
- **OS-level constraints**: 
  - **iOS**: Requires iOS 15.0+ due to deployment target settings in Podfile.
  - **Android**: Requires Bluetooth Low Energy (BLE) support for the Meeting Check-in features.
  - **Permissions**: Requires Album (for profile picture), Location (for Bluetooth scanning), and Notification permissions.

## 2.3 Database Structure (Firestore)
* **Users** (`users/{userId}`): Stores user profiles.
    * **Notifications** (`users/{userId}/notifications/{notiId}`): User alerts.
* **Projects** (`projects/{projectId}`): Project metadata & members.
    * **Tasks** (`projects/{projectId}/tasks/{taskId}`): Task details.
    * **Messages** (`projects/{projectId}/messages/{messageId}`): Group chat history.
    * **Meetings** (`projects/{projectId}/meetings/{meetingId}`): Bluetooth attendance sessions.
    * **Reviews** (`projects/{projectId}/reviews_data/{reviewId}`): Peer review submissions.
    
## **2.4 Logical Design**

### **Sequence Diagram**
<img width="8192" height="3371" alt="sequencedigram" src="https://github.com/user-attachments/assets/28126500-66e2-46c2-ae49-2754b98bd85a" />
<p align="center">Figure 2.1.1 Sequence Diagram</p>

### **Screen Navigation Flow**
<img width="987" height="493" alt="navflow" src="https://github.com/user-attachments/assets/56f47c43-f959-4575-b376-912b6363d39a" />
<p align="center">
    Figure 2.1.2 Screen Navigation Flow
</p>

## **2.5 Project Planning**

### **a. Gantt Chart & Timeline**
| Task | Duration | Start Date | End Date |
|-------|----------|------------|----------|
| Project Initiation | 2 Weeks | Nov 10, 2025 | Nov 24, 2025 |
| Requirement Analysis | 2 Weeks | Nov 25, 2025 | Dec 8, 2025 |
| Design (UI/UX) | 2 Weeks | Dec 9, 2025 | Dec 23, 2025 |
| Development | 4 Weeks | Dec 24, 2025 | Jan 21, 2026 |
| Testing & Presentation | 1 Weeks | Jan 22, 2026 | Jan 28, 2026 |

* **Start Date:** Nov 10, 2025
* **End Date:** Jan 28, 2026

---

# 3. Project Design

## **3.1 User Interface (UI)**

### **3.1.1 Home Page**
<img width="250" height="500" src="https://github.com/user-attachments/assets/7607b5ea-73d9-4c6f-98f3-e97dea8feedc" width="800" alt="Home Page">
<p> Figure 3.1.1 Home Page</p>

### **3.1.2 Project List Page**
<img width="250" height="500" src="https://github.com/user-attachments/assets/6509aade-fd0e-4450-8cd1-4464578cf212" width="800" alt="Project List">
<p>Figure 3.1.2 Project List Page</p>

### **3.1.3 Task Board**
<img width="250" height="500" src="https://github.com/user-attachments/assets/85437f87-4e3b-4bf1-8dc7-080a14dc9f07" width="800" alt="Task Board">
<p>Figure 3.1.3 Task Board</p>

### **3.1.4 Message**
<img width="250" height="500" src="https://github.com/user-attachments/assets/aaf6af8e-39ea-463c-aaff-c54bf68d8b47" width="800" alt="Message">
<p>Figure 3.1.4 Message</p>

### **3.1.5 Group Message**
<img width="250" height="500" src="https://github.com/user-attachments/assets/829eee74-b40f-444a-b631-186fba8d4e56" width="800" alt="Group Message">
<p>Figure 3.1.5 Group Message</p>

### **3.1.6 Profile**
<img width="250" height="500" src="https://github.com/user-attachments/assets/83134c86-5f99-48e9-b2ca-115c7cd1f5d1" width="800" alt="Notifications">
<p>Figure 3.1.6 Profile Setting</p>

### **3.1.7 Notification**
<img width="250" height="500" src="https://github.com/user-attachments/assets/4404b6c0-1eb3-4097-9fb8-d364969669dd" width="800" alt="Profile">
<p>Figure 3.1.7 Notification</p>


## **3.2 User Experience (UX)**
* **Navigation flow:**
    * **Bottom Navigation Bar:** Provides persistent, one-tap access to primary screens (Home, Tasks, Chat, Profile), reducing clicks for high-frequency actions.
    * **Dashboard-First:** The Home screen aggregates critical data (deadlines, active projects) so users see status immediately upon app launch.
    * **Contextual FABs:** "Create" actions (Project/Task) are accessible via Floating Action Buttons or clear "+" icons, distinct from navigation elements.

* **Ease of use:**
    * **Mobile-First Design:** Buttons and cards are sized for touch targets (min 48px height for buttons).
    * **Smart Defaults:** Forms pre-fill known data (e.g., current user as "Project Lead") to speed up setup.
    * **Task Management:** Simple tap mechanisms to view details, with clear visual indicators for task status (color-coded).

* **Avoiding confusion:**
    * **Empty States:** Screens with no data display helpful illustrations and instruction text (e.g., "No group chats yet") rather than blank screens.
    * **Visual Hierarchy:** "Beeps" (urgent) use Red, while standard info uses Blue, ensuring users prioritize correctly.
    * **Success Feedback:** Snackbars confirm actions (e.g., "Project Created", "Invite code copied"), reassuring users that the system worked.

## **3.3 Consistency**
* **Color Scheme:** Primary Blue for trust, Red for urgent notifications.
* **Design Patterns:** Standardized card views and buttons.
* **Logo:** Consistent placement for "Home" navigation.

---

# References
1. Google. (2026). *Flutter Documentation*. 
2. Firebase. (2026). *Firestore Security Rules*.
