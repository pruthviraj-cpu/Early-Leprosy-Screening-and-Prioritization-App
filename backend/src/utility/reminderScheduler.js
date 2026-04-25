// src/utility/reminderScheduler.js
import cron from "node-cron";
import { supabaseAdmin } from "../config/supabase.js";
import { sendDoctorReminderEmail } from "./emailReminder.js";

// ─────────────────────────────────────────────────────────────
//  ✅ CONFIGURE YOUR REMINDER SCHEDULE HERE
//
//  Change REMINDER_MODE to switch between modes:
//    "minutes" → good for TESTING  (runs every N minutes)
//    "days"    → good for PRODUCTION (runs every N days at a set hour)
//
//  Examples:
//    REMINDER_MODE = "minutes", REMINDER_INTERVAL = 5   → every 5 minutes
//    REMINDER_MODE = "days",    REMINDER_INTERVAL = 2   → every 2 days at 9 AM
//    REMINDER_MODE = "days",    REMINDER_INTERVAL = 7   → every 7 days at 9 AM
// ─────────────────────────────────────────────────────────────
const REMINDER_MODE = process.env.REMINDER_MODE || "days"; // "minutes" | "days"
const REMINDER_INTERVAL = parseInt(process.env.REMINDER_INTERVAL || "2", 10);
const REMINDER_HOUR = parseInt(process.env.REMINDER_HOUR || "9", 10); // 9 AM (only used in "days" mode)

// ─────────────────────────────────────────────────────────────
//  Converts config into a cron expression
// ─────────────────────────────────────────────────────────────
const buildCronExpression = () => {
  if (REMINDER_MODE === "minutes") {
    // Run every N minutes — great for testing
    return `*/${REMINDER_INTERVAL} * * * *`;
  }

  if (REMINDER_MODE === "days") {
    if (REMINDER_INTERVAL === 1) {
      // Every day at REMINDER_HOUR
      return `0 ${REMINDER_HOUR} * * *`;
    }
    if (REMINDER_INTERVAL === 2) {
      // Every 2 days at REMINDER_HOUR (runs every even day of month)
      return `0 ${REMINDER_HOUR} */2 * *`;
    }
    if (REMINDER_INTERVAL === 7) {
      // Every 7 days = once a week, every Monday at REMINDER_HOUR
      return `0 ${REMINDER_HOUR} * * 1`;
    }
    // Generic fallback: every N days
    return `0 ${REMINDER_HOUR} */${REMINDER_INTERVAL} * *`;
  }

  // Default fallback: every day at 9 AM
  return `0 9 * * *`;
};

// ─────────────────────────────────────────────────────────────
//  Core job: find all doctors with unreviewed cases → send email
// ─────────────────────────────────────────────────────────────
export const sendDoctorReminders = async () => {
  console.log(`\n[ReminderScheduler] 🔔 Running reminder job at ${new Date().toISOString()}`);

  try {
    // Step 1: Get all unreviewed diagnosis cases
    // doctor_review is null means no doctor has reviewed it yet
    const { data: unreviewedCases, error: casesError } = await supabaseAdmin
      .from("diagnosis_results")
      .select("id, user_id, full_name, created_at, doctor_review")
      .is("doctor_review", null); // unreviewed = doctor_review is NULL

    if (casesError) {
      console.error("[ReminderScheduler] ❌ Error fetching unreviewed cases:", casesError.message);
      return;
    }

    if (!unreviewedCases || unreviewedCases.length === 0) {
      console.log("[ReminderScheduler] ✅ No unreviewed cases found. No emails needed.");
      return;
    }

    console.log(`[ReminderScheduler] 📋 Found ${unreviewedCases.length} unreviewed case(s).`);

    // Step 2: Get all doctors from profiles (role = 'doctor')
    const { data: doctors, error: doctorsError } = await supabaseAdmin
      .from("profiles")
      .select("id, full_name, role")
      .eq("role", "doctor");

    if (doctorsError) {
      console.error("[ReminderScheduler] ❌ Error fetching doctors:", doctorsError.message);
      return;
    }

    if (!doctors || doctors.length === 0) {
      console.log("[ReminderScheduler] ⚠️ No doctors found in profiles table.");
      return;
    }

    // Step 3: Get doctor emails from Supabase Auth (auth.users)
    // We fetch emails for only the doctor IDs we found
    const doctorIds = doctors.map((d) => d.id);

    const { data: authUsers, error: authError } = await supabaseAdmin.auth.admin.listUsers();

    if (authError) {
      console.error("[ReminderScheduler] ❌ Error fetching auth users:", authError.message);
      return;
    }

    // Filter to only doctors and map id → email
    const doctorEmailMap = new Map();
    authUsers.users.forEach((user) => {
      if (doctorIds.includes(user.id) && user.email) {
        doctorEmailMap.set(user.id, user.email);
      }
    });

    // Step 4: Send one reminder email per doctor
    let emailsSent = 0;
    const pendingCount = unreviewedCases.length;

    for (const doctor of doctors) {
      const email = doctorEmailMap.get(doctor.id);

      if (!email) {
        console.warn(`[ReminderScheduler] ⚠️ No email found for doctor: ${doctor.full_name || doctor.id}`);
        continue;
      }

      try {
        await sendDoctorReminderEmail(email, doctor.full_name || "Doctor", pendingCount);
        emailsSent++;
      } catch (emailError) {
        console.error(
          `[ReminderScheduler] ❌ Failed to send email to ${email}:`,
          emailError.message
        );
      }
    }

    console.log(
      `[ReminderScheduler] ✅ Reminder job complete. Emails sent: ${emailsSent}/${doctors.length}`
    );
  } catch (err) {
    console.error("[ReminderScheduler] ❌ Unexpected error in reminder job:", err.message);
  }
};

// ─────────────────────────────────────────────────────────────
//  Starts the cron scheduler — call this once from server.js
// ─────────────────────────────────────────────────────────────
export const startReminderScheduler = () => {
  const cronExpression = buildCronExpression();

  console.log(`\n[ReminderScheduler] 🚀 Starting scheduler...`);
  console.log(`[ReminderScheduler] 📅 Mode     : ${REMINDER_MODE}`);
  console.log(`[ReminderScheduler] 🔢 Interval : ${REMINDER_INTERVAL} ${REMINDER_MODE}`);
  console.log(`[ReminderScheduler] ⏰ Cron     : "${cronExpression}"`);

  if (!cron.validate(cronExpression)) {
    console.error("[ReminderScheduler] ❌ Invalid cron expression! Scheduler not started.");
    return;
  }

  cron.schedule(cronExpression, sendDoctorReminders, {
    scheduled: true,
    timezone: process.env.SCHEDULER_TIMEZONE || "Asia/Kolkata", // IST by default (you're in Pune)
  });

  console.log(`[ReminderScheduler] ✅ Scheduler is active.\n`);
};