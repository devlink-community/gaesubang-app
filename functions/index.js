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

// === 30일 지난 알림 자동 삭제 (매일 자정 실행) ===
exports.cleanupOldNotifications = functions.pubsub
  .schedule('0 0 * * *') // 매일 자정 (KST)
  .timeZone('Asia/Seoul')
  .onRun(async (context) => {
    try {
      console.log('=== 오래된 알림 정리 시작 ===');
      
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      const thirtyDaysAgoTimestamp = admin.firestore.Timestamp.fromDate(thirtyDaysAgo);
      
      console.log('기준 날짜:', thirtyDaysAgo.toISOString());
      
      let totalDeletedCount = 0;
      let processedUserCount = 0;
      
      // 모든 사용자의 알림 컬렉션 조회
      const notificationsCollectionGroup = admin.firestore().collectionGroup('items');
      const oldNotificationsSnapshot = await notificationsCollectionGroup
        .where('createdAt', '<', thirtyDaysAgoTimestamp)
        .get();
      
      if (oldNotificationsSnapshot.empty) {
        console.log('삭제할 오래된 알림이 없습니다.');
        return { success: true, deletedCount: 0 };
      }
      
      console.log('삭제 대상 알림 수:', oldNotificationsSnapshot.docs.length);
      
      // 배치 단위로 삭제 (Firestore 배치는 최대 500개)
      const batchSize = 500;
      const batches = [];
      
      for (let i = 0; i < oldNotificationsSnapshot.docs.length; i += batchSize) {
        const batch = admin.firestore().batch();
        const batchDocs = oldNotificationsSnapshot.docs.slice(i, i + batchSize);
        
        batchDocs.forEach(doc => {
          batch.delete(doc.ref);
          totalDeletedCount++;
        });
        
        batches.push(batch.commit());
      }
      
      // 모든 배치 실행
      await Promise.all(batches);
      
      console.log('=== 오래된 알림 정리 완료 ===');
      console.log('총 삭제된 알림 수:', totalDeletedCount);
      
      return { 
        success: true, 
        deletedCount: totalDeletedCount,
        processedUsers: processedUserCount,
        cutoffDate: thirtyDaysAgo.toISOString()
      };
      
    } catch (error) {
      console.error('=== 오래된 알림 정리 실패 ===');
      console.error('에러 상세:', error);
      return { error: error.message };
    }
  });

// === FCM 토큰 정리 (매주 일요일 새벽 2시 실행) ===
exports.cleanupExpiredFCMTokens = functions.pubsub
  .schedule('0 2 * * 0') // 매주 일요일 새벽 2시 (KST)
  .timeZone('Asia/Seoul')
  .onRun(async (context) => {
    try {
      console.log('=== 만료된 FCM 토큰 정리 시작 ===');
      
      const ninetyDaysAgo = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
      const ninetyDaysAgoTimestamp = admin.firestore.Timestamp.fromDate(ninetyDaysAgo);
      
      console.log('기준 날짜 (90일 전):', ninetyDaysAgo.toISOString());
      
      let totalDeletedTokens = 0;
      let processedUserCount = 0;
      
      // 모든 사용자 조회
      const usersSnapshot = await admin.firestore().collection('users').get();
      
      console.log('검사할 사용자 수:', usersSnapshot.docs.length);
      
      for (const userDoc of usersSnapshot.docs) {
        try {
          const userId = userDoc.id;
          
          // 만료된 FCM 토큰 조회
          const expiredTokensSnapshot = await admin.firestore()
            .collection('users')
            .doc(userId)
            .collection('private')
            .doc('fcmTokens')
            .collection('tokens')
            .where('lastUsed', '<', ninetyDaysAgoTimestamp)
            .get();
          
          if (!expiredTokensSnapshot.empty) {
            const batch = admin.firestore().batch();
            
            expiredTokensSnapshot.docs.forEach(tokenDoc => {
              batch.delete(tokenDoc.ref);
              totalDeletedTokens++;
            });
            
            await batch.commit();
            
            console.log(`사용자 ${userId}: ${expiredTokensSnapshot.docs.length}개 만료된 토큰 삭제`);
          }
          
          processedUserCount++;
          
          // 너무 많은 사용자를 한번에 처리하지 않도록 제한
          if (processedUserCount % 100 === 0) {
            console.log(`진행 상황: ${processedUserCount}/${usersSnapshot.docs.length} 사용자 처리 완료`);
          }
          
        } catch (userError) {
          console.error(`사용자 ${userDoc.id} FCM 토큰 정리 실패:`, userError.message);
          // 개별 사용자 실패는 전체 프로세스를 중단하지 않음
        }
      }
      
      console.log('=== 만료된 FCM 토큰 정리 완료 ===');
      console.log('총 삭제된 토큰 수:', totalDeletedTokens);
      console.log('처리된 사용자 수:', processedUserCount);
      
      return { 
        success: true, 
        deletedTokens: totalDeletedTokens,
        processedUsers: processedUserCount,
        cutoffDate: ninetyDaysAgo.toISOString()
      };
      
    } catch (error) {
      console.error('=== FCM 토큰 정리 실패 ===');
      console.error('에러 상세:', error);
      return { error: error.message };
    }
  });
// === 사용자 통계 업데이트 (매일 새벽 1시 실행) ===
exports.updateUserStatistics = functions.pubsub
  .schedule('0 1 * * *') // 매일 새벽 1시 (KST)
  .timeZone('Asia/Seoul')
  .onRun(async (context) => {
    try {
      console.log('=== 사용자 통계 업데이트 시작 ===');
      
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      yesterday.setHours(0, 0, 0, 0);
      
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      const yesterdayTimestamp = admin.firestore.Timestamp.fromDate(yesterday);
      const todayTimestamp = admin.firestore.Timestamp.fromDate(today);
      
      console.log('어제 날짜:', yesterday.toISOString());
      console.log('오늘 날짜:', today.toISOString());
      
      let processedUserCount = 0;
      let updatedUserCount = 0;
      
      // 모든 사용자 조회
      const usersSnapshot = await admin.firestore().collection('users').get();
      
      for (const userDoc of usersSnapshot.docs) {
        try {
          const userId = userDoc.id;
          const userData = userDoc.data();
          
          // 어제의 타이머 활동 조회
          const activitiesSnapshot = await admin.firestore()
            .collection('users')
            .doc(userId)
            .collection('timerActivities')
            .where('timestamp', '>=', yesterdayTimestamp)
            .where('timestamp', '<', todayTimestamp)
            .orderBy('timestamp')
            .get();
          
          // 🔧 개선된 집중 시간 계산 (resume 포함)
          const dailyFocusMinutes = calculateDailyFocusTime(activitiesSnapshot.docs);
          
          // 연속 학습일 계산
          let newStreakDays = userData.streakDays || 0;
          
          if (dailyFocusMinutes >= 30) { // 최소 30분 집중해야 연속일로 인정
            newStreakDays += 1;
          } else {
            newStreakDays = 0; // 연속 중단
          }
          
          // 사용자 정보 업데이트 (변경사항이 있는 경우에만)
          if (newStreakDays !== (userData.streakDays || 0)) {
            await admin.firestore()
              .collection('users')
              .doc(userId)
              .update({
                streakDays: newStreakDays,
                lastActivityDate: admin.firestore.FieldValue.serverTimestamp()
              });
            
            updatedUserCount++;
            
            console.log(`사용자 ${userId}: 연속일 ${userData.streakDays || 0} → ${newStreakDays} (어제 집중시간: ${dailyFocusMinutes}분)`);
          }
          
          processedUserCount++;
          
        } catch (userError) {
          console.error(`사용자 ${userDoc.id} 통계 업데이트 실패:`, userError.message);
        }
      }
      
      console.log('=== 사용자 통계 업데이트 완료 ===');
      console.log('처리된 사용자 수:', processedUserCount);
      console.log('업데이트된 사용자 수:', updatedUserCount);
      
      return { 
        success: true, 
        processedUsers: processedUserCount,
        updatedUsers: updatedUserCount,
        date: yesterday.toISOString().split('T')[0]
      };
      
    } catch (error) {
      console.error('=== 사용자 통계 업데이트 실패 ===');
      console.error('에러 상세:', error);
      return { error: error.message };
    }
  });

// 🔧 새로 추가: resume을 포함한 집중 시간 계산 함수
function calculateDailyFocusTime(activityDocs) {
  let totalFocusMinutes = 0;
  let currentSessionStart = null;
  let isPaused = false;
  
  console.log(`총 ${activityDocs.length}개의 활동 처리 중...`);
  
  activityDocs.forEach((doc, index) => {
    const activity = doc.data();
    const activityType = activity.type;
    const timestamp = activity.timestamp;
    
    console.log(`활동 ${index + 1}: ${activityType} at ${timestamp.toDate().toISOString()}`);
    
    switch (activityType) {
      case 'start':
        // 새로운 세션 시작
        currentSessionStart = timestamp;
        isPaused = false;
        console.log('  → 새 세션 시작');
        break;
        
      case 'pause':
        // 현재 세션 일시정지
        if (currentSessionStart && !isPaused) {
          const sessionMinutes = Math.floor(
            (timestamp.seconds - currentSessionStart.seconds) / 60
          );
          
          // 유효한 세션 시간만 추가 (최대 5시간 제한)
          if (sessionMinutes > 0 && sessionMinutes <= 300) {
            totalFocusMinutes += sessionMinutes;
            console.log(`  → 세션 일시정지: ${sessionMinutes}분 추가 (누적: ${totalFocusMinutes}분)`);
          } else {
            console.log(`  → 비정상 세션 시간 무시: ${sessionMinutes}분`);
          }
          
          isPaused = true;
        } else {
          console.log('  → 일시정지 무시 (시작 시간 없음 또는 이미 일시정지됨)');
        }
        break;
        
      case 'resume':
        // 세션 재개 - 새로운 시작점으로 설정
        if (isPaused) {
          currentSessionStart = timestamp;
          isPaused = false;
          console.log('  → 세션 재개');
        } else {
          console.log('  → 재개 무시 (일시정지 상태가 아님)');
        }
        break;
        
      case 'end':
        // 현재 세션 종료
        if (currentSessionStart && !isPaused) {
          const sessionMinutes = Math.floor(
            (timestamp.seconds - currentSessionStart.seconds) / 60
          );
          
          // 유효한 세션 시간만 추가
          if (sessionMinutes > 0 && sessionMinutes <= 300) {
            totalFocusMinutes += sessionMinutes;
            console.log(`  → 세션 종료: ${sessionMinutes}분 추가 (누적: ${totalFocusMinutes}분)`);
          } else {
            console.log(`  → 비정상 세션 시간 무시: ${sessionMinutes}분`);
          }
        } else {
          console.log('  → 종료 무시 (시작 시간 없음 또는 이미 일시정지됨)');
        }
        
        // 세션 상태 초기화
        currentSessionStart = null;
        isPaused = false;
        break;
        
      default:
        console.log(`  → 알 수 없는 활동 타입: ${activityType}`);
        break;
    }
  });
  
  // 🔧 하루가 끝났는데 아직 진행 중인 세션이 있는 경우 처리
  if (currentSessionStart && !isPaused) {
    // 다음 날 00:00:00까지의 시간을 계산
    const endOfDay = new Date(currentSessionStart.toDate());
    endOfDay.setHours(23, 59, 59, 999);
    
    const remainingMinutes = Math.floor(
      (endOfDay.getTime() - currentSessionStart.toDate().getTime()) / (1000 * 60)
    );
    
    if (remainingMinutes > 0 && remainingMinutes <= 300) {
      totalFocusMinutes += remainingMinutes;
      console.log(`미완료 세션 처리: ${remainingMinutes}분 추가 (누적: ${totalFocusMinutes}분)`);
    }
  }
  
  console.log(`최종 집중 시간: ${totalFocusMinutes}분`);
  return totalFocusMinutes;
}

// === 프로필 변경 시 관련 데이터 동기화 ===
exports.syncProfileChanges = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    try {
      console.log('=== 프로필 변경 동기화 시작 ===');
      
      const userId = context.params.userId;
      const beforeData = change.before.data();
      const afterData = change.after.data();
      
      console.log('사용자 ID:', userId);
      console.log('변경 전 닉네임:', beforeData.nickname);
      console.log('변경 후 닉네임:', afterData.nickname);
      console.log('변경 전 이미지:', beforeData.image ? '있음' : '없음');
      console.log('변경 후 이미지:', afterData.image ? '있음' : '없음');
      
      // 닉네임이나 이미지가 변경되지 않은 경우 처리 안함
      const nicknameChanged = beforeData.nickname !== afterData.nickname;
      const imageChanged = beforeData.image !== afterData.image;
      
      if (!nicknameChanged && !imageChanged) {
        console.log('닉네임과 이미지 모두 변경되지 않음 - 동기화 건너뜀');
        return { skipped: true, reason: 'no_changes' };
      }
      
      console.log('변경 사항:', {
        nickname: nicknameChanged,
        image: imageChanged
      });
      
      let totalUpdated = 0;
      
      // === 1. 그룹 멤버 정보 업데이트 ===
      console.log('1. 그룹 멤버 정보 업데이트 시작');
      
      try {
        const memberGroupsSnapshot = await admin.firestore()
          .collectionGroup('members')
          .where('userId', '==', userId)
          .get();
        
        console.log('사용자가 속한 그룹 멤버 문서 수:', memberGroupsSnapshot.docs.length);
        
        if (!memberGroupsSnapshot.empty) {
          const batch1 = admin.firestore().batch();
          let batch1Count = 0;
          
          memberGroupsSnapshot.docs.forEach(memberDoc => {
            const updateData = {};
            
            if (nicknameChanged) {
              updateData.userName = afterData.nickname;
            }
            if (imageChanged) {
              updateData.profileUrl = afterData.image || '';
            }
            
            batch1.update(memberDoc.ref, updateData);
            batch1Count++;
            
            console.log(`그룹 멤버 문서 업데이트 예약: ${memberDoc.ref.path}`);
          });
          
          await batch1.commit();
          totalUpdated += batch1Count;
          console.log(`그룹 멤버 정보 업데이트 완료: ${batch1Count}개`);
        }
      } catch (groupError) {
        console.error('그룹 멤버 정보 업데이트 중 오류:', groupError);
      }
      
      // === 2. 게시글 작성자 정보 업데이트 ===
      console.log('2. 게시글 작성자 정보 업데이트 시작');
      
      try {
        const postsSnapshot = await admin.firestore()
          .collection('posts')
          .where('authorId', '==', userId)
          .get();
        
        console.log('사용자가 작성한 게시글 수:', postsSnapshot.docs.length);
        
        if (!postsSnapshot.empty) {
          const batch2 = admin.firestore().batch();
          let batch2Count = 0;
          
          postsSnapshot.docs.forEach(postDoc => {
            const updateData = {};
            
            if (nicknameChanged) {
              updateData.authorNickname = afterData.nickname;
            }
            if (imageChanged) {
              updateData.userProfileImage = afterData.image || '';
            }
            
            batch2.update(postDoc.ref, updateData);
            batch2Count++;
            
            console.log(`게시글 문서 업데이트 예약: ${postDoc.id}`);
          });
          
          await batch2.commit();
          totalUpdated += batch2Count;
          console.log(`게시글 작성자 정보 업데이트 완료: ${batch2Count}개`);
        }
      } catch (postError) {
        console.error('게시글 작성자 정보 업데이트 중 오류:', postError);
      }
      
      // === 3. 댓글 작성자 정보 업데이트 ===
      console.log('3. 댓글 작성자 정보 업데이트 시작');
      
      try {
        const commentsSnapshot = await admin.firestore()
          .collectionGroup('comments')
          .where('userId', '==', userId)
          .get();
        
        console.log('사용자가 작성한 댓글 수:', commentsSnapshot.docs.length);
        
        if (!commentsSnapshot.empty) {
          // 댓글은 많을 수 있으므로 배치 단위로 분할 처리
          const batchSize = 450; // 안전 마진 고려
          
          for (let i = 0; i < commentsSnapshot.docs.length; i += batchSize) {
            const batch3 = admin.firestore().batch();
            const batchDocs = commentsSnapshot.docs.slice(i, i + batchSize);
            
            batchDocs.forEach(commentDoc => {
              const updateData = {};
              
              if (nicknameChanged) {
                updateData.userName = afterData.nickname;
              }
              if (imageChanged) {
                updateData.userProfileImage = afterData.image || '';
              }
              
              batch3.update(commentDoc.ref, updateData);
              
              console.log(`댓글 문서 업데이트 예약: ${commentDoc.ref.path}`);
            });
            
            await batch3.commit();
            totalUpdated += batchDocs.length;
            console.log(`댓글 배치 ${Math.floor(i/batchSize) + 1} 업데이트 완료: ${batchDocs.length}개`);
          }
        }
      } catch (commentError) {
        console.error('댓글 작성자 정보 업데이트 중 오류:', commentError);
      }
      
      // === 4. 그룹 타이머 활동 정보 업데이트 ===
      console.log('4. 그룹 타이머 활동 정보 업데이트 시작');
      
      try {
        if (nicknameChanged) {
          const timerActivitiesSnapshot = await admin.firestore()
            .collectionGroup('timerActivities')
            .where('userId', '==', userId)
            .get();
          
          console.log('사용자의 그룹 타이머 활동 수:', timerActivitiesSnapshot.docs.length);
          
          if (!timerActivitiesSnapshot.empty) {
            const batch4 = admin.firestore().batch();
            let batch4Count = 0;
            
            timerActivitiesSnapshot.docs.forEach(activityDoc => {
              batch4.update(activityDoc.ref, {
                memberName: afterData.nickname
              });
              batch4Count++;
              
              console.log(`타이머 활동 문서 업데이트 예약: ${activityDoc.ref.path}`);
            });
            
            await batch4.commit();
            totalUpdated += batch4Count;
            console.log(`타이머 활동 정보 업데이트 완료: ${batch4Count}개`);
          }
        }
      } catch (activityError) {
        console.error('타이머 활동 정보 업데이트 중 오류:', activityError);
      }
      
      // === 5. 최근 알림 발송자 정보 업데이트 (최근 30일 알림만) ===
      console.log('5. 알림 발송자 정보 업데이트 시작');
      
      try {
        const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
        const thirtyDaysAgoTimestamp = admin.firestore.Timestamp.fromDate(thirtyDaysAgo);
        
        const notificationsSnapshot = await admin.firestore()
          .collectionGroup('items')
          .where('senderId', '==', userId)
          .where('createdAt', '>=', thirtyDaysAgoTimestamp)
          .get();
        
        console.log('사용자가 발송한 최근 알림 수:', notificationsSnapshot.docs.length);
        
        if (!notificationsSnapshot.empty) {
          const batch5 = admin.firestore().batch();
          let batch5Count = 0;
          
          notificationsSnapshot.docs.forEach(notificationDoc => {
            const updateData = {};
            
            if (nicknameChanged) {
              updateData.senderName = afterData.nickname;
            }
            if (imageChanged) {
              updateData.senderProfileImage = afterData.image || '';
            }
            
            batch5.update(notificationDoc.ref, updateData);
            batch5Count++;
            
            console.log(`알림 문서 업데이트 예약: ${notificationDoc.ref.path}`);
          });
          
          await batch5.commit();
          totalUpdated += batch5Count;
          console.log(`알림 발송자 정보 업데이트 완료: ${batch5Count}개`);
        }
      } catch (notificationError) {
        console.error('알림 발송자 정보 업데이터 중 오류:', notificationError);
      }
      
      console.log('=== 프로필 변경 동기화 완료 ===');
      console.log('총 업데이트된 문서 수:', totalUpdated);
      
      return { 
        success: true, 
        userId: userId,
        changes: {
          nickname: nicknameChanged,
          image: imageChanged
        },
        updatedDocuments: totalUpdated,
        newNickname: afterData.nickname,
        newImageUrl: afterData.image || null
      };
      
    } catch (error) {
      console.error('=== 프로필 변경 동기화 실패 ===');
      console.error('에러 상세:', error);
      return { error: error.message, userId: context.params.userId };
    }
  });

  // === 사용자 탈퇴 시 관련 데이터 정리 ===
exports.cleanupUserData = functions.firestore
  .document('users/{userId}')
  .onDelete(async (snapshot, context) => {
    try {
      console.log('=== 사용자 탈퇴 데이터 정리 시작 ===');
      
      const userId = context.params.userId;
      const userData = snapshot.data();
      
      console.log('탈퇴 사용자 ID:', userId);
      console.log('탈퇴 사용자 닉네임:', userData.nickname);
      
      let totalProcessed = 0;
      
      // === 1. FCM 토큰 모두 삭제 ===
      console.log('1. FCM 토큰 삭제 시작');
      
      try {
        const fcmTokensSnapshot = await admin.firestore()
          .collection('users')
          .doc(userId)
          .collection('private')
          .doc('fcmTokens')
          .collection('tokens')
          .get();
        
        if (!fcmTokensSnapshot.empty) {
          const batch1 = admin.firestore().batch();
          
          fcmTokensSnapshot.docs.forEach(tokenDoc => {
            batch1.delete(tokenDoc.ref);
          });
          
          // fcmTokens 문서도 삭제
          batch1.delete(admin.firestore()
            .collection('users')
            .doc(userId)
            .collection('private')
            .doc('fcmTokens'));
          
          await batch1.commit();
          totalProcessed += fcmTokensSnapshot.docs.length + 1;
          console.log('FCM 토큰 삭제 완료:', fcmTokensSnapshot.docs.length, '개');
        }
      } catch (fcmError) {
        console.error('FCM 토큰 삭제 중 오류:', fcmError);
      }
      
      // === 2. 사용자 개인 타이머 활동 삭제 ===
      console.log('2. 사용자 개인 타이머 활동 삭제 시작');
      
      try {
        const timerActivitiesSnapshot = await admin.firestore()
          .collection('users')
          .doc(userId)
          .collection('timerActivities')
          .get();
        
        if (!timerActivitiesSnapshot.empty) {
          const batch2 = admin.firestore().batch();
          
          timerActivitiesSnapshot.docs.forEach(activityDoc => {
            batch2.delete(activityDoc.ref);
          });
          
          await batch2.commit();
          totalProcessed += timerActivitiesSnapshot.docs.length;
          console.log('개인 타이머 활동 삭제 완료:', timerActivitiesSnapshot.docs.length, '개');
        }
      } catch (activityError) {
        console.error('개인 타이머 활동 삭제 중 오류:', activityError);
      }
      
      // === 3. 사용자 북마크 삭제 ===
      console.log('3. 사용자 북마크 삭제 시작');
      
      try {
        const bookmarksSnapshot = await admin.firestore()
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .get();
        
        if (!bookmarksSnapshot.empty) {
          const batch3 = admin.firestore().batch();
          
          bookmarksSnapshot.docs.forEach(bookmarkDoc => {
            batch3.delete(bookmarkDoc.ref);
          });
          
          await batch3.commit();
          totalProcessed += bookmarksSnapshot.docs.length;
          console.log('북마크 삭제 완료:', bookmarksSnapshot.docs.length, '개');
        }
      } catch (bookmarkError) {
        console.error('북마크 삭제 중 오류:', bookmarkError);
      }
      
      // === 4. 사용자 알림 모두 삭제 ===
      console.log('4. 사용자 알림 삭제 시작');
      
      try {
        const notificationsSnapshot = await admin.firestore()
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .get();
        
        if (!notificationsSnapshot.empty) {
          const batch4 = admin.firestore().batch();
          
          notificationsSnapshot.docs.forEach(notificationDoc => {
            batch4.delete(notificationDoc.ref);
          });
          
          // notifications 부모 문서도 삭제
          batch4.delete(admin.firestore()
            .collection('notifications')
            .doc(userId));
          
          await batch4.commit();
          totalProcessed += notificationsSnapshot.docs.length + 1;
          console.log('알림 삭제 완료:', notificationsSnapshot.docs.length, '개');
        }
      } catch (notificationError) {
        console.error('알림 삭제 중 오류:', notificationError);
      }
      
      // === 5. 그룹 멤버십 제거 및 관련 데이터 정리 ===
      console.log('5. 그룹 멤버십 제거 시작');
      
      try {
        const membershipSnapshot = await admin.firestore()
          .collectionGroup('members')
          .where('userId', '==', userId)
          .get();
        
        if (!membershipSnapshot.empty) {
          console.log('사용자가 속한 그룹 수:', membershipSnapshot.docs.length);
          
          // 각 그룹에서 멤버 제거 및 memberCount 감소
          const groupUpdates = new Map();
          const batch5 = admin.firestore().batch();
          
          membershipSnapshot.docs.forEach(memberDoc => {
            batch5.delete(memberDoc.ref);
            
            // 그룹 ID 추출 (groups/{groupId}/members/{memberId} 경로에서)
            const groupId = memberDoc.ref.parent.parent.id;
            groupUpdates.set(groupId, (groupUpdates.get(groupId) || 0) + 1);
          });
          
          // 각 그룹의 memberCount 감소
          for (const [groupId, removedCount] of groupUpdates) {
            const groupRef = admin.firestore().collection('groups').doc(groupId);
            batch5.update(groupRef, {
              memberCount: admin.firestore.FieldValue.increment(-removedCount)
            });
          }
          
          await batch5.commit();
          totalProcessed += membershipSnapshot.docs.length + groupUpdates.size;
          console.log('그룹 멤버십 제거 완료:', membershipSnapshot.docs.length, '개');
          console.log('영향받는 그룹 수:', groupUpdates.size);
        }
      } catch (membershipError) {
        console.error('그룹 멤버십 제거 중 오류:', membershipError);
      }
      
      // === 6. 사용자가 작성한 좋아요/댓글 좋아요 제거 ===
      console.log('6. 사용자 좋아요 데이터 정리 시작');
      
      try {
        // 게시글 좋아요 제거
        const postLikesSnapshot = await admin.firestore()
          .collectionGroup('likes')
          .where('userId', '==', userId)
          .get();
        
        if (!postLikesSnapshot.empty) {
          // 좋아요 제거와 동시에 likeCount 감소 처리를 위해 그룹별로 처리
          const postLikesByPost = new Map();
          
          postLikesSnapshot.docs.forEach(likeDoc => {
            const pathParts = likeDoc.ref.path.split('/');
            
            if (pathParts.includes('posts') && pathParts.includes('likes')) {
              // posts/{postId}/likes/{userId} 형태
              if (pathParts.length === 4) {
                const postId = pathParts[1];
                if (!postLikesByPost.has(postId)) {
                  postLikesByPost.set(postId, []);
                }
                postLikesByPost.get(postId).push(likeDoc);
              }
              // posts/{postId}/comments/{commentId}/likes/{userId} 형태
              else if (pathParts.length === 6) {
                const postId = pathParts[1];
                const commentId = pathParts[3];
                const key = `${postId}:${commentId}`;
                if (!postLikesByPost.has(key)) {
                  postLikesByPost.set(key, []);
                }
                postLikesByPost.get(key).push(likeDoc);
              }
            }
          });
          
          // 좋아요 제거 및 카운터 감소
          const batch6 = admin.firestore().batch();
          
          for (const [key, likeDocs] of postLikesByPost) {
            const pathParts = key.split(':');
            
            if (pathParts.length === 1) {
              // 게시글 좋아요
              const postId = pathParts[0];
              const postRef = admin.firestore().collection('posts').doc(postId);
              
              likeDocs.forEach(likeDoc => {
                batch6.delete(likeDoc.ref);
              });
              
              batch6.update(postRef, {
                likeCount: admin.firestore.FieldValue.increment(-likeDocs.length)
              });
            } else if (pathParts.length === 2) {
              // 댓글 좋아요
              const postId = pathParts[0];
              const commentId = pathParts[1];
              const commentRef = admin.firestore()
                .collection('posts')
                .doc(postId)
                .collection('comments')
                .doc(commentId);
              
              likeDocs.forEach(likeDoc => {
                batch6.delete(likeDoc.ref);
              });
              
              batch6.update(commentRef, {
                likeCount: admin.firestore.FieldValue.increment(-likeDocs.length)
              });
            }
          }
          
          await batch6.commit();
          totalProcessed += postLikesSnapshot.docs.length;
          console.log('사용자 좋아요 데이터 정리 완료:', postLikesSnapshot.docs.length, '개');
        }
      } catch (likeError) {
        console.error('좋아요 데이터 정리 중 오류:', likeError);
      }
      
      // === 결과 출력 ===
      console.log('=== 사용자 탈퇴 데이터 정리 완료 ===');
      console.log('총 처리된 문서 수:', totalProcessed);
      
      return { 
        success: true, 
        userId: userId,
        userNickname: userData.nickname,
        processedDocuments: totalProcessed
      };
      
    } catch (error) {
      console.error('=== 사용자 탈퇴 데이터 정리 실패 ===');
      console.error('에러 상세:', error);
      return { error: error.message, userId: context.params.userId };
    }
  });