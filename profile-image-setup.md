# Setting Up Google Cloud Storage for Profile Images

This document provides instructions on how to set up Google Cloud Storage for storing profile images in the KoenjiApp.

## Prerequisites

- A Firebase project with Firestore and Authentication already set up
- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase project initialized in your app directory (`firebase init`)

## Steps to Configure Google Cloud Storage

### 1. Enable Google Cloud Storage in Firebase Console

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. In the left sidebar, click on "Storage"
4. Click "Get Started" if you haven't set up Storage yet
5. Choose a location for your Storage bucket (preferably the same region as your Firestore database)
6. Click "Done"

### 2. Configure Security Rules

1. In the Firebase Console, go to Storage
2. Click on the "Rules" tab
3. Replace the default rules with the rules from the `firebase-storage-rules.txt` file:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow read access to all profile images
    match /profile_images/{profileId}.jpg {
      allow read: if true;
    }
    
    // Allow write access only to the owner of the profile
    match /profile_images/{profileId}.jpg {
      allow write: if request.auth != null && request.auth.uid == profileId;
    }
    
    // Default rule - deny all other access
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

4. Click "Publish"

### 3. Update Firebase SDK in Your App

Make sure your app has the Firebase Storage SDK installed:

1. In Xcode, go to your project settings
2. Select your app target
3. Go to the "Swift Packages" tab
4. Make sure "FirebaseStorage" is included in your Firebase dependencies

### 4. Test the Implementation

1. Run the app and log in
2. Go to the profile page
3. Tap on the profile image to select a new image
4. Verify that the image is uploaded to Google Cloud Storage
5. Verify that the image URL is saved in the profile and sessions
6. Verify that the image is displayed in the profile avatar and session avatar

## Troubleshooting

- If images fail to upload, check the Firebase Storage rules
- If images fail to display, check the image URL in the profile and sessions
- If the app crashes, check the logs for error messages

## Additional Resources

- [Firebase Storage Documentation](https://firebase.google.com/docs/storage)
- [Firebase Storage Security Rules](https://firebase.google.com/docs/storage/security) 