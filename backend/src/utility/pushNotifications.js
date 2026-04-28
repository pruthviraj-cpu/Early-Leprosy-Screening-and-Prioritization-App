import admin from "../config/firebase.js";

export const sendPushNotification = async (token, title, body) => {
  const message = {
    notification: {
      title,
      body,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    token,
  };

  try {
    await admin.messaging().send(message);
    console.log("📱 Push sent to token:", token);
  } catch (error) {
    console.error("Push error:", error.message);
  }
};