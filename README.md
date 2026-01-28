# CollabQuest: The Project Hub

An app that helps with organizing your group project and connect with other members. Features include "beeping" others for attention, task tracking, reminders, push notifications, peer reviews, and using sensors/Bluetooth for face-to-meeting meetings.

# 📌 Group Information

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

> **Note:** Everyone is responsible for reviewing and refining each other's work to maintain quality and balance.

# 📁 Project Documentation

# 🚀 1. Project Overview

## **1.1 Mobile App Details**

### **a. Background of the Problem**
* **The Problem:** Many students face "social loafing" where some members contribute less than others, coupled with scattered communication across multiple apps.
* **Importance:** Group projects are critical for academic success, but poor coordination leads to last-minute stress and unfair grading.
* **User Impact:** Leads to frustration, lack of clear visibility on project progress, and administrative overhead.

### **b. Objective**
- To streamline group project management by improving communication and collaboration among team members through features like real-time notifications, task tracking, peer reviews, and location-based meeting assistance.  
- To enhance the efficiency and effectiveness of group project collaboration by providing tools for real-time communication, task management, reminders, peer feedback, and in-person coordination.

### **c. Target Users**
- Students working on group projects in colleges or universities.
- Remote and hybrid teams needing efficient collaboration tools.
- Small project-based teams requiring coordination.

### **d. Platform**
*   **Platform:** Android and iOS (Flutter)
*   **Reasoning:** Cross-platform development from a single codebase minimizes development time while delivering native performance.

### **e. Features & Functionalities**
*   **Task Tracking & Status Updates:** Displays tasks, deadlines, and current status.
*   **Real-time Communication & "Beep":** In-app chat with an urgent, high-priority "beep" via push notification.
*   **Collaborative Review System:** Allows members to upload work for others to provide structured ratings and feedback.
*   **Location-Based Check-in (Optional):** Uses Bluetooth/GPS to verify attendance at physical group meetings.

## **1.2 Justification of the App**
The Group Project Monitoring App is designed to solve collaboration problems by focusing on simplicity and accountability.

*   **Why this app?** To address uneven workload distribution and scattered communication.
*   **The Idea:** Born from the frustration of lack of visibility in group work ("social loafing").
*   **Existing Solutions & Gaps:** Tools like Trello or Jira are often too complex, expensive, or overkill for simple student projects.
*   **Uniqueness:** 
    *   **Accountability Score:** Visualizes individual contribution based on task completion and peer feedback.
    *   **Simplicity:** A mobile-first, low-friction tool designed specifically for short-term, academic collaboration.

---

# 📊 2. Technical Architecture

## **2.1 Backend & Infrastructure**

### **Backend Components**
*   **Database (Cloud Firestore):** NoSQL database for real-time `Users`, `Projects`, `Tasks`, and `Reviews` data.
*   **Authentication (Firebase Auth):** Secure identity management (Email/Password, Google Sign-In).
*   **Cloud Logic (Firebase Cloud Functions):** Serverless backend code (e.g., updating Accountability Scores).
*   **Push Notifications (FCM):** Powers the "Beep" feature.

### **Security & Privacy**
*   **Encryption:** Chat messages and peer reviews are encrypted.
*   **Transport Security:** TLS for data in transit.
*   **Access Control:** Firestore Security Rules restrict access to project members only.

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

## **2.2 Database Structure (Firestore)**
*   **Users** (`users/{userId}`): Profiles.
*   **Projects** (`projects/{projectId}`): Metadata, members.
*   **Tasks** (`projects/{projectId}/tasks/{taskId}`): Task details.
*   **Chat** (`projects/{projectId}/chat/{messageId}`): Group messages.

## **2.3 Logical Design**

### **Sequence Diagram**
<img width="8192" height="3371" alt="sequencedigram" src="https://github.com/user-attachments/assets/28126500-66e2-46c2-ae49-2754b98bd85a" />
<p align="center">Figure 2.1.1 Sequence Diagram</p>

### **Screen Navigation Flow**
<img width="987" height="493" alt="navflow" src="https://github.com/user-attachments/assets/56f47c43-f959-4575-b376-912b6363d39a" />
<p align="center">Figure 2.1.2 Screen Navigation Flow</p>

---

# 🎨 3. Project Design

## **3.1 User Interface (UI)**
*   **Optimization:** Flexible layouts for various screen sizes.
*   **Gestures:** Swipe-to-delete, long-press actions.

## **3.2 User Experience (UX)**
Designed for intuitive navigation and consistency, ensuring a seamless flow between Tasks, Chat, and Reviews.

## **3.3 Consistency**
*   **Color Scheme:** Primary Blue for trust, Red for urgent notifications.
*   **Design Patterns:** Standardized card views and buttons.
*   **Logo:** Consistent placement for "Home" navigation.

---

# 📚 References
1. Google. (2026). *Flutter Documentation*. 
2. Firebase. (2026). *Firestore Security Rules*.