import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String relatedId = '',
    String senderId = '',
    String senderName = '',
    String senderRole = '',
  }) async {
    if (userId.trim().isEmpty) return;

    await firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'relatedId': relatedId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> notifyUsersByRole({
    required String role,
    required String title,
    required String message,
    required String type,
    String relatedId = '',
    String senderId = '',
    String senderName = '',
    String senderRole = '',
  }) async {
    final snapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .where('isActive', isEqualTo: true)
        .get();

    final batch = firestore.batch();

    for (final doc in snapshot.docs) {
      if (doc.id == senderId) continue;

      final notificationRef = firestore.collection('notifications').doc();

      batch.set(notificationRef, {
        'userId': doc.id,
        'title': title,
        'message': message,
        'type': type,
        'relatedId': relatedId,
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  static Future<void> notifyMessageReceiver({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String messageText,
    required String conversationId,
  }) async {
    if (receiverId.trim().isEmpty) return;
    if (receiverId == senderId) return;

    String cleanMessage = messageText.trim();

    if (cleanMessage.length > 80) {
      cleanMessage = '${cleanMessage.substring(0, 80)}...';
    }

    await createNotification(
      userId: receiverId,
      title: 'New Message',
      message: '$senderName sent you a message: $cleanMessage',
      type: 'message',
      relatedId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
    );
  }

  static Future<void> notifyAnnouncementAudience({
    required String targetAudience,
    required String announcementId,
    required String announcementTitle,
    required String senderId,
    required String senderName,
    required String senderRole,
  }) async {
    final roles = <String>[];

    if (targetAudience == 'All') {
      roles.addAll(['Student', 'Parent', 'Teacher']);
    }

    if (targetAudience == 'Students') roles.add('Student');
    if (targetAudience == 'Parents') roles.add('Parent');
    if (targetAudience == 'Teachers') roles.add('Teacher');
    if (targetAudience == 'Admins') roles.add('Admin');

    for (final role in roles) {
      await notifyUsersByRole(
        role: role,
        title: 'New Announcement',
        message: announcementTitle,
        type: 'announcement',
        relatedId: announcementId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
      );
    }
  }

  static Future<void> notifyCommentReply({
    required String receiverId,
    required String announcementId,
    required String senderId,
    required String senderName,
    required String senderRole,
  }) async {
    if (receiverId.trim().isEmpty) return;
    if (receiverId == senderId) return;

    await createNotification(
      userId: receiverId,
      title: 'New Reply',
      message: '$senderName replied to your comment.',
      type: 'announcement_reply',
      relatedId: announcementId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
    );
  }

  static Future<void> notifyAssignmentToClass({
    required String classId,
    required String assignmentId,
    required String assignmentTitle,
    required String senderId,
    required String senderName,
    required String senderRole,
  }) async {
    if (classId.trim().isEmpty) return;

    final studentsSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('classId', isEqualTo: classId)
        .where('isActive', isEqualTo: true)
        .get();

    final batch = firestore.batch();
    final parentIds = <String>{};

    for (final doc in studentsSnapshot.docs) {
      final data = doc.data();
      final parentId = data['parentId'] ?? '';

      final studentNotificationRef = firestore.collection('notifications').doc();

      batch.set(studentNotificationRef, {
        'userId': doc.id,
        'title': 'New Assignment',
        'message': assignmentTitle,
        'type': 'assignment',
        'relatedId': assignmentId,
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (parentId.toString().isNotEmpty) {
        parentIds.add(parentId.toString());
      }
    }

    for (final parentId in parentIds) {
      final parentNotificationRef = firestore.collection('notifications').doc();

      batch.set(parentNotificationRef, {
        'userId': parentId,
        'title': 'Child Assignment Update',
        'message': assignmentTitle,
        'type': 'assignment',
        'relatedId': assignmentId,
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  static Future<void> notifyPaymentConfirmationToAdmins({
    required String paymentId,
    required String parentId,
    required String parentName,
    required String studentName,
  }) async {
    await notifyUsersByRole(
      role: 'Admin',
      title: 'Payment Confirmation',
      message: '$parentName submitted a payment confirmation for $studentName.',
      type: 'payment_confirmation',
      relatedId: paymentId,
      senderId: parentId,
      senderName: parentName,
      senderRole: 'Parent',
    );
  }

  static Future<void> notifyPaymentDecisionToParent({
    required String parentId,
    required String paymentId,
    required String status,
    required String adminId,
    required String adminName,
  }) async {
    await createNotification(
      userId: parentId,
      title: 'Payment $status',
      message: 'Your payment confirmation was marked as $status.',
      type: 'payment_decision',
      relatedId: paymentId,
      senderId: adminId,
      senderName: adminName,
      senderRole: 'Admin',
    );
  }

  static Future<void> markAsRead(String notificationId) async {
    if (notificationId.trim().isEmpty) return;

    await firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markAllAsRead(String userId) async {
    if (userId.trim().isEmpty) return;

    final snapshot = await firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  static Future<void> deleteNotification(String notificationId) async {
    if (notificationId.trim().isEmpty) return;

    await firestore.collection('notifications').doc(notificationId).delete();
  }
}