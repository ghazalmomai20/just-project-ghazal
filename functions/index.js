// Cloud Function: sendVerificationCode
// Runtime: Node.js 20

const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");
const cors = require("cors")({ origin: true });

admin.initializeApp();
// Force redeploy - Updated timestamp: May 4, 2025

exports.sendVerificationCode = onRequest(
  {
    secrets: ["SENDGRID_API_KEY"], // ✅ إضافة هذا السطر فقط
  },
  async (req, res) => {
    return cors(req, res, async () => {
      if (req.method !== "POST") {
        return res.status(405).send("Method Not Allowed");
      }

      const email = req.body.email;
      if (!email) {
        return res.status(400).send("Email is required");
      }

      const code = Math.floor(100000 + Math.random() * 900000).toString();

      try {
        await admin.firestore().collection("otp_codes").doc(email).set({
          code,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 10 * 60 * 1000)
          ),
        });

        // ✅ استخدم السكريت بعد تعريفه
        const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY;
        sgMail.setApiKey(SENDGRID_API_KEY);

        const msg = {
          to: email,
          from: "chatgpyrj@gmail.com", // ✅ تأكد من تفعيله في SendGrid
          subject: "Your Verification Code",
          html: `<p>Your code is <strong>${code}</strong>. It will expire in 10 minutes.</p>`,
        };

        await sgMail.send(msg);
        res.status(200).send({ success: true });
      } catch (err) {
        console.error("❌ Error:", err);
        res.status(500).send("Internal Server Error");
      }
    });
  }
);

exports.sendNotification = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  const { userId, title, body } = req.body;

  if (!userId || !title || !body) {
    return res.status(400).send("userId, title, and body are required");
  }

  try {
    // Get the user's FCM token from Firestore
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const userData = userDoc.data();

    if (!userData || !userData.fcmToken) {
      return res.status(404).send("User not found or missing FCM token");
    }

    const message = {
      token: userData.fcmToken,
      notification: {
        title,
        body,
      },
    };

    await admin.messaging().send(message);
    res.status(200).send({ success: true, message: "Notification sent" });
  } catch (error) {
    console.error("❌ Error sending notification:", error);
    res.status(500).send("Failed to send notification");
  }
});