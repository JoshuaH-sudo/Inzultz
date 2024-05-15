
export type ContactRequest = {
  senderId: string;
  receiverId: string;
  status: "pending" | "accepted" | "declined";
  updateAt: number;
}
