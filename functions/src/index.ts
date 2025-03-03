// index.ts - Firebase Cloud Functions (2nd Gen)

import { onValueWritten } from "firebase-functions/v2/database";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";
import * as functionsV2 from "firebase-functions/v2";
import express from "express";
import cors from "cors";
import { defineSecret } from "firebase-functions/params";

// -------------------------------------------------------------------
// Define your secrets
// -------------------------------------------------------------------
const SECRET_EMAIL_USER = defineSecret("EMAIL_USER");
const SECRET_EMAIL_PASSWORD = defineSecret("EMAIL_PASSWORD");

// -------------------------------------------------------------------
// Initialize admin only once
// -------------------------------------------------------------------
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// -------------------------------------------------------------------
// Single Express App for HTTP Functions
// -------------------------------------------------------------------
const app = express();
app.use(cors({ origin: true }));

// Optional health check endpoint
app.get("/_health", (req, res) => res.status(200).send("OK"));

// Export the Express app as an HTTP function, specifying secrets
export const api = functionsV2.https.onRequest(
  {
    secrets: [SECRET_EMAIL_USER, SECRET_EMAIL_PASSWORD],
  },
  async (req, res) => {
    try {
      // Example usage: create the transport at runtime
      const mailTransport = createMailTransport();
      await mailTransport.sendMail({
        from: "example@example.com",
        to: "test@example.com",
        subject: "Hello from Firebase Secrets!",
        text: "It works!",
      });

      res.send("Email sent!");
    } catch (error) {
      console.error("Error sending email:", error);
      res.status(500).send("Error sending email");
    }
  }
);

// -------------------------------------------------------------------
// Session Sync Functions (Event-driven)
// (These do not need email secrets, so no secrets array required.)
// -------------------------------------------------------------------
export const syncSessionPresenceDebug = onValueWritten(
  "/sessions/{deviceId}/isActive",
  async (event) => {
    const deviceId: string = event.params.deviceId;
    const afterSnapshot = event.data.after;
    const isActive: boolean = afterSnapshot.val();

    await admin
      .firestore()
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

    await admin
      .firestore()
      .collection("sessions_release")
      .doc(deviceId)
      .update({
        isActive,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });
  }
);

// -------------------------------------------------------------------
// Create a Nodemailer transport *at runtime* by reading secrets
// -------------------------------------------------------------------
function createMailTransport() {
  const user = SECRET_EMAIL_USER.value();
  const pass = SECRET_EMAIL_PASSWORD.value();

  return nodemailer.createTransport({
    service: "gmail",
    auth: { user, pass },
  });
}

// -------------------------------------------------------------------
// Reservation Confirmation (Event-driven & Callable)
// Each function that sends email must declare the secrets it needs
// -------------------------------------------------------------------

// 1) Debug environment
export const sendConfirmationEmailDebug = onDocumentUpdated(
  {
    document: "reservations/{reservationId}",
    secrets: [SECRET_EMAIL_USER, SECRET_EMAIL_PASSWORD],
  },
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) return;

    // Check if this is a web reservation being approved
    if (
      afterData.source === "web" &&
      beforeData.acceptance === "toConfirm" &&
      afterData.acceptance === "confirmed"
    ) {
      await sendReservationConfirmationEmail(afterData, event.params.reservationId);
    }
  }
);

// 2) Production environment
export const sendConfirmationEmailRelease = onDocumentUpdated(
  {
    document: "reservations_release/{reservationId}",
    secrets: [SECRET_EMAIL_USER, SECRET_EMAIL_PASSWORD],
  },
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) return;

    // Check if this is a web reservation being approved
    if (
      afterData.source === "web" &&
      beforeData.acceptance === "toConfirm" &&
      afterData.acceptance === "confirmed"
    ) {
      await sendReservationConfirmationEmail(afterData, event.params.reservationId);
    }
  }
);

// 3) Callable function to manually send confirmation emails
export const manualSendConfirmationEmail = onCall(
  {
    secrets: [SECRET_EMAIL_USER, SECRET_EMAIL_PASSWORD],
  },
  async (request) => {
    const { reservationId, email, isDebug } = request.data;

    if (!reservationId || !email) {
      throw new Error("Missing required parameters: reservationId and email");
    }

    const collection = isDebug ? "reservations" : "reservations_release";
    const docRef = admin.firestore().collection(collection).doc(reservationId);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      throw new Error(`Reservation with ID ${reservationId} not found`);
    }

    const reservation = docSnap.data();
    if (!reservation) {
      throw new Error(`No data found for reservation ${reservationId}`);
    }

    // Send the email
    await sendReservationConfirmationEmail(reservation, reservationId, email);

    // Update the reservation
    await docRef.update({
      emailSent: true,
      emailSentTimestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  }
);

// Helper to send the actual confirmation email
async function sendReservationConfirmationEmail(
  reservation: any,
  reservationId: string,
  forcedEmail?: string
) {
  let email = forcedEmail || reservation.email;

  // If no direct email field and no forced email, try extracting from notes
  if (!email && reservation.notes) {
    const emailMatch = reservation.notes.match(/Email:\s*([^\s;]+)/);
    if (emailMatch && emailMatch[1]) {
      email = emailMatch[1];
    }
  }

  if (!email) {
    console.error(`No email found for reservation ${reservationId}`);
    return { error: "No email found" };
  }

  const emailHtml = `
    <!DOCTYPE html>
    <html>
      <head>
        <style>
          /* your styles here */
        </style>
      </head>
      <body>
        <h1>Reservation Confirmed</h1>
        <p>Details go here...</p>
      </body>
    </html>
  `;

  try {
    // Create a transport each time we want to send an email
    const mailTransport = createMailTransport();

    await mailTransport.sendMail({
      from: '"Your Restaurant" <your-email@gmail.com>',
      to: email,
      subject: "Your Reservation Has Been Confirmed",
      html: emailHtml,
    });

    console.log(`Confirmation email sent to ${email} for reservation ${reservationId}`);
    return { success: true };
  } catch (error) {
    console.error("Error sending email:", error);
    return { error: error instanceof Error ? error.message : "Unknown error" };
  }
}

// -------------------------------------------------------------------
// New Web Reservation Notification (Event-driven)
// (These do not need email secrets, so no secrets array needed.)
// -------------------------------------------------------------------
export const newWebReservationNotificationDebug = onDocumentCreated(
  "reservations/{reservationId}",
  async (event) => {
    const reservation = event.data?.data();
    if (reservation?.source === "web" && reservation.acceptance === "toConfirm") {
      await sendNewReservationNotification(reservation, event.params.reservationId);
    }
  }
);

export const newWebReservationNotificationRelease = onDocumentCreated(
  "reservations_release/{reservationId}",
  async (event) => {
    const reservation = event.data?.data();
    if (reservation?.source === "web" && reservation.acceptance === "toConfirm") {
      await sendNewReservationNotification(reservation, event.params.reservationId);
    }
  }
);

// Send push notification for new web reservations
async function sendNewReservationNotification(reservation: any, reservationId: string) {
  try {
    const deviceTokensSnapshot = await admin.firestore().collection("device_tokens").get();
    if (deviceTokensSnapshot.empty) {
      console.log("No device tokens found for notifications");
      return { skipped: "No device tokens" };
    }

    const tokens: string[] = [];
    deviceTokensSnapshot.forEach((doc) => {
      const token = doc.data().token;
      if (token) tokens.push(token);
    });

    if (tokens.length === 0) {
      console.log("No valid device tokens found");
      return { skipped: "No valid tokens" };
    }

    const message = {
      notification: {
        title: "New Online Reservation Request",
        body: `${reservation.name} for ${reservation.numberOfPersons} people on ${reservation.dateString} at ${reservation.startTime}`,
      },
      data: {
        reservationId: reservationId,
        type: "new_web_reservation",
      },
      tokens: tokens,
    };

    const response = await admin.messaging().sendMulticast(message);
    console.log(`${response.successCount} notifications sent successfully`);
    return { success: true, sent: response.successCount };
  } catch (error) {
    console.error("Error sending notification:", error);
    return { error: error instanceof Error ? error.message : "Unknown error" };
  }
}

// -------------------------------------------------------------------
// Callable function to register device token
// (Does not use email secrets, so no secrets array required.)
// -------------------------------------------------------------------
export const registerDeviceToken = onCall({}, async (request) => {
  const { token, deviceId, userId } = request.data;

  if (!token || !deviceId) {
    throw new Error("Missing required parameters: token and deviceId");
  }

  await admin.firestore().collection("device_tokens").doc(deviceId).set({
    token,
    userId: userId || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

// Define table and reservation interfaces for type safety
interface TableConfig {
  id: number;
  name: string;
  maxCapacity: number;
}

// Updated checkAvailability function that accepts environment flag
export const checkAvailability = onCall({}, async (request) => {
  try {
    const { date, startTime, endTime, numberOfPersons, category, isDebug } = request.data;
    
    if (!date || !startTime || !endTime || !numberOfPersons || !category) {
      return { 
        available: false, 
        error: "Missing required parameters" 
      };
    }
    
    // Convert parameters to proper format
    const reqDate = new Date(date);
    const dateStr = formatDate(reqDate);
    
    console.log(`Checking availability for ${dateStr}, ${category}, ${startTime}-${endTime}, ${numberOfPersons} people (Environment: ${isDebug ? 'Debug' : 'Release'})`);
    
    // Get collection name based on environment
    const collection = isDebug ? "reservations" : "reservations_release";
    
    // Query existing reservations for the specific date
    const reservationsSnapshot = await admin.firestore()
      .collection(collection)
      .where("dateString", "==", dateStr)
      .get();
    
    console.log(`Found ${reservationsSnapshot.size} reservations for date ${dateStr} in ${collection}`);
    
    if (reservationsSnapshot.empty) {
      // No reservations on this date - all tables should be available
      const tables = getTablesConfig();
      
      console.log(`No reservations found - all tables available: ${tables.map(t => t.name).join(', ')}`);
      
      return {
        available: true,
        capacityAvailable: getTotalCapacity(),
        availableTables: tables.map(t => t.name).join(', '),
        message: `Tables available: ${tables.map(t => t.name).join(', ')}`
      };
    }
    
    // Get all reservations for this date
    const existingReservations: any[] = [];
    
    // Debug info about all reservations for this date
    console.log(`All reservations for ${dateStr}:`);
    
    // Helper to extract table IDs from tables array
    function extractTableIds(tablesArray: any[] | undefined): number[] {
      // The tables array might contain just indices (0, 1, 2) 
      // or it might contain table objects with an 'id' property
      const tableIds: number[] = [];
      
      if (!tablesArray || !Array.isArray(tablesArray) || tablesArray.length === 0) {
        return tableIds;
      }
      
      tablesArray.forEach((item, index) => {
        if (typeof item === 'number') {
          // If the item is a number, assume it's an index (0, 1, 2)
          // Add the index+1 as the table ID (to match T1, T2, etc.)
          tableIds.push(item + 1);
        } else if (typeof item === 'object' && item !== null) {
          // If the item is an object, check for 'id' property
          if (typeof item.id === 'number') {
            tableIds.push(item.id);
          } else {
            // If no 'id' property, use the array index+1
            tableIds.push(index + 1);
          }
        }
      });
      
      return tableIds;
    }
    
    reservationsSnapshot.forEach(doc => {
      const data = doc.data();
      console.log(`- Reservation ${data.name}: category=${data.category}, time=${data.startTime}-${data.endTime}, status=${data.status}, type=${data.reservationType}`);
      console.log(`  Tables data:`, data.tables);
      
      // Skip canceled, deleted, or waiting list reservations
      if (data.status === "canceled" || 
          data.status === "deleted" || 
          data.reservationType === "waitingList") {
        console.log(`  Skipping reservation (status=${data.status}, type=${data.reservationType})`);
        return;
      }
      
      // Extract table IDs (assuming tables is an array of indices or objects)
      const tableIds = extractTableIds(data.tables);
      console.log(`  Extracted table IDs: ${tableIds.join(', ')}`);
      
      existingReservations.push({
        id: data.id,
        name: data.name || "Unknown",
        startTime: data.startTime,
        endTime: data.endTime,
        numberOfPersons: data.numberOfPersons,
        tableIds: tableIds,
        category: data.category,
        status: data.status,
        reservationType: data.reservationType
      });
    });
    
    console.log(`Found ${existingReservations.length} active reservations for ${dateStr}`);
    
    // Find reservations that overlap with the requested time AND are in the same category
    const overlappingReservations = existingReservations.filter(res => {
      // Only consider reservations in the same category (lunch/dinner)
      const sameCategory = res.category === category;
      
      // Check for time overlap
      const timeOverlap = timeRangesOverlap(
        startTime, 
        endTime,
        res.startTime,
        res.endTime || calculateEndTime(res.startTime)
      );
      
      // Debug each reservation
      console.log(`Checking reservation ${res.name}: category=${res.category} (match=${sameCategory}), time=${res.startTime}-${res.endTime} (overlap=${timeOverlap})`);
      
      return sameCategory && timeOverlap;
    });
    
    console.log(`Found ${overlappingReservations.length} overlapping reservations for ${category} at ${startTime}-${endTime}`);
    
    // Get tables configuration
    const tables = getTablesConfig();
    
    // Track which specific tables are occupied based on reservation table IDs
    const occupiedTableIds = new Set<number>();
    
   
      // Look at the extracted table IDs from each reservation
      overlappingReservations.forEach(res => {
        if (res.tableIds && res.tableIds.length > 0) {
          res.tableIds.forEach((tableId: number) => {
            occupiedTableIds.add(tableId);
            console.log(`Table T${tableId} is occupied by ${res.name}`);
          });
        } else {
          console.log(`Reservation ${res.name} has no assigned tables, estimating based on party size`);
          
          // When no tables are explicitly assigned, we need to estimate
          // Each table seats 2 people
          const tablesNeeded = Math.ceil(res.numberOfPersons / 2);
          
          // For party sizes > 2, we need to allocate tables
          // For simplicity, just mark the first N available tables
          let assignedCount = 0;
          for (let i = 1; i <= 7 && assignedCount < tablesNeeded; i++) {
            if (!occupiedTableIds.has(i)) {
              occupiedTableIds.add(i);
              assignedCount++;
              console.log(`Estimated table T${i} for reservation ${res.name}`);
            }
          }
        }
      });
  
    
    // Check which tables are available
    const availableTables = tables.filter(table => !occupiedTableIds.has(table.id));
    
    // Calculate total available capacity - each table seats 2 people
    const availableCapacity = availableTables.length * 2;
    
    // Check if we have enough tables for the requested group size
    // Each table seats 2 people, so we need ceil(numberOfPersons/2) tables
    const tablesNeeded = Math.ceil(numberOfPersons / 2);
    const isAvailable = availableTables.length >= tablesNeeded;
    
    console.log(`Occupied tables: ${Array.from(occupiedTableIds).map(id => "T" + id).join(', ')}`);
    console.log(`Available tables: ${availableTables.map(t => t.name).join(', ')}`);
    console.log(`Tables needed for ${numberOfPersons} people: ${tablesNeeded}`);
    console.log(`Final availability result: ${isAvailable ? 'Available' : 'Not available'}`);
    
    // Return detailed availability result
    return {
      available: isAvailable,
      capacityAvailable: availableCapacity,
      totalTables: tables.length,
      totalCapacity: getTotalCapacity(),
      requestedCapacity: numberOfPersons,
      tablesNeeded: tablesNeeded,
      availableTables: availableTables.map(t => t.name).join(', '),
      occupiedTables: Array.from(occupiedTableIds).map(id => {
        return "T" + id;
      }).join(', '),
      message: isAvailable 
        ? `Tables available: ${availableTables.map(t => t.name).join(', ')}`
        : `Sorry, we don't have enough tables available for this time slot. We need ${tablesNeeded} tables for ${numberOfPersons} people, but only have ${availableTables.length} tables available.`
    };
  } catch (error) {
    console.error("Error checking availability:", error);
    return {
      available: false,
      error: "An error occurred while checking availability"
    };
  }
});

// Helper function to calculate end time if it's missing
function calculateEndTime(startTime: string): string {
  const [startHour, startMinute] = startTime.split(':').map(Number);
  let endHour = startHour + 1;
  let endMinute = startMinute + 45;
  
  if (endMinute >= 60) {
    endHour += 1;
    endMinute -= 60;
  }
  
  return `${endHour.toString().padStart(2, '0')}:${endMinute.toString().padStart(2, '0')}`;
}

// Helper functions
function formatDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function timeRangesOverlap(start1: string, end1: string, start2: string, end2: string): boolean {
  // Convert times to comparable format (minutes since midnight)
  const s1 = timeToMinutes(start1);
  const e1 = timeToMinutes(end1);
  const s2 = timeToMinutes(start2);
  const e2 = timeToMinutes(end2);
  
  // Check for overlap
  return Math.max(s1, s2) < Math.min(e1, e2);
}

function timeToMinutes(timeStr: string): number {
  const [hours, minutes] = timeStr.split(':').map(Number);
  return hours * 60 + minutes;
}

function getTablesConfig(): TableConfig[] {
  // Define table configuration to match your app
  // All tables have a capacity of 2 people as per your TableModel.swift
  return [
    { id: 1, name: "T1", maxCapacity: 2 },
    { id: 2, name: "T2", maxCapacity: 2 },
    { id: 3, name: "T3", maxCapacity: 2 },
    { id: 4, name: "T4", maxCapacity: 2 },
    { id: 5, name: "T5", maxCapacity: 2 },
    { id: 6, name: "T6", maxCapacity: 2 },
    { id: 7, name: "T7", maxCapacity: 2 },
  ];
}

function getTotalCapacity(): number {
  // Total seating capacity (all tables have capacity of 2)
  const tables = getTablesConfig();
  return tables.length * 2;
}