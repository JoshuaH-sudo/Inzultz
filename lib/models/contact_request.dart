class ContactRequest {
  final String senderId;
  final String receiverId;
  final String status;

  ContactRequest({
    required this.senderId,
    required this.receiverId,
    required this.status,
  });
}