import {onValueWritten} from "firebase-functions/v2/database";
import * as admin from "firebase-admin";

admin.initializeApp();

// Cloud Function for Debug: listens on '/sessions/{deviceId}/isActive'
export const syncSessionPresenceDebug = onValueWritten(
  "/sessions/{deviceId}/isActive",
  async (event) => {
    const deviceId: string = event.params.deviceId;
    const afterSnapshot = event.data.after;
    const isActive: boolean = afterSnapshot.val();

    await admin.firestore()
      .collection("sessions")
      .doc(deviceId)
      .update({
        isActive,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });
  }
);

export const syncSessionPresenceRelease = onValueWritten(
  "/sessions_release/{deviceId}/isActive",
  async (event) => {
    const deviceId: string = event.params.deviceId;
    const afterSnapshot = event.data.after;
    const isActive: boolean = afterSnapshot.val();

    await admin.firestore()
      .collection("sessions_release")
      .doc(deviceId)
      .update({
        isActive,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });
  }
);
