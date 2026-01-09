class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
}
