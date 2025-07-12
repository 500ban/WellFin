const express = require('express');
const admin = require('firebase-admin');
const router = express.Router();

/**
 * 🔔 プッシュ通知API
 * FCMによるプッシュ通知送信、トークン管理、通知履歴管理
 */

// Firebase Admin SDK初期化（index.jsで実行済みと仮定）

/**
 * 個別プッシュ通知送信
 * POST /push-notifications/send
 */
router.post('/send', async (req, res) => {
  try {
    const { token, title, body, data, options } = req.body;

    // 入力検証
    if (!token || !title || !body) {
      return res.status(400).json({
        success: false,
        error: 'token, title, bodyは必須です',
      });
    }

    // FCMメッセージ構築
    const message = {
      token: token,
      notification: {
        title: title,
        body: body,
      },
      data: data || {},
      android: {
        notification: {
          channelId: options?.channelId || 'default',
          priority: options?.priority || 'high',
          sound: options?.sound || 'default',
          clickAction: options?.clickAction || 'FLUTTER_NOTIFICATION_CLICK',
        },
        data: {
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          ...(data || {}),
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            badge: options?.badge || 1,
            sound: options?.sound || 'default',
          },
        },
        headers: {
          'apns-priority': options?.priority === 'high' ? '10' : '5',
        },
      },
    };

    // FCM送信実行
    const response = await admin.messaging().send(message);

    // 通知履歴保存
    await saveNotificationHistory({
      messageId: response,
      recipientToken: token,
      title: title,
      body: body,
      data: data || {},
      sentAt: new Date(),
      status: 'sent',
    });

    res.json({
      success: true,
      messageId: response,
      message: 'プッシュ通知を送信しました',
    });

  } catch (error) {
    console.error('プッシュ通知送信エラー:', error);
    
    // エラー履歴保存
    await saveNotificationHistory({
      messageId: null,
      recipientToken: req.body.token,
      title: req.body.title,
      body: req.body.body,
      data: req.body.data || {},
      sentAt: new Date(),
      status: 'failed',
      error: error.message,
    });

    res.status(500).json({
      success: false,
      error: 'プッシュ通知の送信に失敗しました',
      details: error.message,
    });
  }
});

/**
 * 一括プッシュ通知送信（トピック）
 * POST /push-notifications/send-topic
 */
router.post('/send-topic', async (req, res) => {
  try {
    const { topic, title, body, data, options } = req.body;

    // 入力検証
    if (!topic || !title || !body) {
      return res.status(400).json({
        success: false,
        error: 'topic, title, bodyは必須です',
      });
    }

    // FCMメッセージ構築
    const message = {
      topic: topic,
      notification: {
        title: title,
        body: body,
      },
      data: data || {},
      android: {
        notification: {
          channelId: options?.channelId || 'default',
          priority: options?.priority || 'high',
          sound: options?.sound || 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            badge: options?.badge || 1,
            sound: options?.sound || 'default',
          },
        },
      },
    };

    // FCM送信実行
    const response = await admin.messaging().send(message);

    // トピック通知履歴保存
    await saveTopicNotificationHistory({
      messageId: response,
      topic: topic,
      title: title,
      body: body,
      data: data || {},
      sentAt: new Date(),
      status: 'sent',
    });

    res.json({
      success: true,
      messageId: response,
      message: `トピック「${topic}」にプッシュ通知を送信しました`,
    });

  } catch (error) {
    console.error('トピック通知送信エラー:', error);
    
    res.status(500).json({
      success: false,
      error: 'トピック通知の送信に失敗しました',
      details: error.message,
    });
  }
});

/**
 * 複数トークンへの一括送信
 * POST /push-notifications/send-multiple
 */
router.post('/send-multiple', async (req, res) => {
  try {
    const { tokens, title, body, data, options } = req.body;

    // 入力検証
    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'tokensは空でない配列である必要があります',
      });
    }

    if (!title || !body) {
      return res.status(400).json({
        success: false,
        error: 'title, bodyは必須です',
      });
    }

    // FCMメッセージ構築
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: data || {},
      android: {
        notification: {
          channelId: options?.channelId || 'default',
          priority: options?.priority || 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            badge: options?.badge || 1,
          },
        },
      },
      tokens: tokens,
    };

    // FCM一括送信実行
    const response = await admin.messaging().sendEachForMulticast(message);

    // 結果分析
    const successCount = response.successCount;
    const failureCount = response.failureCount;
    const results = [];

    response.responses.forEach((resp, idx) => {
      results.push({
        token: tokens[idx],
        success: resp.success,
        messageId: resp.messageId,
        error: resp.error?.message,
      });
    });

    // 一括通知履歴保存
    await saveBatchNotificationHistory({
      title: title,
      body: body,
      data: data || {},
      sentAt: new Date(),
      successCount: successCount,
      failureCount: failureCount,
      results: results,
    });

    res.json({
      success: true,
      successCount: successCount,
      failureCount: failureCount,
      results: results,
      message: `${successCount}件の通知を送信しました`,
    });

  } catch (error) {
    console.error('一括通知送信エラー:', error);
    
    res.status(500).json({
      success: false,
      error: '一括通知の送信に失敗しました',
      details: error.message,
    });
  }
});

/**
 * 習慣リマインダー通知送信
 * POST /push-notifications/habit-reminder
 */
router.post('/habit-reminder', async (req, res) => {
  try {
    const { userId, habitName, reminderTime, customMessage } = req.body;

    // 入力検証
    if (!userId || !habitName) {
      return res.status(400).json({
        success: false,
        error: 'userId, habitNameは必須です',
      });
    }

    // ユーザーのFCMトークンを取得
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'ユーザーが見つかりません',
      });
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        error: 'ユーザーのFCMトークンが設定されていません',
      });
    }

    // 習慣リマインダーメッセージ生成
    const title = '🌟 習慣リマインダー';
    const body = customMessage || `${habitName}の時間です！今日も継続しましょう`;

    // FCMメッセージ構築
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: 'habit_reminder',
        habitName: habitName,
        userId: userId,
        reminderTime: reminderTime || '',
      },
      android: {
        notification: {
          channelId: 'habit_reminders',
          priority: 'high',
          sound: 'default',
        },
      },
    };

    // FCM送信実行
    const response = await admin.messaging().send(message);

    res.json({
      success: true,
      messageId: response,
      message: `習慣リマインダー「${habitName}」を送信しました`,
    });

  } catch (error) {
    console.error('習慣リマインダー送信エラー:', error);
    
    res.status(500).json({
      success: false,
      error: '習慣リマインダーの送信に失敗しました',
      details: error.message,
    });
  }
});

/**
 * タスク締切アラート送信
 * POST /push-notifications/task-deadline
 */
router.post('/task-deadline', async (req, res) => {
  try {
    const { userId, taskName, dueDate, priority, beforeMinutes } = req.body;

    // 入力検証
    if (!userId || !taskName || !dueDate) {
      return res.status(400).json({
        success: false,
        error: 'userId, taskName, dueDateは必須です',
      });
    }

    // ユーザーのFCMトークンを取得
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        error: 'ユーザーのFCMトークンが設定されていません',
      });
    }

    // 締切アラートメッセージ生成
    const timeText = beforeMinutes > 60 
      ? `${Math.floor(beforeMinutes / 60)}時間${beforeMinutes % 60}分`
      : `${beforeMinutes}分`;
    
    const title = priority === 'high' ? '🚨 緊急タスク締切' : '⏰ タスク締切アラート';
    const body = `「${taskName}」の締切まで${timeText}です`;

    // FCMメッセージ構築
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: 'task_deadline',
        taskName: taskName,
        userId: userId,
        dueDate: dueDate,
        priority: priority || 'medium',
        beforeMinutes: beforeMinutes?.toString() || '0',
      },
      android: {
        notification: {
          channelId: 'task_deadlines',
          priority: priority === 'high' ? 'max' : 'high',
          sound: 'default',
        },
      },
    };

    // FCM送信実行
    const response = await admin.messaging().send(message);

    res.json({
      success: true,
      messageId: response,
      message: `タスク締切アラート「${taskName}」を送信しました`,
    });

  } catch (error) {
    console.error('タスク締切アラート送信エラー:', error);
    
    res.status(500).json({
      success: false,
      error: 'タスク締切アラートの送信に失敗しました',
      details: error.message,
    });
  }
});

/**
 * AI週次レポート送信
 * POST /push-notifications/ai-report
 */
router.post('/ai-report', async (req, res) => {
  try {
    const { userId, reportType, summary, reportData } = req.body;

    // 入力検証
    if (!userId || !reportType || !summary) {
      return res.status(400).json({
        success: false,
        error: 'userId, reportType, summaryは必須です',
      });
    }

    // ユーザーのFCMトークンを取得
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        error: 'ユーザーのFCMトークンが設定されていません',
      });
    }

    // AI分析レポートメッセージ生成
    const title = reportType === 'weekly' 
      ? '🤖 AI週次レポート' 
      : '📊 AI分析レポート';
    const body = summary;

    // FCMメッセージ構築
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: 'ai_report',
        reportType: reportType,
        userId: userId,
        summary: summary,
        reportData: JSON.stringify(reportData || {}),
      },
      android: {
        notification: {
          channelId: 'ai_reports',
          priority: 'default',
          sound: 'default',
        },
      },
    };

    // FCM送信実行
    const response = await admin.messaging().send(message);

    res.json({
      success: true,
      messageId: response,
      message: `AI分析レポート（${reportType}）を送信しました`,
    });

  } catch (error) {
    console.error('AI分析レポート送信エラー:', error);
    
    res.status(500).json({
      success: false,
      error: 'AI分析レポートの送信に失敗しました',
      details: error.message,
    });
  }
});

/**
 * 通知履歴取得
 * GET /push-notifications/history/:userId
 */
router.get('/history/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 50, startAfter = null } = req.query;

    // Firestore から通知履歴を取得
    let query = admin.firestore()
      .collection('notification_history')
      .where('recipientUserId', '==', userId)
      .orderBy('sentAt', 'desc')
      .limit(parseInt(limit));

    if (startAfter) {
      const startAfterDoc = await admin.firestore()
        .collection('notification_history')
        .doc(startAfter)
        .get();
      query = query.startAfter(startAfterDoc);
    }

    const snapshot = await query.get();
    const history = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    res.json({
      success: true,
      history: history,
      hasMore: snapshot.docs.length === parseInt(limit),
    });

  } catch (error) {
    console.error('通知履歴取得エラー:', error);
    
    res.status(500).json({
      success: false,
      error: '通知履歴の取得に失敗しました',
      details: error.message,
    });
  }
});

/**
 * FCMトークン登録・更新
 * POST /push-notifications/register-token
 */
router.post('/register-token', async (req, res) => {
  try {
    const { userId, fcmToken, platform } = req.body;

    // 入力検証
    if (!userId || !fcmToken) {
      return res.status(400).json({
        success: false,
        error: 'userId, fcmTokenは必須です',
      });
    }

    // ユーザードキュメントにFCMトークンを保存
    await admin.firestore().collection('users').doc(userId).update({
      fcmToken: fcmToken,
      platform: platform || 'unknown',
      tokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({
      success: true,
      message: 'FCMトークンを登録しました',
    });

  } catch (error) {
    console.error('FCMトークン登録エラー:', error);
    
    res.status(500).json({
      success: false,
      error: 'FCMトークンの登録に失敗しました',
      details: error.message,
    });
  }
});

// === ヘルパー関数 ===

/**
 * 通知履歴保存
 */
async function saveNotificationHistory(historyData) {
  try {
    await admin.firestore().collection('notification_history').add({
      ...historyData,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error('通知履歴保存エラー:', error);
  }
}

/**
 * トピック通知履歴保存
 */
async function saveTopicNotificationHistory(historyData) {
  try {
    await admin.firestore().collection('topic_notification_history').add({
      ...historyData,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error('トピック通知履歴保存エラー:', error);
  }
}

/**
 * 一括通知履歴保存
 */
async function saveBatchNotificationHistory(historyData) {
  try {
    await admin.firestore().collection('batch_notification_history').add({
      ...historyData,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error('一括通知履歴保存エラー:', error);
  }
}

module.exports = router; 