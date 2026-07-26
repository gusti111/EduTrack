importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

// Konfigurasi ini diambil dari file firebase_options.dart milikmu
firebase.initializeApp({
    apiKey: "AIzaSyATX-lVzOOeKoS4-_Y7tAlI-CUCGoXp08Q",
    authDomain: "edutrack-e9eb2.firebaseapp.com",
    projectId: "edutrack-e9eb2",
    storageBucket: "edutrack-e9eb2.firebasestorage.app",
    messagingSenderId: "963404057121",
    appId: "1:963404057121:web:410b613f488c95bf7bb160"
});

const messaging = firebase.messaging();

// Handler untuk pesan background (saat tab aplikasi ditutup atau tidak aktif)
messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Menerima pesan background: ', payload);

    const notificationTitle = payload.notification?.title || 'EduTrack: Notifikasi Baru';
    const notificationOptions = {
        body: payload.notification?.body,
        icon: '/icons/Icon-192.png' // Pastikan path ini sesuai dengan icon web kamu
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
});