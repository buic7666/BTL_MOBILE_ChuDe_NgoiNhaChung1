import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { computeNetBalances, Expense, Settlements } from "./computeNet";

admin.initializeApp();
const db = admin.firestore();

async function recomputeBalances(houseId: string): Promise<void> {
  const expensesSnap = await db.collection("houses").doc(houseId).collection("finance_expenses").get();
  const settlementsSnap = await db.collection("houses").doc(houseId).collection("finance_settlements").get();

  const expenses: Expense[] = expensesSnap.docs.map((d: admin.firestore.QueryDocumentSnapshot) => {
    const data = d.data();
    return {
      amount: Number(data.amount ?? 0),
      payer: String(data.payer ?? ""),
      splitMode: data.splitMode,
      splitDetails: data.splitDetails ?? null,
      selectedMembers: data.selectedMembers ?? null,
    };
  });

  const settlements: Settlements = {};
  for (const d of settlementsSnap.docs) {
    const data = d.data();
    const id = String(data.memberId ?? "");
    const delta = Number(data.delta ?? 0);
    if (!id) continue;
    settlements[id] = (settlements[id] ?? 0) + delta;
  }

  const net = computeNetBalances(expenses, settlements);

  await db.collection("houses").doc(houseId).collection("finance_balances").doc("summary").set({
    net,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

export const onExpenseWrite = functions.firestore
  .document("houses/{houseId}/finance_expenses/{expenseId}")
  .onWrite(async (
    change: functions.Change<admin.firestore.DocumentSnapshot>,
    context: functions.EventContext
  ) => {
    const houseId = context.params.houseId as string;
    if (!houseId) return;
    try {
      await recomputeBalances(houseId);
    } catch (e) {
      console.error("recomputeBalances error (expense):", e);
    }
  });

export const onSettlementWrite = functions.firestore
  .document("houses/{houseId}/finance_settlements/{settlementId}")
  .onWrite(async (
    change: functions.Change<admin.firestore.DocumentSnapshot>,
    context: functions.EventContext
  ) => {
    const houseId = context.params.houseId as string;
    if (!houseId) return;
    try {
      await recomputeBalances(houseId);
    } catch (e) {
      console.error("recomputeBalances error (settlement):", e);
    }
  });
