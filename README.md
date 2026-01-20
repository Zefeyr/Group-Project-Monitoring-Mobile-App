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
*Insert app title here*

### **b. Background of the Problem**
Explain:
- What problem exists?
- Why is it important?
- How does it affect users?

### **c. Purpose / Objective**
Explain:
- What the app aims to achieve  
- The goals of the system  
- Expected outcomes  

### **d. Target Users**
Describe your primary audience:
- Age group  
- Field / profession  
- User needs  
- Usage environment  

### **e. Preferred Platform**
Specify:
- Android / iOS / Wearables  
- Why this platform?  
- Why Flutter is chosen (if applicable)  

### **f. Features & Functionalities**
List and explain the main features:
- Feature 1 — what & why  
- Feature 2 — what & why  
- Feature 3 — what & why  

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
Explain:
- Backend structure  
- Database design (CRUD operations)  
- Data storage selection  
- Security considerations  

### **a. Platform Compatibility**
Describe:
- Compatibility with smartphones  
- Compatibility with wearables (if any)  
- OS-level constraints  

### **b. Logical Design**
- **Sequence Diagram**
The system uses a reactive pattern where Firestore updates trigger Cloud Functions to update the Accountability Score and notify peers via Firebase Cloud Messaging (FCM).
<img width="8192" height="3371" alt="sequencedigram" src="https://github.com/user-attachments/assets/28126500-66e2-46c2-ae49-2754b98bd85a" />
<p align="center">
    Figure 2.1.1 Sequence Diagram
</p>

- **Screen Navigation Flow Diagram**
The app utilizes a Bottom Navigation Bar for its primary features (Tasks, Chat, Review, and Check-in). The Dashboard serves as the central entry point, providing a summary of project health and the "Beep" status of other members.
<img width="987" height="529" alt="navflow" src="https://github.com/user-attachments/assets/ab201f08-4382-4ef3-8e8a-89ce81cc0833" />
<p align="center">
    Figure 2.1.2 Screen Navigation Flow
</p>


*(Insert images using Markdown:)*  


markdown
Copy code

## **2.2 Project Planning**

### **a. Gantt Chart & Timeline**
Stages that must be included:
- Project Initiation  
- Requirement Analysis  
- Design  
- Development  

Include a Gantt chart (image or table).

*(Example placeholder)*  

yaml
Copy code

Specify:
- Start date (Today)  
- End date (Group project presentation date)

---

# 🎨 3. Project Design

## **3.1 User Interface (UI)**
Explain how the UI follows mobile app design principles:
- Small screen optimization  
- Flutter widgets  
- Gesture support (swipe, tap, long press)

Include screenshots or mockups:

markdown
Copy code

## **3.2 User Experience (UX)**
Explain:
- Navigation flow  
- Ease of use  
- Avoiding confusion  
- Consistency in design  

## **3.3 Consistency**
Describe consistency in:
- Color scheme  
- Logo usage  
- Design patterns  
- Forms  
- Layout styles  

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
> Add references used in the project here…
