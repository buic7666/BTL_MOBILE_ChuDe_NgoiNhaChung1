export type Expense = {
  amount: number;
  payer: string;
  splitMode?: string;
  splitDetails?: { percent?: number; memberId?: string } | null;
  selectedMembers?: string[] | null;
};

export type Settlements = Record<string, number>; // memberId -> delta

const members = ["you", "an", "binh", "chi"]; // TODO: dynamic members per house

export function normalizeId(raw: string): string {
  const s = raw.toLowerCase();
  if (s.includes("ban") || s.includes("bạn")) return "you";
  if (s.includes("an")) return "an";
  if (s.includes("binh") || s.includes("bình")) return "binh";
  if (s.includes("chi")) return "chi";
  return s;
}

export function computeNetBalances(expenses: Expense[], settlements?: Settlements): Record<string, number> {
  const net: Record<string, number> = Object.fromEntries(members.map(m => [m, 0]));

  for (const e of expenses) {
    const amount = typeof e.amount === "number" ? e.amount : 0;
    const payer = normalizeId(String(e.payer ?? ""));
    const splitRaw = String(e.splitMode ?? "");

    const shares: Record<string, number> = Object.fromEntries(members.map(m => [m, 0]));

    if (splitRaw.includes("percent")) {
      const sd = e.splitDetails ?? {};
      const pct = typeof sd.percent === "number" ? sd.percent : Number(sd.percent ?? 0);
      const pctMember = normalizeId(String(sd.memberId ?? ""));
      const percentAmount = amount * (pct / 100.0);
      const others = members.filter(m => m !== pctMember);
      const perOther = others.length ? ((amount - percentAmount) / others.length) : 0.0;
      for (const m of members) {
        shares[m] = m === pctMember ? percentAmount : perOther;
      }
    } else if (splitRaw.includes("perPerson") || (e.selectedMembers && e.selectedMembers.length)) {
      const selected = (e.selectedMembers ?? []).map(x => normalizeId(String(x))).filter(x => members.includes(x));
      // Include payer as a participant unless already present, so split counts payer's share too.
      const participants = new Set<string>(selected);
      if (payer) participants.add(payer);
      const use = participants.size ? Array.from(participants) : members;
      const sc = use.length || 1;
      const perShare = amount / sc;
      for (const m of members) {
        shares[m] = use.includes(m) ? perShare : 0.0;
      }
    } else {
      const per = amount / members.length;
      for (const m of members) {
        shares[m] = per;
      }
    }

    if (payer === "you") {
      for (const m of members) {
        if (m === "you") continue;
        net[m] = (net[m] ?? 0) + (shares[m] ?? 0);
      }
    } else {
      const youShare = shares["you"] ?? 0;
      net[payer] = (net[payer] ?? 0) - youShare;
    }
  }

  if (settlements) {
    for (const [id, delta] of Object.entries(settlements)) {
      net[id] = (net[id] ?? 0) + (typeof delta === "number" ? delta : 0);
    }
  }

  return net;
}
