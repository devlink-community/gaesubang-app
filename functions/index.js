const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// FCM 토큰 조회 함수
async function getUserFCMTokens(userId) {
  try {
    const tokensSnapshot = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('private')
      .doc('fcmTokens')
      .collection('tokens')
      .where('lastUsed', '>', admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) // 30일 이내
      ))
      .get();
    
    return tokensSnapshot.docs.map(doc => doc.data().token);
  } catch (error) {
    console.error('FCM 토큰 조회 실패:', error);
    return [];
  }
}

// 알림 데이터를 Firestore에 저장
async function saveNotificationToFirestore(notification) {
  try {
    await admin.firestore()
      .collection('notifications')
      .doc(notification.userId)
      .collection('items')
      .add({
        type: notification.type,
        targetId: notification.targetId,
        senderId: notification.senderId,
        senderName: notification.senderName,
        senderProfileImage: notification.senderProfileImage || null,
        title: notification.title,
        body: notification.body,
        data: notification.data,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        readAt: null
      });
    
    console.log('알림 데이터 저장 완료');
  } catch (error) {
    console.error('알림 데이터 저장 실패:', error);
  }
}

// FCM 메시지 전송
async function sendFCMMessage(tokens, notification) {
  try {
    if (tokens.length === 0) {
      console.log('전송할 FCM 토큰이 없습니다.');
      return;
    }

    const message = {
      notification: {
        title: notification.title,
        body: notification.body
      },
      data: {
        type: notification.type,
        targetId: notification.targetId,
        senderId: notification.senderId,
        ...notification.data
      },
      tokens: tokens
    };

    const response = await admin.messaging().sendMulticast(message);
    console.log('FCM 전송 성공:', response.successCount, '건');
    
    if (response.failureCount > 0) {
      console.log('FCM 전송 실패:', response.failureCount, '건');
    }
  } catch (error) {
    console.error('FCM 전송 오류:', error);
  }
}

// 댓글 알림 함수
exports.sendCommentNotification = functions.firestore
  .document('comments/{commentId}')
  .onCreate(async (snapshot, context) => {
    try {
      const commentId = context.params.commentId;
      const commentData = snapshot.data();
      const { postId, userId: commenterId, content } = commentData;
      
      // 게시글 정보 조회
      const postSnapshot = await admin.firestore().collection('posts').doc(postId).get();
      if (!postSnapshot.exists) {
        console.log('게시글을 찾을 수 없습니다:', postId);
        return null;
      }
      
      const postData = postSnapshot.data();
      const postAuthorId = postData.userId;
      
      // 자기 댓글인 경우 알림 전송 안함
      if (commenterId === postAuthorId) {
        console.log('자기 댓글이므로 알림 전송하지 않음');
        return null;
      }
      
      // 댓글 작성자 정보 조회
      const commenterSnapshot = await admin.firestore().collection('users').doc(commenterId).get();
      const commenterData = commenterSnapshot.exists ? commenterSnapshot.data() : null;
      
      if (!commenterData) {
        console.log('댓글 작성자 정보를 찾을 수 없습니다:', commenterId);
        return null;
      }
      
      // 게시글 작성자의 FCM 토큰 조회
      const fcmTokens = await getUserFCMTokens(postAuthorId);
      
      // 알림 데이터 구성
      const notification = {
        userId: postAuthorId,
        type: 'comment',
        targetId: postId,
        senderId: commenterId,
        senderName: commenterData.username || commenterData.nickname || '알 수 없는 사용자',
        senderProfileImage: commenterData.profileImageUrl,
        title: '새 댓글 알림',
        body: `${commenterData.username || '사용자'}님이 회원님의 게시글에 댓글을 남겼습니다: "${content.substring(0, 50)}${content.length > 50 ? '...' : ''}"`,
        data: {
          postId: postId,
          commentId: commentId,
          commentContent: content.substring(0, 100)
        }
      };
      
      // 병렬로 FCM 전송과 Firestore 저장
      await Promise.all([
        sendFCMMessage(fcmTokens, notification),
        saveNotificationToFirestore(notification)
      ]);
      
      return { success: true, notificationType: 'comment' };
      
    } catch (error) {
      console.error('댓글 알림 처리 오류:', error);
      return { error: error.message };
    }
  });

// 좋아요 알림 함수
exports.sendLikeNotification = functions.firestore
  .document('likes/{likeId}')
  .onCreate(async (snapshot, context) => {
    try {
      const likeId = context.params.likeId;
      const likeData = snapshot.data();
      const { postId, userId: likerId } = likeData;
      
      // 게시글 정보 조회
      const postSnapshot = await admin.firestore().collection('posts').doc(postId).get();
      if (!postSnapshot.exists) {
        console.log('게시글을 찾을 수 없습니다:', postId);
        return null;
      }
      
      const postData = postSnapshot.data();
      const postAuthorId = postData.userId;
      
      // 자기 게시글에 좋아요 누른 경우 알림 전송 안함
      if (likerId === postAuthorId) {
        console.log('자기 게시글 좋아요이므로 알림 전송하지 않음');
        return null;
      }
      
      // 좋아요 누른 사용자 정보 조회
      const likerSnapshot = await admin.firestore().collection('users').doc(likerId).get();
      const likerData = likerSnapshot.exists ? likerSnapshot.data() : null;
      
      if (!likerData) {
        console.log('좋아요 누른 사용자 정보를 찾을 수 없습니다:', likerId);
        return null;
      }
      
      // 게시글 작성자의 FCM 토큰 조회
      const fcmTokens = await getUserFCMTokens(postAuthorId);
      
      // 알림 데이터 구성
      const notification = {
        userId: postAuthorId,
        type: 'like',
        targetId: postId,
        senderId: likerId,
        senderName: likerData.username || likerData.nickname || '알 수 없는 사용자',
        senderProfileImage: likerData.profileImageUrl,
        title: '새 좋아요 알림',
        body: `${likerData.username || '사용자'}님이 회원님의 게시글에 좋아요를 눌렀습니다.`,
        data: {
          postId: postId,
          postTitle: postData.title?.substring(0, 50) || '게시글'
        }
      };
      
      // 병렬로 FCM 전송과 Firestore 저장
      await Promise.all([
        sendFCMMessage(fcmTokens, notification),
        saveNotificationToFirestore(notification)
      ]);
      
      return { success: true, notificationType: 'like' };
      
    } catch (error) {
      console.error('좋아요 알림 처리 오류:', error);
      return { error: error.message };
    }
  });

// 좋아요 취소 시 알림 삭제 (선택사항)
exports.removeLikeNotification = functions.firestore
  .document('likes/{likeId}')
  .onDelete(async (snapshot, context) => {
    try {
      const likeData = snapshot.data();
      const { postId, userId: likerId } = likeData;
      
      // 게시글 정보 조회
      const postSnapshot = await admin.firestore().collection('posts').doc(postId).get();
      if (!postSnapshot.exists) {
        return null;
      }
      
      const postData = postSnapshot.data();
      const postAuthorId = postData.userId;
      
      // 해당 좋아요 알림 찾아서 삭제
      const notificationsSnapshot = await admin.firestore()
        .collection('notifications')
        .doc(postAuthorId)
        .collection('items')
        .where('type', '==', 'like')
        .where('targetId', '==', postId)
        .where('senderId', '==', likerId)
        .get();
      
      if (!notificationsSnapshot.empty) {
        const batch = admin.firestore().batch();
        notificationsSnapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
        await batch.commit();
        console.log('좋아요 취소로 인한 알림 삭제 완료');
      }
      
      return { success: true, action: 'notification_removed' };
      
    } catch (error) {
      console.error('좋아요 알림 삭제 오류:', error);
      return { error: error.message };
    }
  });

