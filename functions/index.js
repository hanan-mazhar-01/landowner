const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Helper to send FCM notifications to a list of tokens.
 */
async function sendPushToTokens(tokens, title, body, data = {}) {
  if (!tokens || tokens.length === 0) return;
  const validTokens = [...new Set(tokens.filter((t) => typeof t === "string" && t.length > 10))];
  if (validTokens.length === 0) return;

  const payload = {
    tokens: validTokens,
    notification: {
      title,
      body,
    },
    data: {
      ...data,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "landowner_reminders",
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(payload);
    logger.info(`Push sent: ${response.successCount} successful, ${response.failureCount} failed.`);
    response.responses.forEach((r, i) => {
      if (!r.success) logger.warn(`Push to token #${i} failed: ${r.error?.code} ${r.error?.message}`);
    });
  } catch (error) {
    logger.error("Error sending FCM multicast:", error);
  }
}

/**
 * 1. Daily scheduled reminder job at 09:00 AM.
 * Scans all users for overdue rent, expiring documents, and maintenance.
 */
exports.dailyReminderJob = onSchedule(
  {
    schedule: "0 9 * * *",
    timeZone: "Asia/Karachi",
  },
  async (event) => {
    logger.info("Starting LandOwner daily reminder job...");
    const now = new Date();
    const todayStr = now.toISOString().split("T")[0];

    const usersSnap = await db.collection("users").get();
    for (const userDoc of usersSnap.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      const tokens = userData.fcmTokens || [];

      // Current app versions schedule these alerts on the device itself
      // (exact time, works offline) — pushing here would duplicate them.
      if (userData.localReminders === true) continue;

      // A. Check Overdue Rent Charges
      const chargesSnap = await db
        .collection("users")
        .doc(userId)
        .collection("charges")
        .get();

      for (const chargeDoc of chargesSnap.docs) {
        const charge = chargeDoc.data();
        if (charge.paidAt) continue;
        const dueDate = charge.dueDate ? new Date(charge.dueDate) : null;
        if (dueDate && dueDate < now) {
          const daysOverdue = Math.floor((now - dueDate) / (1000 * 60 * 60 * 24));
          const notifId = `alert:overdue:${charge.id}:${todayStr}`;

          // Avoid duplicate alerts for the same day
          const existingNotif = await db
            .collection("users")
            .doc(userId)
            .collection("notifications")
            .doc(notifId)
            .get();

          if (!existingNotif.exists) {
            const title = `⚠️ Overdue Rent Alert`;
            const body = `Rent payment of Rs${charge.amount || 0} is ${daysOverdue} days overdue.`;

            await db
              .collection("users")
              .doc(userId)
              .collection("notifications")
              .doc(notifId)
              .set({
                id: notifId,
                category: "rent",
                title,
                body,
                createdAt: now.toISOString(),
                unread: true,
                critical: true,
                target: `/finance`,
                propertyId: charge.propertyId || "",
              });

            await sendPushToTokens(tokens, title, body, {
              target: `/finance`,
              propertyId: charge.propertyId || "",
            });
          }
        }
      }

      // B. Check Expiring Documents
      const docsSnap = await db
        .collection("users")
        .doc(userId)
        .collection("documents")
        .get();

      for (const dDoc of docsSnap.docs) {
        const docItem = dDoc.data();
        if (docItem.expiry) {
          const expiryDate = new Date(docItem.expiry);
          const diffDays = Math.ceil((expiryDate - now) / (1000 * 60 * 60 * 24));

          // Alert at 30, 15, 7, and 1 day milestones
          if ([30, 15, 7, 1].includes(diffDays)) {
            const notifId = `alert:doc_expiry:${docItem.id}:${diffDays}d`;
            const existingNotif = await db
              .collection("users")
              .doc(userId)
              .collection("notifications")
              .doc(notifId)
              .get();

            if (!existingNotif.exists) {
              const title = `📄 Document Expiring Soon`;
              const body = `${docItem.name || "Document"} expires in ${diffDays} days.`;

              await db
                .collection("users")
                .doc(userId)
                .collection("notifications")
                .doc(notifId)
                .set({
                  id: notifId,
                  category: "documents",
                  title,
                  body,
                  createdAt: now.toISOString(),
                  unread: true,
                  critical: diffDays <= 7,
                  target: `/properties/${docItem.propertyId || ""}`,
                  propertyId: docItem.propertyId || "",
                });

              await sendPushToTokens(tokens, title, body, {
                target: `/properties/${docItem.propertyId || ""}`,
              });
            }
          }
        }
      }
    }

    logger.info("LandOwner daily reminder job finished successfully.");
  }
);

/**
 * 2. Firestore Trigger: push for notifications explicitly flagged `push: true`.
 * In-app alerts written by the app are delivered as device-scheduled local
 * notifications, so they are not pushed again here.
 */
exports.onNotificationCreated = onDocumentCreated(
  "users/{userId}/notifications/{notificationId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const notification = snap.data();
    const userId = event.params.userId;

    if (notification && notification.push === true) {
      const userDoc = await db.collection("users").doc(userId).get();
      const tokens = userDoc.data()?.fcmTokens || [];
      if (tokens.length > 0) {
        await sendPushToTokens(
          tokens,
          notification.title || "LandOwner Alert",
          notification.body || "",
          {
            target: notification.target || "/notifications",
            propertyId: notification.propertyId || "",
          }
        );
      }
    }
  }
);

/**
 * 3. Account deletion (App Store 5.1.1(v)). The app writes
 *    accountDeletions/{uid}; this trigger deletes everything with admin rights,
 *    so the user isn't asked to sign in again. (A Firestore trigger needs no
 *    public invoker, which the organisation policy doesn't allow.)
 *    Order: media → Firestore data → sign-in → the request itself.
 */
exports.onAccountDeletionRequested = onDocumentCreated("accountDeletions/{uid}", async (event) => {
  const uid = event.params.uid;

  // A. Uploaded photos/documents (stored under land_owner/users/{uid}/).
  //    Needs CLOUDINARY_API_KEY / CLOUDINARY_API_SECRET in functions/.env.
  await deleteCloudinaryFolder(uid);

  // B. The profile document and every subcollection under it.
  await db.recursiveDelete(db.collection("users").doc(uid));

  // C. The Firebase Auth user.
  try {
    await admin.auth().deleteUser(uid);
  } catch (e) {
    if (e.code !== "auth/user-not-found") throw e;
  }

  // D. A final sweep: the app may still hold a valid token for a moment and
  //    write a straggler while B ran. Then remove the request itself.
  await new Promise((r) => setTimeout(r, 5000));
  await db.recursiveDelete(db.collection("users").doc(uid));
  await event.data.ref.delete();
  logger.info(`Account ${uid} deleted.`);
});

async function deleteCloudinaryFolder(uid) {
  const cloud = process.env.CLOUDINARY_CLOUD_NAME || "vz6euzlq";
  const key = process.env.CLOUDINARY_API_KEY;
  const secret = process.env.CLOUDINARY_API_SECRET;
  if (!key || !secret) {
    logger.warn("Cloudinary keys not configured; skipping media deletion.");
    return;
  }
  const auth = "Basic " + Buffer.from(`${key}:${secret}`).toString("base64");
  const prefix = encodeURIComponent(`land_owner/users/${uid}/`);
  for (const type of ["image", "raw", "video"]) {
    try {
      const res = await fetch(
        `https://api.cloudinary.com/v1_1/${cloud}/resources/${type}/upload?prefix=${prefix}&invalidate=true`,
        { method: "DELETE", headers: { Authorization: auth } },
      );
      if (!res.ok) logger.warn(`Cloudinary ${type} delete: HTTP ${res.status}`);
    } catch (e) {
      logger.warn(`Cloudinary ${type} delete failed: ${e}`);
    }
  }
}
