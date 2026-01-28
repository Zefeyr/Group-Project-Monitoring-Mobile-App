# Group-Project-Monitoring-Mobile-App
An app that helps with organizing your group project and connect with other members. Example features; beep others, tracking, reminder, push notification, review others work, use sensors, utilize Bluetooth for f2f meeting

# 📌 Group Information

## i. Group Name
**Group Name:** *X*

---

## ii. Group Member Details (Name & Matric No.)

| No. | Name                                          | Matric Number  | 
|-----|-----------------------------------------------|----------------|
| 1   | Ahmad Nur Zafran Shah Bin Ahmad Shahrizal (L) | 2213645        |     
| 2   | Danish Haikal bin Mohammad                    | 2219885        | 
| 3   | Ahmad Zulfahmi Bin Zainal                     | 2219235        | 
| 4   | Ahmad Hakimi Bin Adnan                        | 2212529        | 

---

## iii. Task Distribution

| Stage | Zafran | Hakimi | Zul | Danish |
|-------|--------|--------|-----|--------|
| **Project Ideation & Initiation** | Draft app title & background of the problem | Write purpose/objectives & target user | Define preferred platform & features/functionalities | Justification: why & how the app idea was selected |
| **Requirement Analysis & Planning** | Evaluate technical feasibility & CRUD operations | Plan backend structure & select packages/plugins | Ensure platform compatibility & database structure | Create sequence diagram & screen navigation flow |
| **Planning (Gantt Chart & Timeline)** | Gantt chart: Project Initiation stage | Gantt chart: Requirement Analysis stage | Gantt chart: Design stage | Gantt chart: Development & Presentation stage |
| **Project Design (UI/UX & Consistency)** | Design Home screen & Login screen UI | Design Main Feature screens UI | Apply UX principles: navigation flow & intuitiveness | Ensure consistency: color scheme, logo, forms, design patterns |

> **Note:** Everyone is responsible for reviewing and refining each other's work to maintain quality and balance.


# 📁 Project Documentation

# 🚀 1. Project Ideation & Initiation

## **1.1 Mobile App Details**

### **a. Title**
**CollabQuest: The Project Hub**

### **b. Background of the Problem**
Explain:
- The Problem: Many students face "social loafing" where some members contribute less than others, coupled with scattered communication across multiple apps.
- Importance: Group projects are critical for academic success, but poor coordination leads to last-minute stress and unfair grading.
- User Impact: Leads to frustration, lack of clear visibility on project progress, and administrative overhead.

### **c. Objective**
- To streamline group project management by improving communication and collaboration among team members through features like real time notifications, task tracking, peer reviews, and location based meeting assistance.  
- To enhance the efficiency and effectiveness of group project collaboration by providing tools for real time communication, task management, reminders, peer feedback, and in person coordination through sensors and Bluetooth.  

### **d. Target Users**
- Students working on group projects in colleges or universities.
- Remote and hybrid teams needing efficient collaboration tools.
- Anyone involved in small project-based teams who require reminders, task tracking, and easy coordination.

### **e. Preferred Platform**
Platform: Android and iOS

Why: Targets the widest possible user base (students) who use smartphones for daily communication and quick task management.
Why Flutter: Chosen for cross-platform development from a single codebase, which minimizes development time and costs while delivering native performance on both Android and iOS.  

### **f. Features & Functionalities**
List and explain the main features:
*   **Task Tracking & Status Updates:** Displays tasks, deadlines, and current status.
*   **Real-time Communication & "Beep":** In-app chat with an urgent, high-priority "beep" via push notification.
*   **Collaborative Review System:** Allows members to upload work for others to provide structured ratings and feedback.
*   **Location-Based Check-in (Optional):** Uses Bluetooth/GPS to verify attendance at physical group meetings.

## **1.2 Justification of the Proposed App**
The proposed app which is Group Project Monitoring App is conceived to solved such problems in students and team collaboration which is focusing on simplicity and accountability.
Describe clearly:
- **Why** the app idea was selected
    -The app was selected to address a specific solution to uneven workload distribution and scattered communication in group project.  
- **How** the idea came up
    - The idea was first came up when the lecture came along with a great idea about group project monitoring application which is kind of interesting. Also, the concept arise from lot of students frustation which is lack of clear and real time visibility into who is doing what, leading to last minute group project.  
- Existing solutions and gaps
    - Some of applications and websites already exist to solve this problem such as Trello, Asana and Jira. These existing applications offer robust, enterprise-grade tracking, reporting and integrations. The existing solutions are powerful enough but also create some significant barriers for students. These applications are typically overprice and higly cost for students.  
- What makes your idea needed / unique  
    - Our app is a specialized solution that is genuinely needed because it focuses on a niche underserved by complex enterprise software. 
    Core Unique Feature: Accountability Score/Visualization. This feature calculates and displays an individual's contribution based on timely task completion and peer feedback, providing instant, objective data for group members and instructors.
    Needed Because: It is a mobile-first, low-friction tool designed specifically for short-term, academic collaboration, allowing groups to onboard and begin monitoring work in minutes, directly solving the problem of social loafing and administrative overhead.
---

# 📊 2. Requirement Analysis & Planning

## **2.1 Technical Feasibility**

### **Backend Structure & Plugin Selection**
#### **1. Backend Components**
* **Database (Cloud Firestore):** A **NoSQL** database that stores data in flexible documents. This will handle the storage for `Users`, `Projects`, `Tasks`, and `Reviews` collections, allowing for real-time updates without manual refreshing.
* **Authentication (Firebase Auth):** Provides secure identity management, supporting **Email/Password** and **Google Sign-In** protocols to ensure user data privacy.
* **Cloud Logic (Firebase Cloud Functions):** A serverless framework that executes backend code in response to events (e.g., updating the **Accountability Score** automatically when a task is marked as "Complete").
* **Push Notifications (FCM):** Utilizes **Firebase Cloud Messaging** to power the high-priority **"Beep"** feature, ensuring members are alerted of urgent requests even when the app is in the background.

#### **2. Security & Encryption Implementation**
To maintain intellectual honesty and data privacy, the following security protocols are implemented:
* **End-to-End Encryption (E2EE):** Chat messages and peer review comments are encrypted locally using the **AES-256** algorithm before being sent to Firestore. Only authorized project members hold the decryption keys.
* **Transport Security:** All data in transit is protected via **TLS (Transport Layer Security)**.
* **Access Control:** **Firestore Security Rules** are configured to restrict data access, ensuring users can only view or edit documents within their assigned project groups.

#### **3. Selected Packages & Plugins**
The following **Flutter/Dart** packages have been selected to bridge the app's frontend with its backend infrastructure:

| Category | Package Name | Purpose |
| :--- | :--- | :--- |
| **Core** | `firebase_core` | Mandatory for initializing all Firebase services. |
| **Database** | `cloud_firestore` | Enables real-time data streaming and NoSQL operations. |
| **Auth** | `firebase_auth` | Manages user registration, login, and session persistence. |
| **Messaging** | `firebase_messaging` | Handles incoming and outgoing push notifications for "Beeps." |
| **Logic** | `cloud_functions` | Allows the app to trigger server-side scripts for scoring logic. |
| **State Management** | `provider` | Ensures a reactive UI that updates instantly when backend data changes. |
| **Security** | `encrypt` | Implements **AES-256 encryption** for the Peer Review and Chat content. |

### **a. Platform Compatibility**
Describe:
- **Compatibility with smartphones**: 
  - **Android**: Fully compatible with Android devices running Android 5.0 (Lollipop) or higher.
  - **iOS**: Fully compatible with iPhone devices running iOS 13.0 or higher.
- **Compatibility with wearables**: 
  - Not currently compatible with Wear OS or Apple Watch.
- **OS-level constraints**: 
  - **iOS**: Requires iOS 13.0+ due to deployment target settings.
  - **Android**: Requires Google Play Services for location-based features (if applicable).
  - **Permissions**: Requires Camera, Location, and Storage permissions for full functionality.

### **b. Database Structure**
The application uses **Cloud Firestore (NoSQL)** for real-time collaboration and data synchronization.

**Collections & Schema:**
- **Users** (`users/{userId}`): Stores user profiles (Student/Lecturer), email, and display name.
- **Projects** (`projects/{projectId}`): Stores project metadata, members list, and overall progress.
- **Tasks** (`projects/{projectId}/tasks/{taskId}`): Sub-collection within projects storing task details, assignee, status, and due date.
- **Chat** (`projects/{projectId}/chat/{messageId}`): Sub-collection for group messages, timestamps, and sender IDs.




### **c. Logical Design**
- **Sequence Diagram**
The system uses a reactive pattern where Firestore updates trigger Cloud Functions to update the Accountability Score and notify peers via Firebase Cloud Messaging (FCM).
<img width="8192" height="3371" alt="sequencedigram" src="https://github.com/user-attachments/assets/28126500-66e2-46c2-ae49-2754b98bd85a" />
<p align="center">
    Figure 2.1.1 Sequence Diagram
</p>

- **Screen Navigation Flow Diagram**
The app utilizes a Bottom Navigation Bar for its primary features (Tasks, Chat, Review, and Check-in). The Dashboard serves as the central entry point, providing a summary of project health and the "Beep" status of other members.
<img width="987" height="493" alt="navflow" src="https://github.com/user-attachments/assets/56f47c43-f959-4575-b376-912b6363d39a" />
<p align="center">
    Figure 2.1.2 Screen Navigation Flow
</p>



## **2.2 Project Planning**

### **a. Gantt Chart & Timeline**
| Task | Duration | Start Date | End Date |
|-------|----------|------------|----------|
| Project Initiation | 2 Weeks | Jan 20, 2026 | Feb 3, 2026 |
- Requirement Analysis  
- Design  
- Development  

* **Start Date:** January 20, 2026
* **End Date:** ##########JANGAN LUPA EJAS (Presentation Date)

---

# 🎨 3. Project Design

## **3.1 User Interface (UI)**
* **Optimization:** Optimized for small screens using Flutter’s flexible layout widgets.
* **Gestures:** Support for swipe-to-delete tasks and long-press to trigger "Beeps."

jangan lupa letak screenshots or mockups: -Design Home screen & Login screen UI(zap)
                                          -Design Main Feature screens UI(kimi


## **3.2 User Experience (UX)**
Explain:
- Navigation flow  
- Ease of use  
- Avoiding confusion  
- Consistency in design  

## **3.3 Consistency**
* **Color Scheme:** Primary Blue for trust, Red for urgent notifications.
* **Design Patterns:** Standardized card views for tasks and uniform button styles throughout.
* **Logo Usage:** The logo should consistently appear in the same location, typically the top-left corner of the navigation bar, to provide a "Home" link.
* **Forms:** Consistency in forms prevents user errors and speeds up data entry for tasks like Work Submission or Login.

Include:

yaml
Copy code

---
# 📚 References
List your references here in any format (APA, IEEE, MLA, etc.).  
Example:

1. [Author], *Title*, Year.  
2. [Website name], Available at: [URL].  
3. [Research paper or article citation].

*Placeholder:*  
1. Google. (2026). *Flutter Documentation*. 
2. Firebase. (2026). *Firestore Security Rules*.
