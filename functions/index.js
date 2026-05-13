const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

/**
 * When a buyer creates an order document, notify the seller's device(s).
 * Requires sellers' FCM tokens on `users/{sellerId}.fcmTokens` (array of strings),
 * written by the Flutter app (see lib/push_messaging.dart).
 */
exports.notifySellerNewOrder = onDocumentCreated("orders/{orderId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const order = snap.data();
  const sellerId = order.sellerId;
  if (!sellerId || typeof sellerId !== "string") return;

  const userRef = getFirestore().collection("users").doc(sellerId);
  const userSnap = await userRef.get();
  if (!userSnap.exists) return;

  const raw = userSnap.get("fcmTokens");
  const tokens = Array.isArray(raw) ? raw.filter((t) => typeof t === "string" && t.length > 0) : [];
  if (tokens.length === 0) return;

  const buyerName = (order.buyerName || "A buyer").toString();
  const title = "New order";
  const body = `${buyerName} placed an order. Open UMart to review.`;
  const orderId = event.params.orderId;

  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification: {title, body},
    data: {
      type: "new_order",
      orderId: String(orderId),
    },
    android: {
      notification: {channelId: "umart_orders"},
    },
  });

  const invalid = [];
  res.responses.forEach((r, i) => {
    if (!r.success && r.error) {
      const code = r.error.code;
      if (
        code === "messaging/invalid-registration-token" ||
        code === "messaging/registration-token-not-registered"
      ) {
        invalid.push(tokens[i]);
      }
    }
  });

  if (invalid.length > 0) {
    await userRef.update({
      fcmTokens: FieldValue.arrayRemove(...invalid),
    });
  }
});
