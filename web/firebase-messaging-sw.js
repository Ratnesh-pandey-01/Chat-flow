importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCwttyYYayrbZnKiN3Me8LFmTjoR7zMO4I",
  authDomain: "chatflow-633af.firebaseapp.com",
  projectId: "chatflow-633af",
  messagingSenderId: "946902067778",
  appId: "1:946902067778:web:fe72e01a9fae95033b1bdb",
});

const messaging = firebase.messaging();