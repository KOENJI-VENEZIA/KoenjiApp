// index.ts - Firebase Cloud Functions (2nd Gen)

import { onValueWritten } from "firebase-functions/v2/database";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall, onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";
import * as functionsV2 from "firebase-functions/v2";
import express from "express";
import cors from "cors";
import { defineSecret } from "firebase-functions/params";
import { getFirestore } from 'firebase-admin/firestore';
import { drive as googleDrive } from 'googleapis/build/src/apis/drive/index.js';
import { JWT } from 'google-auth-library';
import { promises as fsPromises, createReadStream } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import { defineString } from 'firebase-functions/params';
import { SalesData } from './types.js';
import { onSchedule } from "firebase-functions/scheduler";
import { google } from 'googleapis';

// -------------------------------------------------------------------
// Define your secrets
// -------------------------------------------------------------------
const SECRET_EMAIL_USER = defineSecret("EMAIL_USER");
// OAuth2 credentials instead of password
const SECRET_CLIENT_ID = defineSecret("CLIENT_ID");
const SECRET_CLIENT_SECRET = defineSecret("CLIENT_SECRET");
const SECRET_REFRESH_TOKEN = defineSecret("REFRESH_TOKEN");
const driveClientEmail = defineString('DRIVE_CLIENT_EMAIL', { default: process.env.DRIVE_CLIENT_EMAIL || '' });
const drivePrivateKey = defineString('DRIVE_PRIVATE_KEY', { default: process.env.DRIVE_PRIVATE_KEY || '' });
const driveProjectId = defineString('DRIVE_PROJECT_ID', { default: process.env.DRIVE_PROJECT_ID || '' });
const driveFolderId = defineString('DRIVE_FOLDER_ID', { default: process.env.DRIVE_FOLDER_ID || '' });
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
    secrets: [SECRET_EMAIL_USER, SECRET_CLIENT_ID, SECRET_CLIENT_SECRET, SECRET_REFRESH_TOKEN],
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
// Uses OAuth2 authentication instead of password
// -------------------------------------------------------------------
function createMailTransport() {
  const user = SECRET_EMAIL_USER.value();
  const clientId = SECRET_CLIENT_ID.value();
  const clientSecret = SECRET_CLIENT_SECRET.value();
  const refreshToken = SECRET_REFRESH_TOKEN.value();

  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      type: "OAuth2",
      user: user,
      clientId: clientId,
      clientSecret: clientSecret,
      refreshToken: refreshToken
    }
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
    secrets: [SECRET_EMAIL_USER, SECRET_CLIENT_ID, SECRET_CLIENT_SECRET, SECRET_REFRESH_TOKEN],
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
    secrets: [SECRET_EMAIL_USER, SECRET_CLIENT_ID, SECRET_CLIENT_SECRET, SECRET_REFRESH_TOKEN],
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
    secrets: [SECRET_EMAIL_USER, SECRET_CLIENT_ID, SECRET_CLIENT_SECRET, SECRET_REFRESH_TOKEN],
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
// Helper to send the actual confirmation email
async function sendReservationConfirmationEmail(
  reservation: any,
  reservationId: string,
  forcedEmail?: string
) {
  let email = forcedEmail || reservation.email;

  // Extract email from notes if needed
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

  // Get preferred language from reservation, default to English if not specified
  const language = reservation.preferredLanguage || 'en';
  console.log(`Using language: ${language} for reservation ${reservationId}`);

  try {
    // Load template based on language - now async
    const template = await loadEmailTemplate('confirmation', language);
    
    // Prepare data for template
    const templateData = {
      name: reservation.name,
      date: reservation.dateString,
      time: reservation.startTime,
      people: reservation.numberOfPersons,
      tables: reservation.tables ? reservation.tables.join(', ') : '',
      id: reservationId,
    };
    
    // Render the template with data
    const emailHtml = renderEmailTemplate(template, templateData);

    // Get the correct subject for this language and type
    const emailSubject = getEmailSubject('confirmation', language);
    console.log(`Email subject: "${emailSubject}" for language: ${language}`);

    // Create a transport each time we want to send an email
    const mailTransport = createMailTransport();

    await mailTransport.sendMail({
      from: '"KOENJI. VENEZIA" <koenji.staff@gmail.com>',
      to: email,
      subject: emailSubject,
      html: emailHtml,
    });

    console.log(`Confirmation email sent to ${email} for reservation ${reservationId} in ${language}`);
    return { success: true };
  } catch (error) {
    console.error("Error sending email:", error);
    return { error: error instanceof Error ? error.message : "Unknown error" };
  }
}

// Helper function to get email subject in correct language
function getEmailSubject(type: string, language: string): string {
  type EmailType = 'confirmation' | 'decline';
  
  const emailType = type as EmailType;
  
  switch (emailType) {
    case 'confirmation':
      switch (language.toLowerCase()) {
        case 'it':
          return 'KOENJI. VENEZIA - Conferma di prenotazione';
        case 'jp':
          return 'KOENJI. VENEZIA - ご予約の確認';
        case 'en':
        default:
          return 'KOENJI. VENEZIA - Confirmation of your reservation';
      }
    case 'decline':
      switch (language.toLowerCase()) {
        case 'it':
          return 'KOENJI. VENEZIA - Aggiornamento sulla tua richiesta di prenotazione';
        case 'jp':
          return 'KOENJI. VENEZIA - ご予約リクエストについて';
        case 'en':
        default:
          return 'KOENJI. VENEZIA - Information about your reservation request';
      }
    default:
      return 'Koenji Restaurant';
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

// Update the sendEmail function to maintain original parameters but use localized subjects
export const sendEmail = onCall({
  secrets: [SECRET_EMAIL_USER, SECRET_CLIENT_ID, SECRET_CLIENT_SECRET, SECRET_REFRESH_TOKEN],
}, async (request) => {
  // Keep original parameter format
  const { to, subject, action, reservation, language = 'en' } = request.data;
  
  console.log(`Sending email action: ${action}, language: ${language}`);
  
  if (!to || !action || !reservation || !reservation.id) {
    throw new Error("Missing required parameters: to, action, and reservation with id are required");
  }
  
  const reservationId = reservation.id;
  
  try {
    // Get the full reservation data from Firestore
    const reservationDoc = await admin.firestore().collection("reservations").doc(reservationId).get();
    
    if (!reservationDoc.exists) {
      throw new Error(`Reservation ${reservationId} not found`);
    }
    
    // Merge the data from Firestore with any data provided in the request
    const fullReservation = {
      ...reservationDoc.data(),
      ...reservation,
      // Ensure preferredLanguage is set
      preferredLanguage: language || reservationDoc.data()?.preferredLanguage || 'en'
    };
    
    // Update the reservation with the language if it's provided and different
    const currentLanguage = reservationDoc.data()?.preferredLanguage;
    if (language && language !== currentLanguage) {
      await admin.firestore().collection("reservations").doc(reservationId).update({
        preferredLanguage: language
      });
      console.log(`Updated reservation ${reservationId} with preferredLanguage: ${language}`);
    }
    
    // Determine email type based on action
    let result;
    
    if (action === 'confirm') {
      // Use our specialized function for confirmation emails
      result = await sendReservationConfirmationEmail(fullReservation, reservationId, to);
    } else if (action === 'decline') {
      // Use our specialized function for decline emails
      const reason = request.data.reason || 'other';
      result = await sendDeclineEmail(fullReservation, reservationId, reason, to);
    } else {
      // For other actions, use the provided subject but with the same email structure
      console.log(`Using custom action: ${action} with provided subject: ${subject}`);
      
      // Load a generic template
      const template = await loadEmailTemplate('generic', language);
      
      // Prepare data for template
      const templateData = {
        name: fullReservation.name,
        date: fullReservation.dateString,
        time: fullReservation.startTime,
        people: fullReservation.numberOfPersons,
        tables: fullReservation.tables ? fullReservation.tables.join(', ') : '',
        message: request.data.message || '',
      };
      
      // Render the template with data
      const emailHtml = renderEmailTemplate(template, templateData);
      
      // Create a transport each time we want to send an email
      const mailTransport = createMailTransport();
      
      await mailTransport.sendMail({
        from: '"KOENJI. VENEZIA" <koenji.staff@gmail.com>',
        to: to,
        subject: subject,
        html: emailHtml,
      });
      
      console.log(`Custom email sent to ${to} for reservation ${reservationId}`);
      result = { success: true };
    }
    
    return result;
  } catch (error) {
    console.error("Error in sendEmail function:", error);
    throw new Error(error instanceof Error ? error.message : "Unknown error");
  }
});

// Helper function to get the decline reason text
function getDeclineReasonText(reason: string, language: string): string {
  type ReasonType = 'notEnoughCapacity' | 'internalIssue' | 'other';
  const reasonTexts: Record<ReasonType, Record<string, string>> = {
    notEnoughCapacity: {
      en: "Unfortunately, we do not have sufficient capacity for your requested party size at this time.",
      it: "Purtroppo, non abbiamo capacità sufficiente per il numero di persone richiesto in questo momento.",
      ja: "申し訳ありませんが、現時点ではリクエストされた人数分の十分な席がございません。"
    },
    internalIssue: {
      en: "We are experiencing some internal operational challenges at the requested time.",
      it: "Stiamo riscontrando alcune difficoltà operative interne nell'orario richiesto.",
      ja: "リクエストされた時間帯に内部的な運営上の課題が発生しています。"
    },
    other: {
      en: "We are unable to accommodate your reservation at this time.",
      it: "Non siamo in grado di accogliere la tua prenotazione in questo momento.",
      ja: "現時点ではご予約をお受けすることができません。"
    }
  };
  
  const reasonKey = reason as ReasonType;
  return reasonTexts[reasonKey]?.[language] || reasonTexts[reasonKey]?.['en'] || reasonTexts.other.en;
}

// For getFollowUpMessage function
function getFollowUpMessage(reason: string, language: string): string {
  type ReasonType = 'internalIssue' | 'other' | 'default';
  const followUpMessages: Record<ReasonType, Record<string, string>> = {
    internalIssue: {
      en: "One of our staff members will follow up with you by phone shortly to discuss alternatives.",
      it: "Un membro del nostro staff ti contatterà telefonicamente a breve per discutere alternative.",
      ja: "スタッフが代替案についてお話しするために、まもなくお電話でフォローアップいたします。"
    },
    other: {
      en: "We will try to follow up with you when possible to provide more information.",
      it: "Cercheremo di contattarti appena possibile per fornirti maggiori informazioni.",
      ja: "可能な限り、詳細情報を提供するためにフォローアップいたします。"
    },
    default: {
      en: "We would be happy to help you find an alternative date or time that works for you.",
      it: "Saremo lieti di aiutarti a trovare una data o un orario alternativi che funzionino per te.",
      ja: "お客様に合う代替の日付や時間をご案内できれば幸いです。"
    }
  };
  
  const reasonKey = reason as ReasonType;
  return followUpMessages[reasonKey]?.[language] || 
         followUpMessages[reasonKey]?.['en'] || 
         followUpMessages.default[language] || 
         followUpMessages.default.en;
}


// Function to load email template
// TO-DO: remove the debug info
// Simple in-memory cache for templates
const templateCache: Record<string, { template: string, timestamp: number }> = {};
const CACHE_TTL = 3600000; // 1 hour in milliseconds

// Add this function at the appropriate location in your code
async function logToFirestore(message: string, level: 'info' | 'warn' | 'error' = 'info', data?: any) {
  try {
    await admin.firestore().collection('function_logs').add({
      message,
      level,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      data: data || null
    });
  } catch (e) {
    // Silently fail if logging itself fails
    console.error('Failed to write to function_logs:', e);
  }
}

// Update the loadEmailTemplate function
async function loadEmailTemplate(templateName: string, language: string): Promise<string> {
  const supportedLanguages = ['en', 'it', 'ja'];
  const lang = supportedLanguages.includes(language) ? language : 'en';
  
  // Log basic info to Firestore
  await logToFirestore(`Template request - Name: ${templateName}, Language: ${language}, Using: ${lang}`, 'info');
  
  // Create a cache key
  const cacheKey = `${templateName}_${lang}`;
  
  // Check if we have a cached version that's not expired
  const now = Date.now();
  if (templateCache[cacheKey] && (now - templateCache[cacheKey].timestamp) < CACHE_TTL) {
    await logToFirestore(`Using cached template for ${cacheKey}`, 'info');
    return templateCache[cacheKey].template;
  }
  
  // GitHub raw content URL
  const baseUrl = 'https://raw.githubusercontent.com/KOENJI-VENEZIA/reservations_online/main';
  const templateUrl = `${baseUrl}/templates/emails/${lang}/${templateName}.html`;
  
  await logToFirestore(`Attempting to fetch template from: ${templateUrl}`, 'info');
  
  try {
    const response = await fetch(templateUrl);
    
    await logToFirestore(`Fetch response status: ${response.status} ${response.statusText}`, 'info', {
      url: templateUrl,
      status: response.status,
      statusText: response.statusText
    });
    
    if (!response.ok) {
      // If language-specific template fails, try English
      if (lang !== 'en') {
        await logToFirestore(`Template not found for ${lang}, trying English fallback`, 'warn', {
          url: templateUrl, 
          status: response.status
        });
        
        const fallbackUrl = `${baseUrl}/templates/emails/en/${templateName}.html`;
        await logToFirestore(`Fallback URL: ${fallbackUrl}`, 'info');
        
        const fallbackResponse = await fetch(fallbackUrl);
        await logToFirestore(`Fallback response status: ${fallbackResponse.status} ${fallbackResponse.statusText}`, 'info');
        
        if (fallbackResponse.ok) {
          const template = await fallbackResponse.text();
          await logToFirestore(`Successfully fetched English fallback template (${template.length} chars)`, 'info');
          // Cache the fallback template
          templateCache[cacheKey] = { template, timestamp: now };
          return template;
        }
      }
      
      await logToFirestore(`Failed to fetch template (HTTP ${response.status})`, 'error', {
        url: templateUrl,
        status: response.status,
        statusText: response.statusText
      });
      
      throw new Error(`Failed to fetch template (HTTP ${response.status}) from ${templateUrl}`);
    }
    
    const template = await response.text();
    await logToFirestore(`Successfully fetched ${lang} template (${template.length} chars)`, 'info');
    // Cache the template
    templateCache[cacheKey] = { template, timestamp: now };
    return template;
  } catch (error: any) {
    await logToFirestore(`Error fetching template: ${error.message}`, 'error', {
      templateName,
      language,
      url: templateUrl,
      errorMessage: error.message
    });
    
    // Return a simple fallback template
    return `
      <html><body>
        <h1>Reservation Information</h1>
        <p>Dear {{name}},</p>
        <p>Thank you for your reservation for {{people}} people on {{date}} at {{time}}.</p>
        <p>Language requested: ${language}, Language attempted: ${lang}</p>
        <p>Error: ${error.message}</p>
      </body></html>
    `;
  }
}

// Function to render a template with data
function renderEmailTemplate(template: string, data: any): string {
  // Replace all placeholders in format {{key}} with corresponding values from data
  return template.replace(/\{\{(\w+)\}\}/g, (match, key) => {
    return data[key] !== undefined ? data[key] : match;
  });
}

// Configure Google Drive API
const SCOPES = ['https://www.googleapis.com/auth/drive', 'https://www.googleapis.com/auth/spreadsheets'];

// Define localization for CSV headers
const csvHeaderTranslations = {
  'it': {
    'id': 'ID',
    'date': 'Data',
    'lastEditedOn': 'Ultima Modifica',
    'lunch_bento': 'Pranzo - Bento',
    'lunch_fatture': 'Pranzo - Fatture',
    'lunch_letturaCassa': 'Pranzo - Lettura Cassa',
    'lunch_persone': 'Pranzo - Persone',
    'lunch_yami': 'Pranzo - Yami',
    'lunch_yamiPulito': 'Pranzo - Yami Pulito',
    'dinner_cocai': 'Cena - Cocai',
    'dinner_fatture': 'Cena - Fatture',
    'dinner_letturaCassa': 'Cena - Lettura Cassa',
    'dinner_yami': 'Cena - Yami',
    'dinner_yamiPulito': 'Cena - Yami Pulito'
  },
  'ja': {
    'id': 'ID',
    'date': '日付',
    'lastEditedOn': '最終編集',
    'lunch_bento': 'ランチ - 弁当',
    'lunch_fatture': 'ランチ - 請求書',
    'lunch_letturaCassa': 'ランチ - レジ読み取り',
    'lunch_persone': 'ランチ - 人数',
    'lunch_yami': 'ランチ - ヤミ',
    'lunch_yamiPulito': 'ランチ - ヤミ（清算後）',
    'dinner_cocai': 'ディナー - コカイ',
    'dinner_fatture': 'ディナー - 請求書',
    'dinner_letturaCassa': 'ディナー - レジ読み取り',
    'dinner_yami': 'ディナー - ヤミ',
    'dinner_yamiPulito': 'ディナー - ヤミ（清算後）'
  },
  'en': {
    'id': 'ID',
    'date': 'Date',
    'lastEditedOn': 'Last Edited',
    'lunch_bento': 'Lunch - Bento',
    'lunch_fatture': 'Lunch - Invoices',
    'lunch_letturaCassa': 'Lunch - Cash Register',
    'lunch_persone': 'Lunch - People',
    'lunch_yami': 'Lunch - Yami',
    'lunch_yamiPulito': 'Lunch - Clean Yami',
    'dinner_cocai': 'Dinner - Cocai',
    'dinner_fatture': 'Dinner - Invoices',
    'dinner_letturaCassa': 'Dinner - Cash Register',
    'dinner_yami': 'Dinner - Yami',
    'dinner_yamiPulito': 'Dinner - Clean Yami'
  }
};

// Convert data to bilingual CSV (Italian and Japanese) and save locally
async function convertToBilingualCSV(data: SalesData[], date: string): Promise<string> {
  if (!data.length) {
    throw new Error(`No data to convert for date: ${date}`);
  }
  
  // Define CSV headers (technical keys) - exclude lastEditedOn
  const headerKeys = [
    'id',
    'date',
    'lunch_bento',
    'lunch_fatture',
    'lunch_letturaCassa',
    'lunch_persone',
    'lunch_yami',
    'lunch_yamiPulito',
    'dinner_cocai',
    'dinner_fatture',
    'dinner_letturaCassa',
    'dinner_yami',
    'dinner_yamiPulito'
  ];
  
  // Start building enhanced CSV content
  let csvContent = '';
  
  // Add bilingual report title
  csvContent += `"REPORT VENDITE / 売上レポート"\n`;
  
  // Format date for both languages
  const [year, month, day] = date.split('-');
  const italianDate = `${day}/${month}/${year}`;
  const japaneseDate = `${year}年${month}月${day}日`;
  
  csvContent += `"Data / 日付:","${italianDate} / ${japaneseDate}"\n\n`;
  
  // Create bilingual headers
  const bilingualHeaders = headerKeys.map(key => {
    const italianHeader = csvHeaderTranslations['it'][key as keyof (typeof csvHeaderTranslations)['it']];
    const japaneseHeader = csvHeaderTranslations['ja'][key as keyof (typeof csvHeaderTranslations)['ja']];
    return `"${italianHeader} / ${japaneseHeader}"`;
  });
  
  // Add data table with bilingual headers
  csvContent += bilingualHeaders.join(',') + '\n';
  
  // Format functions for bilingual display
  const formatDateBilingual = (dateStr: string): string => {
    try {
      const [year, month, day] = dateStr.split('-');
      return `${day}/${month}/${year} / ${year}年${month}月${day}日`;
    } catch (e) {
      return dateStr;
    }
  };
  
  // Add data rows
  data.forEach(record => {
    const row = headerKeys.map(header => {
      // Handle special formatting based on field type
      const value = record[header as keyof SalesData];
      
      // Format date fields
      if (header === 'date') {
        return `"${formatDateBilingual(value as string)}"`;
      }
      
      // Quote strings with commas, wrap in quotes and escape existing quotes
      if (typeof value === 'string' && value.includes(',')) {
        return `"${value.replace(/"/g, '""')}"`;
      }
      
      return value;
    });
    
    csvContent += row.join(',') + '\n';
  });
  
  // Add a bilingual summary section
  csvContent += `\n"RIEPILOGO / 概要"\n`;
  
  // Calculate lunch summary
  let lunchTotal = 0;
  let lunchPersons = 0;
  let lunchAverage = 0;
  
  // Calculate dinner summary
  let dinnerTotal = 0;
  
  // Process data for summary
  data.forEach(record => {
    // Lunch data
    lunchTotal += Number(record.lunch_letturaCassa) || 0;
    lunchPersons += Number(record.lunch_persone) || 0;
    
    // Dinner data
    dinnerTotal += Number(record.dinner_letturaCassa) || 0;
  });
  
  // Calculate averages
  lunchAverage = lunchPersons > 0 ? lunchTotal / lunchPersons : 0;
  
  // Add lunch summary
  csvContent += `\n"DATI PRANZO / ランチデータ"\n`;
  
  csvContent += `"Totale Incasso Pranzo / ランチ総売上","${lunchTotal.toFixed(2)}"\n`;
  csvContent += `"Totale Persone Pranzo / ランチ総人数","${lunchPersons}"\n`;
  csvContent += `"Media per Persona / 一人当たりの平均","${lunchAverage.toFixed(2)}"\n`;
  
  // Add dinner summary
  csvContent += `\n"DATI CENA / ディナーデータ"\n`;
  
  csvContent += `"Totale Incasso Cena / ディナー総売上","${dinnerTotal.toFixed(2)}"\n`;
  
  // Add totals
  csvContent += `\n"TOTALI / 合計"\n`;
  
  csvContent += `"Totale Giornaliero / 日次合計","${(lunchTotal + dinnerTotal).toFixed(2)}"\n`;
  
  // Add generation timestamp
  const now = new Date();
  const italianTimestamp = `${now.getDate()}/${now.getMonth() + 1}/${now.getFullYear()} ${now.getHours()}:${String(now.getMinutes()).padStart(2, '0')}`;
  const japaneseTimestamp = `${now.getFullYear()}年${now.getMonth() + 1}月${now.getDate()}日 ${now.getHours()}:${String(now.getMinutes()).padStart(2, '0')}`;
  
  csvContent += `\n"Report generato il / レポート生成日時","${italianTimestamp} / ${japaneseTimestamp}"\n`;
  
  // Write to temp file
  const tempFilePath = join(tmpdir(), `sales_${date}_bilingual.csv`);
  await fsPromises.writeFile(tempFilePath, csvContent);
  
  return tempFilePath;
}

// Function to create or update a Google Sheet with sales data
async function updateSalesGoogleSheet(data: SalesData[], date: string): Promise<string> {
  // Get credentials from defined parameters
  const credentials = {
    client_email: driveClientEmail.value(),
    private_key: drivePrivateKey.value().replace(/\\n/g, '\n'),
    project_id: driveProjectId.value(),
  };
  
  try {
    // Authenticate with Google
    const auth = new JWT({
      email: credentials.client_email,
      key: credentials.private_key,
      scopes: SCOPES
    });
    
    // Initialize Google Drive and Sheets APIs
    const drive = googleDrive({
      version: 'v3',
      auth
    });
    
    const sheets = google.sheets({
      version: 'v4',
      auth
    });
    
    // Define target folder ID in Google Drive
    const folderId = driveFolderId.value();
    
    // Extract year and month from date
    const [year, month] = date.split('-');
    
    // Format month name in Italian
    const monthNames = {
      '01': 'Gennaio',
      '02': 'Febbraio',
      '03': 'Marzo',
      '04': 'Aprile',
      '05': 'Maggio',
      '06': 'Giugno',
      '07': 'Luglio',
      '08': 'Agosto',
      '09': 'Settembre',
      '10': 'Ottobre',
      '11': 'Novembre',
      '12': 'Dicembre'
    };
    
    const monthName = monthNames[month as keyof typeof monthNames] || month;
    const fileName = `Koenji Sales ${monthName} ${year}`;
    const sheetTitle = `${monthName} ${year}`;
    
    // Check if file already exists
    let spreadsheetId = '';
    let fileExists = false;
    
    try {
      const response = await drive.files.list({
        q: `name='${fileName}' and '${folderId}' in parents and trashed=false`,
        fields: 'files(id, name)',
        spaces: 'drive'
      });
      
      if (response.data.files && response.data.files.length > 0) {
        spreadsheetId = response.data.files[0].id || '';
        fileExists = true;
        console.log(`Found existing spreadsheet: ${fileName} with ID: ${spreadsheetId}`);
      }
    } catch (error) {
      console.error('Error checking for existing file:', error);
    }
    
    // If file doesn't exist, create a new one
    if (!fileExists) {
      const resource = {
        name: fileName,
        mimeType: 'application/vnd.google-apps.spreadsheet',
        parents: [folderId]
      };
      
      const file = await drive.files.create({
        requestBody: resource,
        fields: 'id'
      });
      
      spreadsheetId = file.data.id || '';
      console.log(`Created new spreadsheet: ${fileName} with ID: ${spreadsheetId}`);
      
      // Copy the MONTH_TEMPLATE to create the new sheet with formatting
      await copyTemplateSheet(spreadsheetId, 'MONTH_TEMPLATE', sheetTitle);
    } else {
      // Check if the sheet for this month exists, if not create it from template
      try {
        await copyTemplateSheet(spreadsheetId, 'MONTH_TEMPLATE', sheetTitle);
      } catch (error) {
        console.log(`Sheet ${sheetTitle} already exists or template not found`);
      }
    }
    
    // ... rest of the function remains the same ...
    
    if (!spreadsheetId) {
      throw new Error('Failed to create or find spreadsheet');
    }
    
    // Get existing sheets to check if the month sheet already exists
    const spreadsheet = await sheets.spreadsheets.get({
      spreadsheetId
    });
    
    const existingSheets = spreadsheet.data.sheets || [];
    let monthSheetExists = false;
    let monthSheetId = 0;
    
    for (const sheet of existingSheets) {
      if (sheet.properties?.title === sheetTitle) {
        monthSheetExists = true;
        monthSheetId = sheet.properties.sheetId || 0;
        break;
      }
    }
    
    // If the month sheet doesn't exist, create it
    if (!monthSheetExists) {
      const addSheetResponse = await sheets.spreadsheets.batchUpdate({
        spreadsheetId,
        requestBody: {
          requests: [
            {
              addSheet: {
                properties: {
                  title: sheetTitle
                }
              }
            }
          ]
        }
      });
      
      monthSheetId = addSheetResponse.data.replies?.[0].addSheet?.properties?.sheetId || 0;
      console.log(`Created new sheet: ${sheetTitle} with ID ${monthSheetId}`);
    }
    
    // Format the data for the sheet
    // First, prepare the headers
    const headers = [
      ['ID', 'Data / 日付', 'Pranzo - Bento / ランチ - 弁当', 'Pranzo - Fatture / ランチ - 請求書', 
       'Pranzo - Lettura Cassa / ランチ - レジ読み取り', 'Pranzo - Persone / ランチ - 人数',
       'Pranzo - Yami / ランチ - ヤミ', 'Pranzo - Yami Pulito / ランチ - ヤミ（清算後）',
       'Cena - Cocai / ディナー - コカイ', 'Cena - Fatture / ディナー - 請求書',
       'Cena - Lettura Cassa / ディナー - レジ読み取り', 'Cena - Yami / ディナー - ヤミ',
       'Cena - Yami Pulito / ディナー - ヤミ（清算後）']
    ];
    
    // Format date for display
    const formatDateBilingual = (dateStr: string): string => {
      try {
        const [year, month, day] = dateStr.split('-');
        return `${day}/${month}/${year} / ${year}年${month}月${day}日`;
      } catch (e) {
        return dateStr;
      }
    };
    
    // Get all days in the month
    const daysInMonth = new Date(parseInt(year), parseInt(month), 0).getDate();
    const allDaysInMonth: string[] = [];
    for (let i = 1; i <= daysInMonth; i++) {
      const formattedDay = i.toString().padStart(2, '0');
      allDaysInMonth.push(`${year}-${month}-${formattedDay}`);
    }
    
    // Create a map of existing data by date
    const dataByDate: Record<string, any[]> = {};
    
    // Add the current data to the map
    data.forEach(record => {
      if (!dataByDate[record.date]) {
        dataByDate[record.date] = [];
      }
      dataByDate[record.date].push(record);
    });
    
    // Get existing data for this month
    try {
      const dataResponse = await sheets.spreadsheets.values.get({
        spreadsheetId,
        range: sheetTitle
      });
      
      if (dataResponse.data.values && dataResponse.data.values.length > 1) {
        // Filter out the data for the current date (skip header row)
        dataResponse.data.values.slice(1).filter(row => {
          // Check if this is a data row (not a summary row)
          if (row.length < 2) return false;
          
          // Extract the date from the bilingual format
          const dateCell = row[1] || '';
          const datePart = dateCell.split(' / ')[0]; // Get the Italian format date
          if (!datePart) return true; // Keep rows without dates
          
          const [day, month, year] = datePart.split('/');
          const rowDate = `${year}-${month}-${day}`;
          
          // Keep the row if it's not for the current date
          if (rowDate !== date) {
            // Add this existing data to our map
            if (!dataByDate[rowDate] && rowDate.startsWith(year) && rowDate.split('-')[1] === month) {
              // Create a placeholder record for this date
              const placeholderRecord = {
                id: row[0] || '',
                date: rowDate,
                lunch_bento: parseFloat(row[2]) || 0,
                lunch_fatture: parseFloat(row[3]) || 0,
                lunch_letturaCassa: parseFloat(row[4]) || 0,
                lunch_persone: parseFloat(row[5]) || 0,
                lunch_yami: parseFloat(row[6]) || 0,
                lunch_yamiPulito: parseFloat(row[7]) || 0,
                dinner_cocai: parseFloat(row[8]) || 0,
                dinner_fatture: parseFloat(row[9]) || 0,
                dinner_letturaCassa: parseFloat(row[10]) || 0,
                dinner_yami: parseFloat(row[11]) || 0,
                dinner_yamiPulito: parseFloat(row[12]) || 0
              };
              dataByDate[rowDate] = [placeholderRecord];
            }
            return true;
          }
          return false;
        });
      }
    } catch (error) {
      console.log('No existing data found for this month, starting fresh');
    }
    
    // Prepare rows for all days in the month
    const allRows: any[][] = [];
    
    // For each day in the month
    allDaysInMonth.forEach(dateStr => {
      if (dataByDate[dateStr] && dataByDate[dateStr].length > 0) {
        // We have data for this date, use it
        dataByDate[dateStr].forEach(record => {
          allRows.push([
            record.id,
            formatDateBilingual(record.date),
            record.lunch_bento,
            record.lunch_fatture,
            record.lunch_letturaCassa,
            record.lunch_persone,
            record.lunch_yami,
            record.lunch_yamiPulito,
            record.dinner_cocai,
            record.dinner_fatture,
            record.dinner_letturaCassa,
            record.dinner_yami,
            record.dinner_yamiPulito
          ]);
        });
      } else {
        // No data for this date, create a row with zeros
        allRows.push([
          '', // No ID for placeholder rows
          formatDateBilingual(dateStr),
          0, // lunch_bento
          0, // lunch_fatture
          0, // lunch_letturaCassa
          0, // lunch_persone
          0, // lunch_yami
          0, // lunch_yamiPulito
          0, // dinner_cocai
          0, // dinner_fatture
          0, // dinner_letturaCassa
          0, // dinner_yami
          0  // dinner_yamiPulito
        ]);
      }
    });
    
    // Sort the rows by date
    allRows.sort((a, b) => {
      const dateA = a[1] || '';
      const dateB = b[1] || '';
      
      // Extract the date from the bilingual format
      const datePartA = dateA.split(' / ')[0]; // Get the Italian format date
      const datePartB = dateB.split(' / ')[0]; // Get the Italian format date
      
      if (!datePartA || !datePartB) return 0;
      
      const [dayA, monthA, yearA] = datePartA.split('/');
      const [dayB, monthB, yearB] = datePartB.split('/');
      
      const dateObjA = new Date(`${yearA}-${monthA}-${dayA}`);
      const dateObjB = new Date(`${yearB}-${monthB}-${dayB}`);
      
      return dateObjA.getTime() - dateObjB.getTime();
    });
    
    // Calculate summary data for the month
    let lunchBentoTotal = 0;
    let lunchFattureTotal = 0;
    let lunchLetturaCassaTotal = 0;
    let lunchPersoneTotal = 0;
    let lunchYamiTotal = 0;
    let lunchYamiPulitoTotal = 0;
    let dinnerCocaiTotal = 0;
    let dinnerFattureTotal = 0;
    let dinnerLetturaCassaTotal = 0;
    let dinnerYamiTotal = 0;
    let dinnerYamiPulitoTotal = 0;
    
    // Calculate totals from all rows
    for (const row of allRows) {
      if (row.length >= 13) { // Make sure it's a data row
        lunchBentoTotal += Number(row[2]) || 0;
        lunchFattureTotal += Number(row[3]) || 0;
        lunchLetturaCassaTotal += Number(row[4]) || 0;
        lunchPersoneTotal += Number(row[5]) || 0;
        lunchYamiTotal += Number(row[6]) || 0;
        lunchYamiPulitoTotal += Number(row[7]) || 0;
        dinnerCocaiTotal += Number(row[8]) || 0;
        dinnerFattureTotal += Number(row[9]) || 0;
        dinnerLetturaCassaTotal += Number(row[10]) || 0;
        dinnerYamiTotal += Number(row[11]) || 0;
        dinnerYamiPulitoTotal += Number(row[12]) || 0;
      }
    }
    
    // Add a summary row to the data
    const summaryRow = [
      '', // No ID for summary row
      'RIEPILOGO / 概要', // Use this as the "date" for the summary row
      lunchBentoTotal.toFixed(2),
      lunchFattureTotal.toFixed(2),
      lunchLetturaCassaTotal.toFixed(2),
      lunchPersoneTotal,
      lunchYamiTotal.toFixed(2),
      lunchYamiPulitoTotal.toFixed(2),
      dinnerCocaiTotal.toFixed(2),
      dinnerFattureTotal.toFixed(2),
      dinnerLetturaCassaTotal.toFixed(2),
      dinnerYamiTotal.toFixed(2),
      dinnerYamiPulitoTotal.toFixed(2)
    ];
    
    // Add the summary row to the end of the data rows
    allRows.push(summaryRow);
    
    // Combine headers and rows
    const allValues = [...headers, ...allRows];
    
    // Clear existing data in the sheet
    await sheets.spreadsheets.values.clear({
      spreadsheetId,
      range: sheetTitle
    });
    
    // Update the sheet with all the data
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: `${sheetTitle}!A1`,
      valueInputOption: 'USER_ENTERED',
      requestBody: {
        values: allValues
      }
    });
    
    // Update the annual summary sheet
    await updateAnnualSummarySheet(spreadsheetId, year);
    
    return spreadsheetId;
  } catch (error: any) {
    console.error('Google Sheets API Error:', {
      error: error.message,
      stack: error.stack
    });
    
    throw new Error(`Google Sheets error: ${error.message}`);
  }
}

// Function to update the annual summary sheet
async function updateAnnualSummarySheet(spreadsheetId: string, year: string): Promise<void> {
  try {
    // Get credentials from defined parameters
    const credentials = {
      client_email: driveClientEmail.value(),
      private_key: drivePrivateKey.value().replace(/\\n/g, '\n'),
      project_id: driveProjectId.value(),
    };
    
    // Authenticate with Google
    const auth = new JWT({
      email: credentials.client_email,
      key: credentials.private_key,
      scopes: SCOPES
    });
    
    // Initialize Google Sheets API
    const sheets = google.sheets({
      version: 'v4',
      auth
    });
    
    // Annual summary sheet title
    const annualSheetTitle = `Riepilogo ${year}`;
    
    // Check if the annual summary sheet exists, if not create it from template
    try {
      await copyTemplateSheet(spreadsheetId, 'YEAR_TEMPLATE', annualSheetTitle);
      console.log(`Created or found annual summary sheet: ${annualSheetTitle}`);
    } catch (error) {
      console.log(`Error with annual summary sheet template: ${error}`);
      // Continue with the function even if template copying fails
    }
    
    // Get all sheets in the spreadsheet
    const spreadsheet = await sheets.spreadsheets.get({
      spreadsheetId
    });
    
    const allSheets = spreadsheet.data.sheets || [];
    
    // Filter out the annual summary sheet and any template sheets
    const dataSheets = allSheets.filter(sheet => {
      const title = sheet.properties?.title || '';
      return title !== annualSheetTitle && 
             title !== 'MONTH_TEMPLATE' && 
             title !== 'YEAR_TEMPLATE' &&
             !title.includes('Riepilogo') && 
             title.includes(year);
    });
    
    if (dataSheets.length === 0) {
      console.log('No month sheets found for annual summary');
      return;
    }
    
    // Prepare headers for the annual summary
    const headers = [
      ['RIEPILOGO ANNUALE / 年次レポート', year],
      [''],
      ['Mese / 月', 'Pranzo Incasso / ランチ売上', 'Pranzo Persone / ランチ人数', 
       'Cena Incasso / ディナー売上', 'Totale / 合計']
    ];
    
    // Month names in Italian and Japanese
    const monthNames = [
      'Gennaio / 1月', 'Febbraio / 2月', 'Marzo / 3月', 'Aprile / 4月', 
      'Maggio / 5月', 'Giugno / 6月', 'Luglio / 7月', 'Agosto / 8月', 
      'Settembre / 9月', 'Ottobre / 10月', 'Novembre / 11月', 'Dicembre / 12月'
    ];
    
    // Collect data for each month
    const monthlyData: Record<string, number[]> = {};
    let yearlyLunchTotal = 0;
    let yearlyLunchPersons = 0;
    let yearlyDinnerTotal = 0;
    
    for (const sheet of dataSheets) {
      const sheetTitle = sheet.properties?.title || '';
      // Extract month name (before the slash)
      const monthName = sheetTitle.split(' / ')[0]; 
      
      // Find the corresponding bilingual month name
      let bilingualMonthName = '';
      for (const name of monthNames) {
        if (name.startsWith(monthName)) {
          bilingualMonthName = name;
          break;
        }
      }
      
      if (!bilingualMonthName) continue;
      
      // Get the summary data from each month sheet
      try {
        // First, get all values to find where the summary starts
        const allValues = await sheets.spreadsheets.values.get({
          spreadsheetId,
          range: sheetTitle
        });
        
        const values = allValues.data.values || [];
        let summaryStartRow = 0;
        
        // Find where the summary section starts
        for (let i = 0; i < values.length; i++) {
          if (values[i][0] === 'RIEPILOGO / 概要') {
            summaryStartRow = i;
            break;
          }
        }
        
        if (summaryStartRow === 0) {
          console.log(`No summary found in sheet ${sheetTitle}`);
          continue;
        }
        
        // Get the summary section
        const summaryValues = values.slice(summaryStartRow);
        
        // Extract the totals
        let lunchTotal = 0;
        let lunchPersons = 0;
        let dinnerTotal = 0;
        
        for (const row of summaryValues) {
          if (row[0]?.includes('Totale Incasso Pranzo')) {
            lunchTotal = parseFloat(row[1] || '0');
          } else if (row[0]?.includes('Totale Persone Pranzo')) {
            lunchPersons = parseInt(row[1] || '0');
          } else if (row[0]?.includes('Totale Incasso Cena')) {
            dinnerTotal = parseFloat(row[1] || '0');
          }
        }
        
        // Store the data by month
        monthlyData[bilingualMonthName] = [lunchTotal, lunchPersons, dinnerTotal];
        
        // Add to yearly totals
        yearlyLunchTotal += lunchTotal;
        yearlyLunchPersons += lunchPersons;
        yearlyDinnerTotal += dinnerTotal;
      } catch (error) {
        console.log(`Error getting data from sheet ${sheetTitle}:`, error);
      }
    }
    
    // Prepare rows for each month in order
    const rows = monthNames.map(monthName => {
      const data = monthlyData[monthName] || [0, 0, 0];
      const [lunchTotal, lunchPersons, dinnerTotal] = data;
      const total = lunchTotal + dinnerTotal;
      
      return [
        monthName,
        lunchTotal.toFixed(2),
        lunchPersons.toString(),
        dinnerTotal.toFixed(2),
        total.toFixed(2)
      ];
    });
    
    // Add yearly summary
    const yearlyTotal = yearlyLunchTotal + yearlyDinnerTotal;
    const yearlyAverage = yearlyLunchPersons > 0 ? yearlyLunchTotal / yearlyLunchPersons : 0;
    
    const summaryRows = [
      [''],
      ['TOTALI ANNUALI / 年間合計'],
      ['Totale Pranzo / ランチ合計', yearlyLunchTotal.toFixed(2)],
      ['Totale Persone Pranzo / ランチ人数合計', yearlyLunchPersons.toString()],
      ['Media per Persona / 一人当たり平均', yearlyAverage.toFixed(2)],
      ['Totale Cena / ディナー合計', yearlyDinnerTotal.toFixed(2)],
      ['TOTALE ANNUALE / 年間総合計', yearlyTotal.toFixed(2)]
    ];
    
    // Combine all data
    const values = [...headers, ...rows, ...summaryRows];
    
    // Clear existing data in the annual summary sheet
    await sheets.spreadsheets.values.clear({
      spreadsheetId,
      range: 'Riepilogo Annuale / 年次レポート'
    });
    
    // Update the annual summary sheet
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: 'Riepilogo Annuale / 年次レポート!A1',
      valueInputOption: 'USER_ENTERED',
      requestBody: {
        values
      }
    });
    
    console.log('Annual summary sheet updated successfully');
  } catch (error: any) {
    console.error('Error updating annual summary:', error.message);
  }
}

// Update the scheduled export to use Google Sheets
export const scheduledExportSalesToDrive = onSchedule({
  schedule: '0 5 * * *', // Run at 5 AM every day
  timeZone: 'Europe/Rome', // Set your timezone
  retryCount: 3 // Add retry attempts
}, async (context) => {
  try {
    const dateToExport = getYesterdayDate();
    const salesData = await fetchSalesData(dateToExport);
    
    if (salesData.length === 0) {
      console.log(`No sales data found for ${dateToExport}, skipping export`);
      return;
    }
    
    // First, create the CSV file for backward compatibility
    const csvFilePath = await convertToBilingualCSV(salesData, dateToExport);
    
    // Upload CSV to Google Drive (maintaining existing functionality)
    await uploadToDrive(csvFilePath, dateToExport, 'bilingual');
    
    // Also update the Google Sheet
    const spreadsheetId = await updateSalesGoogleSheet(salesData, dateToExport);
    
    console.log(`Successfully updated sales data for ${dateToExport} in spreadsheet: ${spreadsheetId}`);
    return;
  } catch (error) {
    console.error('Scheduled export failed:', error instanceof Error ? error.message : String(error));
    return;
  }
});

// Update the HTTP endpoint to support Google Sheets
export const exportSalesToDrive = onRequest(async (req, res) => {
  try {
    // Type-safe handling of date parameter
    const dateParam = req.query.date;
    // Get the date for which to export data (default to yesterday if not specified)
    const dateToExport = typeof dateParam === 'string' ? dateParam : getYesterdayDate();
    
    // Get language parameter
    const langParam = req.query.lang;
    
    // Get format parameter (new)
    const formatParam = req.query.format;
    const useSheets = formatParam === 'sheets';
    
    // Fetch sales release data from Firestore
    const salesData = await fetchSalesData(dateToExport);
    
    if (salesData.length === 0) {
      res.status(404).send({
        success: false,
        message: `No sales data found for date: ${dateToExport}`
      });
      return;
    }
    
    // If sheets format is requested or no specific format is requested and no language is specified
    if (useSheets || (!langParam && !formatParam)) {
      // Use Google Sheets
      const spreadsheetId = await updateSalesGoogleSheet(salesData, dateToExport);
      
      res.status(200).send({
        success: true,
        message: `Data exported successfully to Google Sheets with ID: ${spreadsheetId}`,
        date: dateToExport,
        format: 'Google Sheets',
        records: salesData.length
      });
    } else {
      // Use the original CSV export
      let csvFilePath: string;
      let language: string;
      
      // If a specific language is requested, use that, otherwise use bilingual
      if (typeof langParam === 'string' && ['it', 'ja', 'en'].includes(langParam)) {
        language = langParam;
        csvFilePath = await convertToCSV(salesData, dateToExport, language);
      } else {
        // Default to bilingual (Italian and Japanese)
        language = 'bilingual';
        csvFilePath = await convertToBilingualCSV(salesData, dateToExport);
      }
      
      // Upload to Google Drive
      const fileId = await uploadToDrive(csvFilePath, dateToExport, language);
      
      res.status(200).send({
        success: true,
        message: `CSV exported successfully to Google Drive with ID: ${fileId}`,
        date: dateToExport,
        language: language,
        records: salesData.length
      });
    }
  } catch (error: unknown) {
    console.error('Error exporting sales data:', 
      error instanceof Error ? error.message : String(error));
    res.status(500).send({
      success: false,
      message: 'Failed to export sales data',
      error: error instanceof Error ? error.message : String(error)
    });
  }
});

// Helper function to get yesterday's date in YYYY-MM-DD format
function getYesterdayDate(): string {
  const date = new Date();
  date.setDate(date.getDate() - 1);
  return date.toISOString().split('T')[0];
}

// Fetch sales data from Firestore
async function fetchSalesData(date: string): Promise<SalesData[]> {
  const db = getFirestore();
  const salesCollection = db.collection('sales_release');
  const snapshot = await salesCollection.where('dateString', '==', date).get();
  
  if (snapshot.empty) {
    console.log(`No sales data found for date: ${date}`);
    return [];
  }
  
  return snapshot.docs.map(doc => {
    const data = doc.data();
    return {
      id: doc.id,
      date: data.dateString,
      lastEditedOn: data.lastEditedOn ? new Date(data.lastEditedOn).toISOString() : '',
      // Lunch data
      lunch_bento: data.lunch?.bento || 0,
      lunch_fatture: data.lunch?.fatture || 0,
      lunch_letturaCassa: data.lunch?.letturaCassa || 0,
      lunch_persone: data.lunch?.persone || 0,
      lunch_yami: data.lunch?.yami || 0,
      lunch_yamiPulito: data.lunch?.yamiPulito || 0,
      // Dinner data
      dinner_cocai: data.dinner?.cocai || 0,
      dinner_fatture: data.dinner?.fatture || 0,
      dinner_letturaCassa: data.dinner?.letturaCassa || 0,
      dinner_yami: data.dinner?.yami || 0,
      dinner_yamiPulito: data.dinner?.yamiPulito || 0
    };
  });
}

// Convert data to CSV and save locally
async function convertToCSV(data: SalesData[], date: string, language: string = 'it'): Promise<string> {
  if (!data.length) {
    throw new Error(`No data to convert for date: ${date}`);
  }
  
  // Validate language and default to Italian if not supported
  if (!['it', 'ja', 'en'].includes(language)) {
    language = 'it';
  }
  
  // Define CSV headers (technical keys)
  const headerKeys = [
    'id',
    'date',
    'lastEditedOn',
    'lunch_bento',
    'lunch_fatture',
    'lunch_letturaCassa',
    'lunch_persone',
    'lunch_yami',
    'lunch_yamiPulito',
    'dinner_cocai',
    'dinner_fatture',
    'dinner_letturaCassa',
    'dinner_yami',
    'dinner_yamiPulito'
  ];
  
  // Get translated headers
  const translatedHeaders = headerKeys.map(key => 
    csvHeaderTranslations[language as keyof typeof csvHeaderTranslations][key as keyof (typeof csvHeaderTranslations)['it']]
  );
  
  // Section titles based on language
  const sectionTitles = {
    'it': {
      title: 'REPORT VENDITE',
      date: 'Data:',
      summary: 'RIEPILOGO',
      lunch: 'DATI PRANZO',
      dinner: 'DATI CENA',
      totals: 'TOTALI',
      generated: 'Report generato il'
    },
    'ja': {
      title: '売上レポート',
      date: '日付:',
      summary: '概要',
      lunch: 'ランチデータ',
      dinner: 'ディナーデータ',
      totals: '合計',
      generated: 'レポート生成日時'
    },
    'en': {
      title: 'SALES REPORT',
      date: 'Date:',
      summary: 'SUMMARY',
      lunch: 'LUNCH DATA',
      dinner: 'DINNER DATA',
      totals: 'TOTALS',
      generated: 'Report generated on'
    }
  };
  
  const titles = sectionTitles[language as keyof typeof sectionTitles];
  
  // Format date for better readability
  const formatDateString = (dateStr: string): string => {
    try {
      const [year, month, day] = dateStr.split('-');
      if (language === 'ja') {
        return `${year}年${month}月${day}日`;
      } else if (language === 'it') {
        return `${day}/${month}/${year}`;
      }
      return `${day}/${month}/${year}`;
    } catch (e) {
      return dateStr;
    }
  };
  
  // Format timestamp for better readability
  const formatTimestamp = (timestamp: string): string => {
    if (!timestamp) return '';
    try {
      const date = new Date(timestamp);
      if (language === 'ja') {
        return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日 ${date.getHours()}:${String(date.getMinutes()).padStart(2, '0')}`;
      }
      return `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()} ${date.getHours()}:${String(date.getMinutes()).padStart(2, '0')}`;
    } catch (e) {
      return timestamp;
    }
  };
  
  // Start building enhanced CSV content
  let csvContent = '';
  
  // Add report title and date
  csvContent += `"${titles.title}"\n`;
  csvContent += `"${titles.date}","${formatDateString(date)}"\n\n`;
  
  // Add data table with headers
  csvContent += translatedHeaders.join(',') + '\n';
  
  // Add data rows
  data.forEach(record => {
    const row = headerKeys.map(header => {
      // Handle special formatting based on field type
      const value = record[header as keyof SalesData];
      
      // Format date fields
      if (header === 'date') {
        return `"${formatDateString(value as string)}"`;
      }
      
      // Format timestamp fields
      if (header === 'lastEditedOn') {
        return `"${formatTimestamp(value as string)}"`;
      }
      
      // Quote strings with commas, wrap in quotes and escape existing quotes
      if (typeof value === 'string' && value.includes(',')) {
        return `"${value.replace(/"/g, '""')}"`;
      }
      
      return value;
    });
    
    csvContent += row.join(',') + '\n';
  });
  
  // Add a summary section
  csvContent += `\n"${titles.summary}"\n`;
  
  // Calculate lunch summary
  let lunchTotal = 0;
  let lunchPersons = 0;
  let lunchAverage = 0;
  
  // Calculate dinner summary
  let dinnerTotal = 0;
  
  // Process data for summary
  data.forEach(record => {
    // Lunch data
    lunchTotal += Number(record.lunch_letturaCassa) || 0;
    lunchPersons += Number(record.lunch_persone) || 0;
    
    // Dinner data
    dinnerTotal += Number(record.dinner_letturaCassa) || 0;
  });
  
  // Calculate averages
  lunchAverage = lunchPersons > 0 ? lunchTotal / lunchPersons : 0;
  
  // Add lunch summary
  csvContent += `\n"${titles.lunch}"\n`;
  
  // Translate these labels based on language
  const lunchLabels = {
    'it': {
      total: 'Totale Incasso Pranzo',
      persons: 'Totale Persone Pranzo',
      average: 'Media per Persona'
    },
    'ja': {
      total: 'ランチ総売上',
      persons: 'ランチ総人数',
      average: '一人当たりの平均'
    },
    'en': {
      total: 'Total Lunch Revenue',
      persons: 'Total Lunch Customers',
      average: 'Average per Person'
    }
  };
  
  const lunchText = lunchLabels[language as keyof typeof lunchLabels];
  
  csvContent += `"${lunchText.total}","${lunchTotal.toFixed(2)}"\n`;
  csvContent += `"${lunchText.persons}","${lunchPersons}"\n`;
  csvContent += `"${lunchText.average}","${lunchAverage.toFixed(2)}"\n`;
  
  // Add dinner summary
  csvContent += `\n"${titles.dinner}"\n`;
  
  const dinnerLabels = {
    'it': {
      total: 'Totale Incasso Cena',
      average: 'Media per Tavolo'
    },
    'ja': {
      total: 'ディナー総売上',
      average: 'テーブルあたりの平均'
    },
    'en': {
      total: 'Total Dinner Revenue',
      average: 'Average per Table'
    }
  };
  
  const dinnerText = dinnerLabels[language as keyof typeof dinnerLabels];
  
  csvContent += `"${dinnerText.total}","${dinnerTotal.toFixed(2)}"\n`;
  
  // Add totals
  csvContent += `\n"${titles.totals}"\n`;
  
  const totalLabels = {
    'it': {
      dailyTotal: 'Totale Giornaliero'
    },
    'ja': {
      dailyTotal: '日次合計'
    },
    'en': {
      dailyTotal: 'Daily Total'
    }
  };
  
  const totalText = totalLabels[language as keyof typeof totalLabels];
  
  csvContent += `"${totalText.dailyTotal}","${(lunchTotal + dinnerTotal).toFixed(2)}"\n`;
  
  // Add generation timestamp
  const now = new Date();
  let timestampStr = '';
  
  if (language === 'ja') {
    timestampStr = `${now.getFullYear()}年${now.getMonth() + 1}月${now.getDate()}日 ${now.getHours()}:${String(now.getMinutes()).padStart(2, '0')}`;
  } else {
    timestampStr = `${now.getDate()}/${now.getMonth() + 1}/${now.getFullYear()} ${now.getHours()}:${String(now.getMinutes()).padStart(2, '0')}`;
  }
  
  csvContent += `\n"${titles.generated}","${timestampStr}"\n`;
  
  // Write to temp file with language indicator
  const tempFilePath = join(tmpdir(), `sales_${date}_${language}.csv`);
  await fsPromises.writeFile(tempFilePath, csvContent);
  
  return tempFilePath;
}

// Update uploadToDrive to handle bilingual files and use consistent file naming
async function uploadToDrive(filePath: string, date: string, language: string = 'bilingual'): Promise<string> {
  // Get credentials from defined parameters
  const credentials = {
    client_email: driveClientEmail.value(),
    private_key: drivePrivateKey.value().replace(/\\n/g, '\n'),
    project_id: driveProjectId.value(),
  };
  
  try {
  
  
  // Authenticate with Google
  const auth = new JWT({
    email: credentials.client_email,
    key: credentials.private_key,
    scopes: SCOPES
  });
  
  const drive = googleDrive({
    version: 'v3',
    auth
  });
  
  // Define target folder ID in Google Drive
  const folderIdValue = driveFolderId.value();
  if (!folderIdValue) {
    throw new Error('Drive folder ID is not configured');
  }
  const FOLDER_ID = folderIdValue;
  
  // Extract month and year for consistent file naming
  const [year, month] = date.split('-');
  
  // Use consistent file naming based on report type
  let fileName: string;
  
  if (language === 'yearly') {
    // Yearly summary report
    fileName = `Koenji_Yearly_Summary_${year}.csv`;
  } else if (language === 'monthly') {
    // Monthly summary report
    fileName = `Koenji_Monthly_Summary_${year}_${month}.csv`;
  } else if (language === 'bilingual') {
    // Daily report with consistent naming
    fileName = `Koenji_Daily_Report_${year}_${month}.csv`;
  } else {
    // For manual exports with specific language
    const languageLabel = language === 'it' ? 'Italiano' : language === 'ja' ? '日本語' : 'English';
    fileName = `Sales_Report_${date}_${languageLabel}.csv`;
  }
  
  // Check if file already exists
  const query = `name='${fileName}' and '${FOLDER_ID}' in parents and trashed=false`;
  const existingFiles = await drive.files.list({
    q: query,
    fields: 'files(id, name)',
    spaces: 'drive'
  });
  
  let fileId = '';
  
  if (existingFiles.data.files && existingFiles.data.files.length > 0) {
    // Update existing file
    fileId = existingFiles.data.files[0].id || '';
    
    await drive.files.update({
      fileId: fileId,
      media: {
        mimeType: 'text/csv',
        body: createReadStream(filePath)
      }
    });
  } else {
    // Create new file
    const fileMetadata = {
      name: fileName,
      parents: [FOLDER_ID]
    };
    
    const media = {
      mimeType: 'text/csv',
      body: createReadStream(filePath)
    };
    
    const response = await drive.files.create({
      requestBody: fileMetadata,
      media: media,
      fields: 'id'
    });
    
    fileId = response.data.id || '';
  }
  
  return fileId;
} catch (error: any) {
  // Add detailed logging
  console.error('Google Drive API Error:', {
    error: error.message,
    code: error.code,
    folderID: driveFolderId.value(),
    serviceAccount: credentials.client_email.substring(0, 10) + '...' // Log partial email for privacy
  });
  
  throw new Error(`Google Drive error: ${error.message}`);
}}

// Function to get all dates in a month
function getDatesInMonth(year: number, month: number): string[] {
  const dates: string[] = [];
  const daysInMonth = new Date(year, month, 0).getDate();
  
  for (let day = 1; day <= daysInMonth; day++) {
    const formattedDay = day.toString().padStart(2, '0');
    const formattedMonth = month.toString().padStart(2, '0');
    dates.push(`${year}-${formattedMonth}-${formattedDay}`);
  }
  
  return dates;
}

// Create a monthly summary CSV
async function createMonthlySummary(year: number, month: number): Promise<string> {
  const dates = getDatesInMonth(year, month);
  let allData: SalesData[] = [];
  
  // Fetch data for each day in the month
  for (const date of dates) {
    try {
      const dailyData = await fetchSalesData(date);
      allData = [...allData, ...dailyData];
    } catch (error) {
      console.log(`No data for ${date}`);
    }
  }
  
  if (!allData.length) {
    throw new Error(`No data found for ${year}-${month}`);
  }
  
  // Group data by date
  const dataByDate = allData.reduce((acc, item) => {
    if (!acc[item.date]) {
      acc[item.date] = [];
    }
    acc[item.date].push(item);
    return acc;
  }, {} as Record<string, SalesData[]>);
  
  // Start building CSV content
  let csvContent = '';
  
  // Add title
  const formattedMonth = month.toString().padStart(2, '0');
  csvContent += `"RIEPILOGO MENSILE / 月次レポート: ${month}/${year}"\n\n`;
  
  // Add headers
  csvContent += `"Data / 日付","Pranzo Incasso / ランチ売上","Pranzo Persone / ランチ人数","Cena Incasso / ディナー売上","Totale / 合計"\n`;
  
  // Calculate totals for each date
  let monthlyLunchTotal = 0;
  let monthlyLunchPersons = 0;
  let monthlyDinnerTotal = 0;
  
  // Sort dates
  const sortedDates = Object.keys(dataByDate).sort();
  
  for (const date of sortedDates) {
    const dayData = dataByDate[date];
    
    // Calculate daily totals
    let dailyLunchTotal = 0;
    let dailyLunchPersons = 0;
    let dailyDinnerTotal = 0;
    
    dayData.forEach(record => {
      dailyLunchTotal += Number(record.lunch_letturaCassa) || 0;
      dailyLunchPersons += Number(record.lunch_persone) || 0;
      dailyDinnerTotal += Number(record.dinner_letturaCassa) || 0;
    });
    
    // Format date
    const [year, month, day] = date.split('-');
    const formattedDate = `${day}/${month}/${year} / ${year}年${month}月${day}日`;
    
    // Add row
    csvContent += `"${formattedDate}","${dailyLunchTotal.toFixed(2)}","${dailyLunchPersons}","${dailyDinnerTotal.toFixed(2)}","${(dailyLunchTotal + dailyDinnerTotal).toFixed(2)}"\n`;
    
    // Add to monthly totals
    monthlyLunchTotal += dailyLunchTotal;
    monthlyLunchPersons += dailyLunchPersons;
    monthlyDinnerTotal += dailyDinnerTotal;
  }
  
  // Add monthly summary
  csvContent += `\n"TOTALI MENSILI / 月間合計"\n`;
  csvContent += `"Totale Pranzo / ランチ合計","${monthlyLunchTotal.toFixed(2)}"\n`;
  csvContent += `"Totale Persone Pranzo / ランチ人数合計","${monthlyLunchPersons}"\n`;
  csvContent += `"Media per Persona / 一人当たり平均","${(monthlyLunchPersons > 0 ? monthlyLunchTotal / monthlyLunchPersons : 0).toFixed(2)}"\n`;
  csvContent += `"Totale Cena / ディナー合計","${monthlyDinnerTotal.toFixed(2)}"\n`;
  csvContent += `"TOTALE MENSILE / 月間総合計","${(monthlyLunchTotal + monthlyDinnerTotal).toFixed(2)}"\n`;
  
  // Add generation timestamp
  const now = new Date();
  const timestamp = `${now.getDate()}/${now.getMonth() + 1}/${now.getFullYear()} ${now.getHours()}:${String(now.getMinutes()).padStart(2, '0')}`;
  csvContent += `\n"Report generato il / レポート生成日時: ${timestamp}"\n`;
  
  // Write to temp file
  const tempFilePath = join(tmpdir(), `monthly_summary_${year}_${formattedMonth}.csv`);
  await fsPromises.writeFile(tempFilePath, csvContent);
  
  return tempFilePath;
}

// Add a new scheduled function for monthly summaries
export const scheduledMonthlyExport = onSchedule({
  schedule: '0 6 1 * *', // Run at 6 AM on the 1st day of each month
  timeZone: 'Europe/Rome',
  retryCount: 3
}, async (context) => {
  try {
    // Get previous month
    const today = new Date();
    const previousMonth = today.getMonth(); // Current month is 0-indexed
    const year = previousMonth === 0 ? today.getFullYear() - 1 : today.getFullYear();
    const month = previousMonth === 0 ? 12 : previousMonth;
    
    // Create monthly summary
    const csvFilePath = await createMonthlySummary(year, month);
    
    // Upload to Google Drive
    const fileId = await uploadToDrive(csvFilePath, `${year}-${month.toString().padStart(2, '0')}-01`, 'monthly');
    
    console.log(`Successfully exported monthly summary for ${month}/${year} with file ID: ${fileId}`);
    return;
  } catch (error) {
    console.error('Monthly export failed:', error instanceof Error ? error.message : String(error));
    return;
  }
});

// Create a yearly summary CSV
async function createYearlySummary(year: number): Promise<string> {
  let allData: SalesData[] = [];
  
  // Fetch data for each month in the year
  for (let month = 1; month <= 12; month++) {
    try {
      const dates = getDatesInMonth(year, month);
      
      for (const date of dates) {
        try {
          const dailyData = await fetchSalesData(date);
          allData = [...allData, ...dailyData];
        } catch (error) {
          // Skip days with no data
        }
      }
    } catch (error) {
      console.log(`Error processing month ${month}: ${error}`);
    }
  }
  
  if (!allData.length) {
    throw new Error(`No data found for year ${year}`);
  }
  
  // Group data by month
  const dataByMonth: Record<number, SalesData[]> = {};
  
  allData.forEach(item => {
    const [, itemMonth] = item.date.split('-');
    const monthNum = parseInt(itemMonth);
    
    if (!dataByMonth[monthNum]) {
      dataByMonth[monthNum] = [];
    }
    dataByMonth[monthNum].push(item);
  });
  
  // Start building CSV content
  let csvContent = '';
  
  // Add title
  csvContent += `"RIEPILOGO ANNUALE / 年次レポート: ${year}"\n\n`;
  
  // Add headers
  csvContent += `"Mese / 月","Pranzo Incasso / ランチ売上","Pranzo Persone / ランチ人数","Cena Incasso / ディナー売上","Totale / 合計"\n`;
  
  // Calculate totals for each month
  let yearlyLunchTotal = 0;
  let yearlyLunchPersons = 0;
  let yearlyDinnerTotal = 0;
  
  // Month names in Italian and Japanese
  const monthNames = {
    1: 'Gennaio / 1月',
    2: 'Febbraio / 2月',
    3: 'Marzo / 3月',
    4: 'Aprile / 4月',
    5: 'Maggio / 5月',
    6: 'Giugno / 6月',
    7: 'Luglio / 7月',
    8: 'Agosto / 8月',
    9: 'Settembre / 9月',
    10: 'Ottobre / 10月',
    11: 'Novembre / 11月',
    12: 'Dicembre / 12月'
  };
  
  // Process each month
  for (let month = 1; month <= 12; month++) {
    const monthData = dataByMonth[month] || [];
    
    // Calculate monthly totals
    let monthlyLunchTotal = 0;
    let monthlyLunchPersons = 0;
    let monthlyDinnerTotal = 0;
    
    monthData.forEach(record => {
      monthlyLunchTotal += Number(record.lunch_letturaCassa) || 0;
      monthlyLunchPersons += Number(record.lunch_persone) || 0;
      monthlyDinnerTotal += Number(record.dinner_letturaCassa) || 0;
    });
    
    // Add row (only if there's data for this month)
    if (monthData.length > 0) {
      csvContent += `"${monthNames[month as keyof typeof monthNames]}","${monthlyLunchTotal.toFixed(2)}","${monthlyLunchPersons}","${monthlyDinnerTotal.toFixed(2)}","${(monthlyLunchTotal + monthlyDinnerTotal).toFixed(2)}"\n`;
      
      // Add to yearly totals
      yearlyLunchTotal += monthlyLunchTotal;
      yearlyLunchPersons += monthlyLunchPersons;
      yearlyDinnerTotal += monthlyDinnerTotal;
    } else {
      csvContent += `"${monthNames[month as keyof typeof monthNames]}","0.00","0","0.00","0.00"\n`;
    }
  }
  
  // Add yearly summary
  csvContent += `\n"TOTALI ANNUALI / 年間合計"\n`;
  csvContent += `"Totale Pranzo / ランチ合計","${yearlyLunchTotal.toFixed(2)}"\n`;
  csvContent += `"Totale Persone Pranzo / ランチ人数合計","${yearlyLunchPersons}"\n`;
  csvContent += `"Media per Persona / 一人当たり平均","${(yearlyLunchPersons > 0 ? yearlyLunchTotal / yearlyLunchPersons : 0).toFixed(2)}"\n`;
  csvContent += `"Totale Cena / ディナー合計","${yearlyDinnerTotal.toFixed(2)}"\n`;
  csvContent += `"TOTALE ANNUALE / 年間総合計","${(yearlyLunchTotal + yearlyDinnerTotal).toFixed(2)}"\n`;
  
  // Add generation timestamp
  const now = new Date();
  const timestamp = `${now.getDate()}/${now.getMonth() + 1}/${now.getFullYear()} ${now.getHours()}:${String(now.getMinutes()).padStart(2, '0')}`;
  csvContent += `\n"Report generato il / レポート生成日時: ${timestamp}"\n`;
  
  // Write to temp file
  const tempFilePath = join(tmpdir(), `yearly_summary_${year}.csv`);
  await fsPromises.writeFile(tempFilePath, csvContent);
  
  return tempFilePath;
}

// Add a new scheduled function for yearly summaries
export const scheduledYearlyExport = onSchedule({
  schedule: '0 7 1 1 *', // Run at 7 AM on January 1st
  timeZone: 'Europe/Rome',
  retryCount: 3
}, async (context) => {
  try {
    // Get previous year
    const today = new Date();
    const year = today.getFullYear() - 1;
    
    // For backward compatibility, create the CSV file
    const csvFilePath = await createYearlySummary(year);
    
    // Upload CSV to Google Drive
    const fileId = await uploadToDrive(csvFilePath, `${year}-01-01`, 'yearly');
    
    // Create a dummy date for the first day of the year to update the Google Sheet
    const dummyDate = `${year}-01-01`;
    
    // Get some sample data to ensure the sheet is created
    const januaryData = await fetchSalesData(dummyDate);
    
    // If no data for January 1st, try to get data from any day in January
    let sampleData = januaryData;
    if (sampleData.length === 0) {
      // Try to get data from any day in the year
      for (let month = 1; month <= 12; month++) {
        const formattedMonth = month.toString().padStart(2, '0');
        for (let day = 1; day <= 28; day++) { // Try first 28 days of each month
          const formattedDay = day.toString().padStart(2, '0');
          const testDate = `${year}-${formattedMonth}-${formattedDay}`;
          const testData = await fetchSalesData(testDate);
          if (testData.length > 0) {
            sampleData = testData;
            break;
          }
        }
        if (sampleData.length > 0) break;
      }
    }
    
    // If we found any data, update the Google Sheet
    if (sampleData.length > 0) {
      // Update the Google Sheet with the sample data to ensure all sheets are created
      const spreadsheetId = await updateSalesGoogleSheet(sampleData, dummyDate);
      console.log(`Successfully updated Google Sheet for year ${year} with ID: ${spreadsheetId}`);
    } else {
      console.log(`No data found for year ${year}, only CSV was created`);
    }
    
    console.log(`Successfully exported yearly summary for ${year} with file ID: ${fileId}`);
    return;
  } catch (error) {
    console.error('Yearly export failed:', error instanceof Error ? error.message : String(error));
    return;
  }
});

/**
 * Copies a template sheet to create a new sheet with the desired formatting
 * @param spreadsheetId The ID of the spreadsheet
 * @param templateName The name of the template sheet
 * @param newSheetName The name for the new sheet
 * @returns Promise resolving to true if a new sheet was created, false if it already existed
 */
async function copyTemplateSheet(spreadsheetId: string, templateName: string, newSheetName: string): Promise<boolean> {
  const auth = new JWT({
    email: process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL,
    key: process.env.GOOGLE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    scopes: ['https://www.googleapis.com/auth/spreadsheets']
  });
  
  const sheets = google.sheets({ version: 'v4', auth });
  
  try {
    // First check if the sheet already exists
    const response = await sheets.spreadsheets.get({
      spreadsheetId,
      includeGridData: false
    });
    
    const sheetExists = response.data.sheets?.some(
      sheet => sheet.properties?.title === newSheetName
    );
    
    if (sheetExists) {
      console.log(`Sheet ${newSheetName} already exists, skipping template copy`);
      return false;
    }
    
    // Find the template sheet ID
    const templateSheet = response.data.sheets?.find(
      sheet => sheet.properties?.title === templateName
    );
    
    if (!templateSheet || !templateSheet.properties?.sheetId) {
      throw new Error(`Template sheet ${templateName} not found`);
    }
    
    // Copy the template sheet
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      requestBody: {
        requests: [
          {
            duplicateSheet: {
              sourceSheetId: templateSheet.properties.sheetId,
              newSheetName: newSheetName,
              insertSheetIndex: 0  // Insert at the beginning
            }
          }
        ]
      }
    });
    
    console.log(`Created new sheet ${newSheetName} from template ${templateName}`);
    return true;
  } catch (error) {
    console.error(`Error copying template sheet: ${error}`);
    throw error;
  }
}

// Find the function that sends decline emails and update it to use getEmailSubject
async function sendDeclineEmail(
  reservation: any,
  reservationId: string,
  reason: string,
  forcedEmail?: string
) {
  let email = forcedEmail || reservation.email;

  // Extract email from notes if needed
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

  // Get preferred language from reservation, default to English if not specified
  const language = reservation.preferredLanguage || 'en';
  console.log(`Using language: ${language} for decline email, reservation ${reservationId}`);

  try {
    // Load template based on language
    const template = await loadEmailTemplate('decline', language);
    
    // Get the reason text in the correct language
    const reasonText = getDeclineReasonText(reason, language);
    const followUpMessage = getFollowUpMessage(reason, language);
    
    // Prepare data for template
    const templateData = {
      name: reservation.name,
      date: reservation.dateString,
      time: reservation.startTime,
      people: reservation.numberOfPersons,
      reason: reasonText,
      followUpMessage: followUpMessage,
    };
    
    // Render the template with data
    const emailHtml = renderEmailTemplate(template, templateData);

    // Get the correct subject for this language and type
    const emailSubject = getEmailSubject('decline', language);
    console.log(`Decline email subject: "${emailSubject}" for language: ${language}`);

    // Create a transport each time we want to send an email
    const mailTransport = createMailTransport();

    await mailTransport.sendMail({
      from: '"KOENJI. VENEZIA" <koenji.staff@gmail.com>',
      to: email,
      subject: emailSubject,
      html: emailHtml,
    });

    console.log(`Decline email sent to ${email} for reservation ${reservationId} in ${language}`);
    return { success: true };
  } catch (error) {
    console.error("Error sending decline email:", error);
    return { error: error instanceof Error ? error.message : "Unknown error" };
  }
}