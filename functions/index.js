const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Admin SDK 초기화 - 권한 문제 해결
admin.initializeApp();

// FCM 토큰 조회 함수 - 에러 처리 강화
async function getUserFCMTokens(userId) {
  try {
    console.log('FCM 토큰 조회 시작:', userId);
    
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
    
    const tokens = tokensSnapshot.docs.map(doc => doc.data().token).filter(token => token);
    console.log('FCM 토큰 조회 완료:', tokens.length, '개');
    
    return tokens;
  } catch (error) {
    console.error('FCM 토큰 조회 실패:', error);
    return [];
  }
}

// 알림 데이터를 Firestore에 저장 - 에러 처리 강화
async function saveNotificationToFirestore(notification) {
  try {
    console.log('알림 저장 시작:', notification.userId);
    
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

// FCM 메시지 전송 - 최신 API 사용
async function sendFCMMessage(tokens, notification) {
  try {
    if (tokens.length === 0) {
      console.log('전송할 FCM 토큰이 없습니다.');
      return;
    }

    console.log('FCM 전송 시작:', tokens.length, '개 토큰');

    // 각 토큰에 대해 개별 메시지 생성
    const messages = tokens.map(token => ({
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
      token: token,
      // Android 설정
      android: {
        notification: {
          sound: 'default',
          priority: 'high',
          channelId: 'high_importance_channel'
        }
      },
      // iOS APNS 설정
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    }));

    // sendEach 메서드 사용 (최신 방식)
    const response = await admin.messaging().sendEach(messages);
    
    console.log('FCM 전송 완료');
    console.log('성공:', response.successCount, '건');
    console.log('실패:', response.failureCount, '건');
    
    // 실패한 토큰들 로그 출력
    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error && resp.error.code ? resp.error.code : 'unknown';
          const errorMessage = resp.error && resp.error.message ? resp.error.message : 'unknown error';
          console.error(`토큰 ${idx} 전송 실패:`, errorCode, errorMessage);
          
          // 만료된 토큰이나 잘못된 토큰인 경우 로그 출력
          if (errorCode === 'messaging/invalid-registration-token' ||
              errorCode === 'messaging/registration-token-not-registered') {
            console.log('만료된 토큰 감지:', tokens[idx]);
          }
        }
      });
    }
    
    return response;
  } catch (error) {
    console.error('FCM 전송 오류:', error);
    console.error('오류 상세:', error.message);
    throw error;
  }
}

// 댓글 알림 함수 - 에러 처리 강화
exports.sendCommentNotification = functions.firestore
  .document('posts/{postId}/comments/{commentId}')
  .onCreate(async (snapshot, context) => {
    try {
      console.log('=== 댓글 알림 함수 시작 ===');
      
      const postId = context.params.postId;
      const commentId = context.params.commentId;
      const commentData = snapshot.data();
      
      console.log('게시글 ID:', postId);
      console.log('댓글 ID:', commentId);
      console.log('댓글 데이터:', commentData);
      
      const { userId: commenterId, text: content } = commentData;
      
      if (!commenterId || !content) {
        console.log('댓글 데이터가 불완전합니다:', { commenterId, content });
        return null;
      }
      
      // 게시글 정보 조회
      const postSnapshot = await admin.firestore().collection('posts').doc(postId).get();
      if (!postSnapshot.exists) {
        console.log('게시글을 찾을 수 없습니다:', postId);
        return null;
      }
      
      const postData = postSnapshot.data();
      const postAuthorId = postData.authorId;
      
      console.log('게시글 작성자:', postAuthorId);
      console.log('댓글 작성자:', commenterId);
      
      // 자기 댓글인 경우 알림 전송 안함
      if (commenterId === postAuthorId) {
        console.log('자기 댓글이므로 알림 전송하지 않음');
        return null;
      }
      
      // 댓글 작성자 정보 조회
      const commenterSnapshot = await admin.firestore().collection('users').doc(commenterId).get();
      if (!commenterSnapshot.exists) {
        console.log('댓글 작성자 정보를 찾을 수 없습니다:', commenterId);
        return null;
      }
      
      const commenterData = commenterSnapshot.data();
      
      // 게시글 작성자의 FCM 토큰 조회
      const fcmTokens = await getUserFCMTokens(postAuthorId);
      
      // 알림 데이터 구성
      const notification = {
        userId: postAuthorId,
        type: 'comment',
        targetId: postId,
        senderId: commenterId,
        senderName: commenterData.nickname || '알 수 없는 사용자',
        senderProfileImage: commenterData.image,
        title: '새 댓글 알림',
        body: `${commenterData.nickname || '사용자'}님이 회원님의 게시글에 댓글을 남겼습니다: "${content.substring(0, 50)}${content.length > 50 ? '...' : ''}"`,
        data: {
          postId: postId,
          commentId: commentId,
          commentContent: content.substring(0, 100)
        }
      };
      
      console.log('알림 데이터 구성 완료:', notification);
      
      // 병렬로 FCM 전송과 Firestore 저장
      await Promise.all([
        sendFCMMessage(fcmTokens, notification),
        saveNotificationToFirestore(notification)
      ]);
      
      console.log('=== 댓글 알림 함수 완료 ===');
      return { success: true, notificationType: 'comment' };
      
    } catch (error) {
      console.error('=== 댓글 알림 처리 오류 ===');
      console.error('에러 상세:', error);
      return { error: error.message };
    }
  });

  // 댓글 좋아요 알림 함수 - 에러 처리 강화
exports.sendCommentLikeNotification = functions.firestore
  .document('posts/{postId}/comments/{commentId}/likes/{userId}')
  .onCreate(async (snapshot, context) => {
    try {
      console.log('=== 댓글 좋아요 알림 함수 시작 ===');
      
      const postId = context.params.postId;
      const commentId = context.params.commentId;
      const likerId = context.params.userId;
      
      console.log('게시글 ID:', postId);
      console.log('댓글 ID:', commentId);
      console.log('좋아요 사용자:', likerId);
      
      const likeData = snapshot.data();
      console.log('좋아요 데이터:', likeData);
      
      // 댓글 정보 조회
      const commentSnapshot = await admin.firestore()
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .get();
        
      if (!commentSnapshot.exists) {
        console.log('댓글을 찾을 수 없습니다:', commentId);
        return null;
      }
      
      const commentData = commentSnapshot.data();
      const commentAuthorId = commentData.userId;
      
      console.log('댓글 작성자:', commentAuthorId);
      console.log('좋아요 누른 사용자:', likerId);
      
      // 자기 댓글에 좋아요 누른 경우 알림 전송 안함
      if (likerId === commentAuthorId) {
        console.log('자기 댓글 좋아요이므로 알림 전송하지 않음');
        return null;
      }
      
      // 좋아요 누른 사용자 정보 조회
      const likerSnapshot = await admin.firestore().collection('users').doc(likerId).get();
      if (!likerSnapshot.exists) {
        console.log('좋아요 누른 사용자 정보를 찾을 수 없습니다:', likerId);
        return null;
      }
      
      const likerData = likerSnapshot.data();
      
      // 댓글 작성자의 FCM 토큰 조회
      const fcmTokens = await getUserFCMTokens(commentAuthorId);
      
      // 알림 데이터 구성
      const notification = {
        userId: commentAuthorId,
        type: 'like',
        targetId: postId, // 게시글로 이동하도록 설정
        senderId: likerId,
        senderName: likerData.nickname || '알 수 없는 사용자',
        senderProfileImage: likerData.image,
        title: '댓글 좋아요 알림',
        body: `${likerData.nickname || '사용자'}님이 회원님의 댓글에 좋아요를 눌렀습니다: "${commentData.text?.substring(0, 30) || ''}${commentData.text?.length > 30 ? '...' : ''}"`,
        data: {
          postId: postId,
          commentId: commentId,
          commentText: commentData.text?.substring(0, 100) || ''
        }
      };
      
      console.log('댓글 좋아요 알림 데이터 구성 완료:', notification);
      
      // 병렬로 FCM 전송과 Firestore 저장
      await Promise.all([
        sendFCMMessage(fcmTokens, notification),
        saveNotificationToFirestore(notification)
      ]);
      
      console.log('=== 댓글 좋아요 알림 함수 완료 ===');
      return { success: true, notificationType: 'comment_like' };
      
    } catch (error) {
      console.error('=== 댓글 좋아요 알림 처리 오류 ===');
      console.error('에러 상세:', error);
      return { error: error.message };
    }
  });

// 댓글 좋아요 취소 시 알림 삭제
exports.removeCommentLikeNotification = functions.firestore
  .document('posts/{postId}/comments/{commentId}/likes/{userId}')
  .onDelete(async (snapshot, context) => {
    try {
      console.log('=== 댓글 좋아요 취소 알림 삭제 시작 ===');
      
      const postId = context.params.postId;
      const commentId = context.params.commentId;
      const likerId = context.params.userId;
      
      // 댓글 정보 조회
      const commentSnapshot = await admin.firestore()
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .get();
        
      if (!commentSnapshot.exists) {
        return null;
      }
      
      const commentData = commentSnapshot.data();
      const commentAuthorId = commentData.userId;
      
      // 해당 댓글 좋아요 알림 찾아서 삭제
      const notificationsSnapshot = await admin.firestore()
        .collection('notifications')
        .doc(commentAuthorId)
        .collection('items')
        .where('type', '==', 'like')
        .where('targetId', '==', postId)
        .where('senderId', '==', likerId)
        .where('data.commentId', '==', commentId)
        .get();
      
      if (!notificationsSnapshot.empty) {
        const batch = admin.firestore().batch();
        notificationsSnapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
        await batch.commit();
        console.log('댓글 좋아요 취소로 인한 알림 삭제 완료');
      }
      
      return { success: true, action: 'comment_like_notification_removed' };
      
    } catch (error) {
      console.error('댓글 좋아요 알림 삭제 오류:', error);
      return { error: error.message };
    }
  });

// 좋아요 알림 함수 - 에러 처리 강화
exports.sendLikeNotification = functions.firestore
  .document('posts/{postId}/likes/{userId}')
  .onCreate(async (snapshot, context) => {
    try {
      console.log('=== 좋아요 알림 함수 시작 ===');
      
      const postId = context.params.postId;
      const likerId = context.params.userId;
      
      console.log('게시글 ID:', postId);
      console.log('좋아요 사용자:', likerId);
      
      // 게시글 정보 조회
      const postSnapshot = await admin.firestore().collection('posts').doc(postId).get();
      if (!postSnapshot.exists) {
        console.log('게시글을 찾을 수 없습니다:', postId);
        return null;
      }
      
      const postData = postSnapshot.data();
      const postAuthorId = postData.authorId;
      
      console.log('게시글 작성자:', postAuthorId);
      
      // 자기 게시글에 좋아요 누른 경우 알림 전송 안함
      if (likerId === postAuthorId) {
        console.log('자기 게시글 좋아요이므로 알림 전송하지 않음');
        return null;
      }
      
      // 좋아요 누른 사용자 정보 조회
      const likerSnapshot = await admin.firestore().collection('users').doc(likerId).get();
      if (!likerSnapshot.exists) {
        console.log('좋아요 누른 사용자 정보를 찾을 수 없습니다:', likerId);
        return null;
      }
      
      const likerData = likerSnapshot.data();
      
      // 게시글 작성자의 FCM 토큰 조회
      const fcmTokens = await getUserFCMTokens(postAuthorId);
      
      // 알림 데이터 구성
      const notification = {
        userId: postAuthorId,
        type: 'like',
        targetId: postId,
        senderId: likerId,
        senderName: likerData.nickname || '알 수 없는 사용자',
        senderProfileImage: likerData.image,
        title: '새 좋아요 알림',
        body: `${likerData.nickname || '사용자'}님이 회원님의 게시글에 좋아요를 눌렀습니다.`,
        data: {
          postId: postId,
          postTitle: postData.title?.substring(0, 50) || '게시글'
        }
      };
      
      console.log('알림 데이터 구성 완료:', notification);
      
      // 병렬로 FCM 전송과 Firestore 저장
      await Promise.all([
        sendFCMMessage(fcmTokens, notification),
        saveNotificationToFirestore(notification)
      ]);
      
      console.log('=== 좋아요 알림 함수 완료 ===');
      return { success: true, notificationType: 'like' };
      
    } catch (error) {
      console.error('=== 좋아요 알림 처리 오류 ===');
      console.error('에러 상세:', error);
      return { error: error.message };
    }
  });

// 좋아요 취소 시 알림 삭제
exports.removeLikeNotification = functions.firestore
  .document('posts/{postId}/likes/{userId}')
  .onDelete(async (snapshot, context) => {
    try {
      console.log('=== 좋아요 취소 알림 삭제 시작 ===');
      
      const postId = context.params.postId;
      const likerId = context.params.userId;
      
      // 게시글 정보 조회
      const postSnapshot = await admin.firestore().collection('posts').doc(postId).get();
      if (!postSnapshot.exists) {
        return null;
      }
      
      const postData = postSnapshot.data();
      const postAuthorId = postData.authorId;
      
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