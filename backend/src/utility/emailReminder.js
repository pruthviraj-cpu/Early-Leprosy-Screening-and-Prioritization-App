// src/utility/emailReminder.js
import nodemailer from "nodemailer";

/**
 * Creates a Gmail SMTP transporter using App Password.
 * Set these in your .env file:
 *   GMAIL_ADDRESS=yourapp@gmail.com
 *   GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx  (16-char Google App Password)
 */
const createTransporter = () => {
  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.GMAIL_ADDRESS,
      pass: process.env.GMAIL_APP_PASSWORD,
    },
  });
};

/**
 * Sends a reminder email to a single doctor.
 * @param {string} doctorEmail
 * @param {string} doctorName
 * @param {number} pendingCount - number of unreviewed cases
 */
export const sendDoctorReminderEmail = async (doctorEmail, doctorName, pendingCount) => {
  const transporter = createTransporter();

  const subject =
    pendingCount === 1
      ? `⚠️ Reminder: 1 patient case needs your review`
      : `⚠️ Reminder: ${pendingCount} patient cases need your review`;

  const htmlBody = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9;">
      <div style="background-color: #ffffff; border-radius: 8px; padding: 30px; border-left: 4px solid #e74c3c;">
        <h2 style="color: #2c3e50; margin-top: 0;">Patient Review Reminder</h2>
        <p style="color: #555; font-size: 16px;">Hi <strong>Dr. ${doctorName}</strong>,</p>
        <p style="color: #555; font-size: 16px;">
          You have <strong style="color: #e74c3c;">${pendingCount} unreviewed patient case${pendingCount > 1 ? "s" : ""}</strong> 
          waiting on your dashboard.
        </p>
        <p style="color: #555; font-size: 16px;">
          Patients are waiting for your expert assessment. Please log in and review 
          the pending cases at your earliest convenience.
        </p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${process.env.APP_URL || "https://yourapp.com"}/doctor/dashboard" 
             style="background-color: #3498db; color: white; padding: 12px 30px; 
                    text-decoration: none; border-radius: 5px; font-size: 16px; font-weight: bold;">
            Review Cases Now
          </a>
        </div>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;" />
        <p style="color: #999; font-size: 12px;">
          This is an automated reminder from your Health Platform. 
          If you have already reviewed these cases, please disregard this email.
        </p>
      </div>
    </div>
  `;

  const mailOptions = {
    from: `"Health Platform" <${process.env.GMAIL_ADDRESS}>`,
    to: doctorEmail,
    subject,
    html: htmlBody,
  };

  await transporter.sendMail(mailOptions);
  console.log(`[ReminderEmail] ✅ Sent to ${doctorEmail} (${pendingCount} pending cases)`);
};