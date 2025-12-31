import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// ================= TRIGGER: XỬ LÝ THÊM CHI PHÍ =================

/**
 * Lắng nghe khi expense_requests được tạo
 * Tính toán, ghi expense, và update balances
 */
export const onExpenseRequest = functions.firestore
  .document("houses/{houseId}/expense_requests/{requestId}")
  .onCreate(async (snap, context) => {
    const houseId = context.params.houseId as string;
    const data = snap.data();

    const { paidBy, totalAmount, participants, splitMode, splitDetails, selectedMembers } = data;

    try {
      const participantIds = Object.keys(participants)
        .filter((id: string) => participants[id]);

      if (participantIds.length === 0) {
        console.warn("No participants for expense");
        return;
      }

      const splits = calculateSplitAmounts({
        participantIds,
        payerId: paidBy,
        totalAmount,
        splitMode,
        splitDetails,
        selectedMembers,
      });

      // 1️⃣ Ghi expense vào collection chính
      const expenseRef = db
        .collection("houses")
        .doc(houseId)
        .collection("expenses")
        .doc();

      await expenseRef.set({
        createdBy: data.createdBy || "unknown",
        paidBy: paidBy,
        totalAmount: totalAmount,
        title: data.title || "Chi phí chung",
        participants: participants,
        splitMode: splitMode || "SplitMode.equal",
        splitDetails: splitDetails || {},
        selectedMembers: selectedMembers || [],
        splitAmount: totalAmount / participantIds.length,
        date: data.date || admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2️⃣ Update balances (AI NỢ AI)
      for (const [userId, amount] of Object.entries(splits)) {
        if (amount <= 0) continue;

        const balanceRef = db
          .collection("houses")
          .doc(houseId)
          .collection("balances")
          .doc(userId)
          .collection("debts")
          .doc(paidBy);

        const balanceSnap = await balanceRef.get();
        const currentAmount = balanceSnap.exists ? (balanceSnap.data()?.amount ?? 0) : 0;
        const newAmount = currentAmount + amount;

        await balanceRef.set({
          fromUserId: userId,
          toUserId: paidBy,
          amount: newAmount,
          status: "unpaid",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }

      // 3️⃣ Update expense_requests status (không xóa)
      await snap.ref.update({ status: "processed" });

      console.log(`Expense created: ${expenseRef.id} in house ${houseId}`);
    } catch (error: any) {
      console.error("onExpenseRequest error:", error);
    }
  });

// ================= TRIGGER: XỬ LÝ THANH TOÁN =================

/**
 * Lắng nghe khi payment_requests được tạo
 * Lấy balance, ghi payment_logs, xóa balance
 */
export const onPaymentRequest = functions.firestore
  .document("houses/{houseId}/payment_requests/{requestId}")
  .onCreate(async (snap, context) => {
    const houseId = context.params.houseId as string;
    const data = snap.data();

    const { from, to } = data;

    try {
      const balanceRef = db
        .collection("houses")
        .doc(houseId)
        .collection("balances")
        .doc(from)
        .collection("debts")
        .doc(to);

      const balanceSnap = await balanceRef.get();
      if (!balanceSnap.exists) {
        console.warn(`Balance not found: ${from} -> ${to}`);
        await snap.ref.delete();
        return;
      }

      const balance = balanceSnap.data();
      const amount = (balance?.amount ?? 0) as number;

      // 1️⃣ Ghi payment_logs
      const paymentRef = db
        .collection("houses")
        .doc(houseId)
        .collection("payment_logs")
        .doc();

      await paymentRef.set({
        from: from,
        to: to,
        amount: amount,
        status: "confirmed",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2️⃣ XÓA balance
      await balanceRef.delete();

      // 3️⃣ Xóa payment_request
      await snap.ref.delete();

      console.log(`Payment processed: ${from} -> ${to} (${amount}) in house ${houseId}`);
    } catch (error: any) {
      console.error("onPaymentRequest error:", error);
    }
  });

// ================= CLOUD FUNCTIONS (OPTIONAL - CALLABLE) =================

/**
 * Callable function nếu cần xử lý trực tiếp
 * (Thay thế cho triggers nếu muốn)
 */
export const addExpense = functions.https.onCall(
  async (data: any, context: functions.https.CallableContext) => {
    const { houseId, paidBy, totalAmount, participants, splitMode, splitDetails, selectedMembers } = data;

    if (!houseId || !paidBy || !totalAmount || !participants) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields"
      );
    }

    if (!context.auth?.uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    try {
      const participantIds = Object.keys(participants).filter((id) => participants[id]);

      if (participantIds.length === 0) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Must have at least 1 participant"
        );
      }

      const splits = calculateSplitAmounts({
        participantIds,
        payerId: paidBy,
        totalAmount,
        splitMode,
        splitDetails,
        selectedMembers,
      });

      // 1️⃣ Ghi expense
      const expenseRef = db
        .collection("houses")
        .doc(houseId)
        .collection("expenses")
        .doc();

      await expenseRef.set({
        createdBy: context.auth.uid,
        paidBy: paidBy,
        totalAmount: totalAmount,
        participants: participants,
        splitMode: splitMode || "SplitMode.equal",
        splitDetails: splitDetails || {},
        selectedMembers: selectedMembers || [],
        splitAmount: totalAmount / participantIds.length,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2️⃣ Update balances
      for (const [userId, amount] of Object.entries(splits)) {
        if (amount <= 0) continue;

        const balanceRef = db
          .collection("houses")
          .doc(houseId)
          .collection("balances")
          .doc(userId)
          .collection("debts")
          .doc(paidBy);

        const balanceSnap = await balanceRef.get();
        const currentAmount = balanceSnap.exists ? (balanceSnap.data()?.amount ?? 0) : 0;
        const newAmount = currentAmount + amount;

        await balanceRef.set({
          fromUserId: userId,
          toUserId: paidBy,
          amount: newAmount,
          status: "unpaid",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }

      console.log(`Expense created: ${expenseRef.id} in house ${houseId}`);
      return { success: true, expenseId: expenseRef.id };
    } catch (error: any) {
      console.error("addExpense error:", error);
      throw new functions.https.HttpsError(
        "internal",
        error.message || "Internal server error"
      );
    }
  }
);

export const processPayment = functions.https.onCall(
  async (data: any, context: functions.https.CallableContext) => {
    const { houseId, from, to } = data;

    if (!houseId || !from || !to) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing houseId, from, or to"
      );
    }

    if (!context.auth?.uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    try {
      if (context.auth.uid !== from && context.auth.uid !== to) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Not authorized"
        );
      }

      const balanceRef = db
        .collection("houses")
        .doc(houseId)
        .collection("balances")
        .doc(from)
        .collection("debts")
        .doc(to);

      const balanceSnap = await balanceRef.get();
      if (!balanceSnap.exists) {
        throw new functions.https.HttpsError("not-found", "Balance not found");
      }

      const balance = balanceSnap.data();
      const amount = (balance?.amount ?? 0) as number;

      // 1️⃣ Ghi payment_logs
      const paymentRef = db
        .collection("houses")
        .doc(houseId)
        .collection("payment_logs")
        .doc();

      await paymentRef.set({
        from: from,
        to: to,
        amount: amount,
        status: "confirmed",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2️⃣ XÓA balance
      await balanceRef.delete();

      console.log(
        `Payment processed: ${from} paid ${to} ${amount} in house ${houseId}`
      );
      return { success: true, paymentId: paymentRef.id };
    } catch (error: any) {
      console.error("processPayment error:", error);
      throw new functions.https.HttpsError(
        "internal",
        error.message || "Internal server error"
      );
    }
  }
);

function calculateSplitAmounts(params: {
  participantIds: string[];
  payerId: string;
  totalAmount: number;
  splitMode?: string;
  splitDetails?: any;
  selectedMembers?: string[];
}): Record<string, number> {
  const {
    participantIds,
    payerId,
    totalAmount,
    splitMode,
    splitDetails,
    selectedMembers,
  } = params;

  const mode = String(splitMode ?? "SplitMode.equal");
  const splits: Record<string, number> = {};

  if (totalAmount <= 0 || participantIds.length === 0) {
    return splits;
  }

  if (mode.includes("percent")) {
    const percent = Number(splitDetails?.percent ?? 0);
    const percentMemberId = String(splitDetails?.memberId ?? "");

    if (percentMemberId) {
      const pctAmount = (totalAmount * percent) / 100;
      if (percentMemberId !== payerId) {
        splits[percentMemberId] = pctAmount;
      }

      const others = participantIds.filter(
        (id) => id !== percentMemberId && id !== payerId,
      );
      const remaining = totalAmount - pctAmount;
      const per = others.length > 0 ? remaining / others.length : 0;
      for (const id of others) {
        splits[id] = per;
      }
    }
  } else if (mode.includes("perPerson")) {
    const targetMembers = (selectedMembers ?? []).filter(
      (id) => id && id !== payerId,
    );
    const use = targetMembers.length > 0
      ? targetMembers
      : participantIds.filter((id) => id !== payerId);

    if (use.length > 0) {
      const per = totalAmount / use.length;
      for (const id of use) {
        splits[id] = per;
      }
    }
  } else {
    const use = participantIds.filter((id) => id !== payerId);
    if (use.length > 0) {
      const per = totalAmount / use.length;
      for (const id of use) {
        splits[id] = per;
      }
    }
  }

  return splits;
}

// ================= PAYMENT FLOW FUNCTIONS =================

/**
 * A (NGƯỜI NỢ) hoặc B (NGƯỜI ĐƯỢC TRẢ) bấm "Đã xử lý"
 * Cả 2 đều bấm rồi mới xóa nợ + ghi log
 */
export const markPaymentSettled = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  const { houseId, fromUserId, toUserId } = data;

  if (!houseId || !fromUserId || !toUserId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required fields");
  }

  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const userId = context.auth.uid;
  
  // Chỉ người nợ hoặc người được trả mới được bấm
  if (userId !== fromUserId && userId !== toUserId) {
    throw new functions.https.HttpsError("permission-denied", "Only involved parties can mark as settled");
  }

  try {
    const ref = db
      .collection("houses").doc(houseId)
      .collection("balances").doc(fromUserId)
      .collection("debts").doc(toUserId);

    const snap = await ref.get();
    if (!snap.exists) {
      throw new functions.https.HttpsError("not-found", "Debt not found");
    }

    const debt = snap.data() as any;

    // Cập nhật: người này đã xác nhận
    const updateData: any = {};
    if (userId === fromUserId) {
      updateData.paidBy = true;
      updateData.paidAt = admin.firestore.FieldValue.serverTimestamp();
    } else {
      updateData.confirmedBy = true;
      updateData.confirmedAt = admin.firestore.FieldValue.serverTimestamp();
    }

    await ref.update(updateData);

    // Kiểm tra xem cả 2 đã bấm chưa
    const updatedSnap = await ref.get();
    const updatedDebt = updatedSnap.data() as any;

    // Nếu cả 2 đều bấm → xóa nợ + ghi log
    if (updatedDebt.paidBy && updatedDebt.confirmedBy) {
      const batch = db.batch();

      // 1. Ghi payment_logs
      const logRef = db
        .collection("houses").doc(houseId)
        .collection("payment_logs").doc();

      batch.set(logRef, {
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: debt.amount,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2. Xóa debt
      batch.delete(ref);

      await batch.commit();

      console.log(`Payment settled: ${fromUserId} → ${toUserId} (${debt.amount}) in house ${houseId}`);
      return { success: true, message: "Payment settled and completed", settled: true };
    } else {
      // Chỉ một bên đã bấm: chuyển trạng thái để UI bỏ khỏi ví người vừa bấm
      await ref.update({
        status: "paying", // đang chờ bên còn lại
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Payment marked: ${fromUserId} → ${toUserId} (waiting for both parties)`);
      return { success: true, message: "Payment confirmed, waiting for the other party", settled: false };
    }
  } catch (error: any) {
    console.error("markPaymentSettled error:", error);
    throw new functions.https.HttpsError("internal", error.message || "Internal server error");
  }
});
