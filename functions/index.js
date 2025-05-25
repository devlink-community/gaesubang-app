const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Admin SDK 초기화 - 권한 문제 해결
admin.initializeApp();
/**
 * Returns a Firestore Timestamp offset by the given number of days.
 * @param {number} daysOffset - Number of days to offset (negative for past days).
 * @returns {admin.firestore.Timestamp}
 */
function createTimestamp(daysOffset = 0) {
  const date = new Date();
  if (daysOffset !== 0) {
    date.setDate(date.getDate() + daysOffset);
  }
  return admin.firestore.Timestamp.fromDate(date);
}

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
      .where('lastUsed', '>', createTimestamp(-30))
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
      
      const thirtyDaysAgoTimestamp = createTimestamp(-30);
      
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
      
      const ninetyDaysAgoTimestamp = createTimestamp(-90);
      
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

// === 출석부 데이터 집계 (매일 새벽 1시 실행) ===
exports.processAttendanceRecords = functions.pubsub
  .schedule('0 1 * * *') // 매일 새벽 1시 (KST)
  .timeZone('Asia/Seoul')
  .onRun(async (context) => {
    try {
      console.log('=== 출석부 데이터 집계 시작 ===');

      // 어제 날짜 계산
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      yesterday.setHours(0, 0, 0, 0);

      // 어제 날짜의 키 형식 (YYYY-MM-DD)
      const yesterdayKey = yesterday.toISOString().split('T')[0];
      const yesterdayMonth = yesterdayKey.substring(0, 7); // YYYY-MM

      console.log('집계 기준 날짜:', yesterdayKey);
      console.log('출석부 월 키:', yesterdayMonth);

      let processedGroups = 0;
      let processedMembers = 0;
      let updatedAttendances = 0;

      // 1. 모든 그룹 조회
      const groupsSnapshot = await admin.firestore().collection('groups').get();
      console.log('총 그룹 수:', groupsSnapshot.docs.length);

      // 2. 각 그룹별 처리
      for (const groupDoc of groupsSnapshot.docs) {
        try {
          const groupId = groupDoc.id;
          const groupData = groupDoc.data();

          console.log(`그룹 처리 중: ${groupId} (${groupData.name || '이름 없음'})`);

          // 3. 그룹의 모든 멤버 조회
          const membersSnapshot = await admin.firestore()
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .get();

          console.log(`- 멤버 수: ${membersSnapshot.docs.length}`);

          if (membersSnapshot.empty) {
            processedGroups++;
            continue;
          }

          // 그룹별 일별 통계 데이터 준비
          const monthlyStatsRef = admin.firestore()
            .collection('groups')
            .doc(groupId)
            .collection('monthlyStats')
            .doc(yesterdayMonth);

          // 월별 통계 문서 가져오기 (없으면 생성)
          let monthlyStatsData = {};
          const monthlyStatsDoc = await monthlyStatsRef.get();

          if (monthlyStatsDoc.exists) {
            monthlyStatsData = monthlyStatsDoc.data() || {};
          }

          // 어제 날짜 데이터 초기화
          if (!monthlyStatsData[yesterdayKey]) {
            monthlyStatsData[yesterdayKey] = {
              members: {}
            };
          }

          // 4. 각 멤버별 처리
          const memberUpdateBatch = admin.firestore().batch();
          let memberUpdatesCount = 0;

          for (const memberDoc of membersSnapshot.docs) {
            const memberId = memberDoc.id;
            const memberData = memberDoc.data();
            const userId = memberData.userId;

            if (!userId) continue;

            processedMembers++;

            // 타이머 월별 누적 시간 확인
            const timerMonthlyDurations = memberData.timerMonthlyDurations || {};
            const yesterdayDuration = timerMonthlyDurations[yesterdayKey] || 0;

            // 어제 활동 시간이 있으면 출석부에 기록
            if (yesterdayDuration > 0) {
              // 출석부에는 초 단위 값 그대로 저장
              monthlyStatsData[yesterdayKey].members[userId] = yesterdayDuration;
              updatedAttendances++;

              console.log(`  - 멤버 ${userId} 활동 기록: ${yesterdayDuration}초`);

              // timerMonthlyDurations에서 어제 날짜 데이터 제거
              if (timerMonthlyDurations[yesterdayKey]) {
                const memberRef = admin.firestore()
                  .collection('groups')
                  .doc(groupId)
                  .collection('members')
                  .doc(memberId);

                // FieldValue.delete()로 해당 필드만 제거
                const updatedDurations = {...timerMonthlyDurations};
                delete updatedDurations[yesterdayKey];

                memberUpdateBatch.update(memberRef, {
                  [`timerMonthlyDurations.${yesterdayKey}`]: admin.firestore.FieldValue.delete()
                });

                memberUpdatesCount++;

                // Firestore 제한(500개)에 도달하면 batch 실행 후 초기화
                if (memberUpdatesCount >= 450) {
                  await memberUpdateBatch.commit();
                  console.log(`  - ${memberUpdatesCount}개 멤버 업데이트 완료`);
                  memberUpdateBatch = admin.firestore().batch();
                  memberUpdatesCount = 0;
                }
              }
            }
          }

          // 남은 batch 업데이트 실행
          if (memberUpdatesCount > 0) {
            await memberUpdateBatch.commit();
            console.log(`  - ${memberUpdatesCount}개 멤버 업데이트 완료`);
          }

          // 5. 월별 통계 문서 업데이트
          await monthlyStatsRef.set(monthlyStatsData, { merge: true });
          console.log(`  - ${groupId} 출석부 업데이트 완료`);

          processedGroups++;

        } catch (groupError) {
          console.error(`그룹 ${groupDoc.id} 처리 중 오류:`, groupError);
          // 한 그룹의 오류가 전체 처리를 중단하지 않도록 계속 진행
        }
      }

      console.log('=== 출석부 데이터 집계 완료 ===');
      console.log('처리된 그룹 수:', processedGroups);
      console.log('처리된 멤버 수:', processedMembers);
      console.log('업데이트된 출석 기록 수:', updatedAttendances);

      return {
        success: true,
        processedGroups,
        processedMembers,
        updatedAttendances,
        date: yesterdayKey
      };

    } catch (error) {
      console.error('=== 출석부 데이터 집계 실패 ===');
      console.error('에러 상세:', error);
      return { error: error.message };
    }
  });

// === 사용자 데이터 정리 (사용자 삭제 시) ===
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

      // === 2. 사용자 summary 문서 삭제 ===
      console.log('2. 사용자 summary 문서 삭제 시작');

      try {
        const summarySnapshot = await admin.firestore()
          .collection('users')
          .doc(userId)
          .collection('summary')
          .get();

        if (!summarySnapshot.empty) {
          const batch2 = admin.firestore().batch();

          summarySnapshot.docs.forEach(summaryDoc => {
            batch2.delete(summaryDoc.ref);
          });

          await batch2.commit();
          totalProcessed += summarySnapshot.docs.length;
          console.log('summary 문서 삭제 완료:', summarySnapshot.docs.length, '개');
        }
      } catch (summaryError) {
        console.error('summary 문서 삭제 중 오류:', summaryError);
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

// === 그룹 삭제 시 관련 데이터 정리 ===
exports.cleanupGroupData = functions.firestore
  .document('groups/{groupId}')
  .onDelete(async (snapshot, context) => {
    try {
      console.log('=== 그룹 삭제 데이터 정리 시작 ===');

      const groupId = context.params.groupId;
      const groupData = snapshot.data();

      console.log('삭제된 그룹 ID:', groupId);
      console.log('삭제된 그룹명:', groupData.name);

      let totalProcessed = 0;

      // === 1. 그룹 멤버 및 사용자 joingroup 정리 ===
      console.log('1. 그룹 멤버 및 사용자 joingroup 정리 시작');

      try {
        const membersSnapshot = await admin.firestore()
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .get();

        if (!membersSnapshot.empty) {
          const batch1 = admin.firestore().batch();
          const memberUserIds = [];

          // 멤버 문서 삭제
          membersSnapshot.docs.forEach(memberDoc => {
            const memberData = memberDoc.data();
            memberUserIds.push(memberData.userId);
            batch1.delete(memberDoc.ref);
          });

          // 각 멤버의 joingroup 배열에서 해당 그룹 제거
          for (const userId of memberUserIds) {
            try {
              // 🔧 수정: group_id 기준으로 배열에서 제거
              const userDoc = await admin.firestore().collection('users').doc(userId).get();
              if (userDoc.exists && userDoc.data().joingroup) {
                const joinGroups = userDoc.data().joingroup;
                const updatedJoinGroups = joinGroups.filter(g => g.group_id !== groupId);

                batch1.update(admin.firestore().collection('users').doc(userId), {
                  joingroup: updatedJoinGroups
                });
              }
            } catch (memberUpdateError) {
              console.error(`멤버 ${userId} joingroup 업데이트 실패:`, memberUpdateError);
            }
          }

          await batch1.commit();
          totalProcessed += membersSnapshot.docs.length + memberUserIds.length;
          console.log('그룹 멤버 및 joingroup 정리 완료:', membersSnapshot.docs.length, '개 멤버');
        }
      } catch (memberError) {
        console.error('그룹 멤버 정리 중 오류:', memberError);
      }

      // === 2. 그룹 월별 통계(출석부) 데이터 삭제 ===
      console.log('2. 그룹 월별 통계(출석부) 데이터 삭제 시작');

      try {
        const monthlyStatsSnapshot = await admin.firestore()
          .collection('groups')
          .doc(groupId)
          .collection('monthlyStats')
          .get();

        if (!monthlyStatsSnapshot.empty) {
          // 대량 데이터 처리를 위한 배치 분할
          const batchSize = 450;

          for (let i = 0; i < monthlyStatsSnapshot.docs.length; i += batchSize) {
            const batch2 = admin.firestore().batch();
            const batchDocs = monthlyStatsSnapshot.docs.slice(i, i + batchSize);

            batchDocs.forEach(statsDoc => {
              batch2.delete(statsDoc.ref);
            });

            await batch2.commit();
            totalProcessed += batchDocs.length;
          }

          console.log('그룹 월별 통계(출석부) 삭제 완료:', monthlyStatsSnapshot.docs.length, '개');
        }
      } catch (statsError) {
        console.error('그룹 월별 통계(출석부) 삭제 중 오류:', statsError);
      }

      // === 3. 그룹 관련 알림 삭제 (최근 30일) ===
      console.log('3. 그룹 관련 알림 삭제 시작');

      try {
        const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
        const thirtyDaysAgoTimestamp = admin.firestore.Timestamp.fromDate(thirtyDaysAgo);

        // 🔧 수정: 그룹 관련 알림을 더 정확히 찾기 위해 여러 조건으로 검색
        const groupNotificationsSnapshot = await admin.firestore()
          .collectionGroup('items')
          .where('data.groupId', '==', groupId)  // 🔧 수정: 그룹 관련 알림 검색 조건 개선
          .where('createdAt', '>=', thirtyDaysAgoTimestamp)
          .get();

        if (!groupNotificationsSnapshot.empty) {
          const batch3 = admin.firestore().batch();

          groupNotificationsSnapshot.docs.forEach(notificationDoc => {
            batch3.delete(notificationDoc.ref);
          });

          await batch3.commit();
          totalProcessed += groupNotificationsSnapshot.docs.length;
          console.log('그룹 관련 알림 삭제 완료:', groupNotificationsSnapshot.docs.length, '개');
        }
      } catch (notificationError) {
        console.error('그룹 관련 알림 삭제 중 오류:', notificationError);
      }

      console.log('=== 그룹 삭제 데이터 정리 완료 ===');
      console.log('총 처리된 문서 수:', totalProcessed);

      return {
        success: true,
        groupId: groupId,
        groupName: groupData.name,
        processedDocuments: totalProcessed
      };

    } catch (error) {
      console.error('=== 그룹 삭제 데이터 정리 실패 ===');
      console.error('에러 상세:', error);
      return { error: error.message, groupId: context.params.groupId };
    }
  });

// === 그룹 정보 변경 시 관련 데이터 동기화 ===
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

      // === 4. 최근 알림 발송자 정보 업데이트 (최근 30일 알림만) ===
      console.log('4. 알림 발송자 정보 업데이트 시작');

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

// === 그룹 정보 변경 시 관련 데이터 동기화 ===
exports.syncGroupChanges = functions.firestore
 .document('groups/{groupId}')
 .onUpdate(async (change, context) => {
   try {
     console.log('=== 그룹 정보 변경 동기화 시작 ===');

     const groupId = context.params.groupId;
     const beforeData = change.before.data();
     const afterData = change.after.data();

     console.log('그룹 ID:', groupId);
     console.log('변경 전 그룹명:', beforeData.name);
     console.log('변경 후 그룹명:', afterData.name);
     console.log('변경 전 이미지:', beforeData.imageUrl ? '있음' : '없음');
     console.log('변경 후 이미지:', afterData.imageUrl ? '있음' : '없음');

     // 이름이나 이미지가 변경되지 않은 경우 처리 안함
     const nameChanged = beforeData.name !== afterData.name;
     const imageChanged = beforeData.imageUrl !== afterData.imageUrl;

     if (!nameChanged && !imageChanged) {
       console.log('그룹명과 이미지 모두 변경되지 않음 - 동기화 건너뜀');
       return { skipped: true, reason: 'no_changes' };
     }

     console.log('변경 사항:', {
       name: nameChanged,
       image: imageChanged
     });

     let totalUpdated = 0;

     // === 1. 멤버들의 joingroup 배열 업데이트 ===
     console.log('1. 멤버들의 joingroup 배열 업데이트 시작');

     try {
       const membersSnapshot = await admin.firestore()
         .collection('groups')
         .doc(groupId)
         .collection('members')
         .get();

       console.log('그룹 멤버 수:', membersSnapshot.docs.length);

       if (!membersSnapshot.empty) {
         for (const memberDoc of membersSnapshot.docs) {
           const memberData = memberDoc.data();
           const userId = memberData.userId;

           if (!userId) continue;

           try {
             // 사용자 문서 조회
             const userDoc = await admin.firestore().collection('users').doc(userId).get();

             if (userDoc.exists && userDoc.data().joingroup) {
               const joinGroups = userDoc.data().joingroup;
               let updated = false;

               // 업데이트된 그룹 정보
               const updatedJoinGroups = joinGroups.map(group => {
                 if (group.group_id === groupId) {
                   updated = true;
                   return {
                     group_id: groupId,
                     group_name: nameChanged ? afterData.name : group.group_name,
                     group_image: imageChanged ? afterData.imageUrl || '' : group.group_image
                   };
                 }
                 return group;
               });

               if (updated) {
                 await admin.firestore().collection('users').doc(userId).update({
                   joingroup: updatedJoinGroups
                 });
                 totalUpdated++;
                 console.log(`사용자 ${userId}의 joingroup 업데이트 완료`);
               }
             }
           } catch (userError) {
             console.error(`사용자 ${userId} joingroup 업데이트 실패:`, userError);
           }
         }

         console.log('멤버 joingroup 업데이트 완료:', totalUpdated, '명');
       }
     } catch (memberError) {
       console.error('멤버 joingroup 업데이트 중 오류:', memberError);
     }

     console.log('=== 그룹 정보 변경 동기화 완료 ===');
     console.log('총 업데이트된 문서 수:', totalUpdated);

     return {
       success: true,
       groupId: groupId,
       changes: {
         name: nameChanged,
         image: imageChanged
       },
       updatedDocuments: totalUpdated,
       newGroupName: afterData.name,
       newImageUrl: afterData.imageUrl || null
     };

   } catch (error) {
     console.error('=== 그룹 정보 변경 동기화 실패 ===');
     console.error('에러 상세:', error);
     return { error: error.message, groupId: context.params.groupId };
   }
 });