const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// HTTP function to set custom claims for admin
exports.addAdminRole = functions.https.onCall((data, context) => {
  // Check if the request is made by an authenticated user
  if (context.auth.token.admin !== true) {
    return { error: 'Only admins can add other admins.' };
  }

  // Get user and add custom claim (admin)
  return admin.auth().getUserByEmail(data.email).then(user => {
    return admin.auth().setCustomUserClaims(user.uid, {
      admin: true
    });
  }).then(() => {
    return { message: `Success! ${data.email} has been made an admin.` };
  }).catch(err => {
    return { error: err.message };
  });
});


const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
