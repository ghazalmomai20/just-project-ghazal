const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// 🔔 إشعار عند إضافة لايك على منتج
exports.onProductLikeAdded = functions.firestore
  .document('likes/{likeId}')
  .onCreate(async (snap, context) => {
    try {
      const likeData = snap.data();
      const { productId, userId: likerUserId } = likeData;
      
      console.log('Like added for product:', productId, 'by user:', likerUserId);
      
      // جلب بيانات المنتج
      const productDoc = await db.collection('products').doc(productId).get();
      if (!productDoc.exists) {
        console.log('Product not found:', productId);
        return;
      }
      
      const product = productDoc.data();
      const productOwnerId = product.createdBy;
      
      // ماتبعتش إشعار للشخص نفسه
      if (likerUserId === productOwnerId) {
        console.log('User liked their own product, skipping notification');
        return;
      }
      
      // جلب بيانات الشخص اللي عمل لايك
      const likerDoc = await db.collection('users').doc(likerUserId).get();
      const likerName = likerDoc.exists ? likerDoc.data().name || 'Anonymous' : 'Anonymous';
      
      // إنشاء الإشعار في قاعدة البيانات - بالإنجليزية
      const notification = {
        uid: productOwnerId,
        senderUid: likerUserId,
        senderName: likerName,
        senderImageUrl: likerDoc.exists ? likerDoc.data().profileImageUrl || '' : '',
        type: 'product_like',
        productId: productId,
        productName: product.name || 'Product',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        message: `${likerName} liked your product "${product.name || 'Product'}"`,
        read: false
      };
      
      // حفظ الإشعار
      await db.collection('notifications').add(notification);
      console.log('Notification saved to database');
      
      // جلب FCM token للمستخدم وإرسال Push Notification
      const ownerDoc = await db.collection('users').doc(productOwnerId).get();
      if (ownerDoc.exists && ownerDoc.data().fcmToken) {
        const fcmToken = ownerDoc.data().fcmToken;
        
        const message = {
          token: fcmToken,
          notification: {
            title: 'New Like ❤️',
            body: `${likerName} liked your product "${product.name || 'Product'}"`,
          },
          data: {
            type: 'product_like',
            productId: productId,
            senderUid: likerUserId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK'
          }
        };
        
        try {
          await admin.messaging().send(message);
          console.log('✅ Product like push notification sent successfully');
        } catch (error) {
          console.error('❌ Error sending push notification:', error);
        }
      } else {
        console.log('No FCM token found for user:', productOwnerId);
      }
      
    } catch (error) {
      console.error('❌ Error in onProductLikeAdded:', error);
    }
  });

// 🔔 إشعار عند إضافة كومنت على منتج - تم تعطيلها لمنع التكرار
exports.onProductCommentAdded = functions.firestore
  .document('products/{productId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    // تم تعطيل هذه الدالة لمنع تكرار الإشعارات
    // الإشعارات تتم من خلال التطبيق مباشرة
    console.log('🚫 Product comment notification blocked to prevent duplicates');
    return;
  });

// 🔔 إشعار عند إضافة كومنت على منشور - تم تعطيلها لمنع التكرار  
exports.onPostCommentAdded = functions.firestore
  .document('posts/{postId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    // تم تعطيل هذه الدالة لمنع تكرار الإشعارات
    // الإشعارات تتم من خلال التطبيق مباشرة
    console.log('🚫 Post comment notification blocked to prevent duplicates');
    return;
  });