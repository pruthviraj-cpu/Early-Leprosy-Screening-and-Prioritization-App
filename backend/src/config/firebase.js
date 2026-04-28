// import admin from "firebase-admin";
// import serviceAccount from "./firebase-key.json" assert { type: "json" };

// // Initialize once when server starts
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
// });

// export default admin;

import admin from "firebase-admin";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

// Fix for __dirname in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Read JSON file manually
const serviceAccount = JSON.parse(
  fs.readFileSync(path.join(__dirname, "firebase-key.json"), "utf-8")
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export default admin;