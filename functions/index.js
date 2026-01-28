/**
 * Cloud Functions for Firebase (Gen 1)
 */

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

// 1. Notify on New Chat Message
exports.sendChatNotification = functions.firestore
    .document("projects/{projectId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
        const messageData = snap.data();
        const projectId = context.params.projectId;

        // Normalize sender email (trim and lowercase)
        const senderEmail = (messageData.senderEmail || "").trim().toLowerCase();
        const text = messageData.text;

        console.log(`New msg from ${senderEmail} in project ${projectId}`);

        // Get Project Data to find members
        const projectDoc = await admin
            .firestore()
            .collection("projects")
            .doc(projectId)
            .get();

        if (!projectDoc.exists) {
            console.log("Project not found");
            return;
        }

        const projectData = projectDoc.data();
        const projectName = projectData.name || "Project";
        const members = projectData.members || [];

        // Robust Filtering: Filter out the sender
        const recipients = members.filter((email) => {
            const normalizedEmail = (email || "").trim().toLowerCase();
            return normalizedEmail !== senderEmail;
        });

        if (recipients.length === 0) {
            console.log("No recipients found (sender likely only member)");
            return;
        }

        // Get Tokens for recipients
        const tokens = [];
        for (const email of recipients) {
            const userSnap = await admin
                .firestore()
                .collection("users")
                .where("email", "==", email)
                .limit(1)
                .get();

            if (!userSnap.empty) {
                const userData = userSnap.docs[0].data();
                if (userData.fcmToken) {
                    tokens.push(userData.fcmToken);
                }
            }
        }

        if (tokens.length === 0) {
            console.log("No valid tokens found for recipients");
            return;
        }

        // Construct the message payload
        const message = {
            notification: {
                title: `${messageData.senderName || senderEmail.split("@")[0]} in ${projectName}`,
                body: text,
            },
            data: {
                type: "chat",
                projectId: projectId,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            tokens: tokens, // Multicast
        };

        try {
            const response = await admin.messaging().sendEachForMulticast(message);
            console.log(
                "Chat notifications sent:",
                response.successCount,
                "successful,",
                response.failureCount,
                "failed."
            );
        } catch (error) {
            console.error("Error sending chat notifications:", error);
        }
    });

// 2. Notify on New Internal Notification (e.g. Beep)
exports.sendGeneralNotification = functions.firestore
    .document("users/{userId}/notifications/{notiId}")
    .onCreate(async (snap, context) => {
        const notiData = snap.data();
        const userId = context.params.userId;

        // Get User Token
        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        if (!userDoc.exists) {
            console.log("User doc not found");
            return;
        }

        const fcmToken = userDoc.data().fcmToken;
        if (!fcmToken) {
            console.log("No FCM token for user");
            return;
        }

        // Construct message payload
        const message = {
            notification: {
                title: notiData.title || "New Notification",
                body: notiData.body || "Check your app for updates.",
            },
            data: {
                type: notiData.type || "general",
                projectId: notiData.projectId || "",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            token: fcmToken, // Single recipient
        };

        try {
            await admin.messaging().send(message);
            console.log("General notification sent to", userId);
        } catch (error) {
            console.error("Error sending general notification:", error);
        }
    });
