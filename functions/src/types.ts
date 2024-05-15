
export type ContactRequest = {
  to: string;
  from: string;
  status: "pending" | "accepted" | "declined";
}
