# Skin Buddy

Skin Buddy is a full-stack AI-powered application built using Flutter for the frontend, Node.js with Express for the backend, and Supabase for database, authentication, and storage.  
The app follows an offline-first approach with caching for AI chats, forms, images, and user session data.

---

## Tech Stack

Frontend:
- Flutter
- Hive (local NoSQL cache)
- Flutter Secure Storage
- Dio / HTTP

Backend:
- Node.js
- Express.js
- Supabase SDK

Database & Cloud:
- Supabase (PostgreSQL, Auth, Storage)

---

## Project Structure

Skin_buddy/
├── frontend/
├── backend/
├── .gitignore
└── README.md

---

## Prerequisites

Install the following before starting:

Git  
https://git-scm.com/downloads

Flutter  
https://docs.flutter.dev/get-started/install

Node.js (LTS)  
https://nodejs.org

Verify installations:

git --version  
flutter --version  
node --version  
npm --version  

---

## Clone Repository

git clone https://github.com/pruthviraj-cpu/Skin_buddy.git  
cd Skin_buddy

---

## Frontend Setup (Flutter)

cd frontend  
flutter pub get  

Run the app:

flutter run

---

## Backend Setup (Node + Express)

cd backend  
npm install  

Create environment file:

touch .env

Add this inside `.env`:

PORT=5000  
SUPABASE_URL=your_supabase_project_url  
SUPABASE_SERVICE_KEY=your_supabase_service_key  
AI_API_KEY=your_ai_api_key  

Start server:

npm run dev  

Backend will run on:

http://localhost:5000

---

## Supabase Setup

1. Go to https://supabase.com  
2. Create a new project  
3. Copy Project URL and Service Role Key  
4. Paste them into backend `.env`  

---

## Caching Strategy (Offline First)

Login Session:
- Stored using Flutter Secure Storage
- User stays logged in without re-authentication

AI Chat:
- Latest chats stored in Hive
- Cached chats shown instantly when offline
- When internet is available, missing chats are fetched from Supabase and merged

Forms & Images:
- Form data stored in Hive
- Images stored locally until upload succeeds
- Synced automatically when internet is available

Location Data:
- Cached locally
- Updated periodically when online

---

## Git Ignore Rules

The following files and folders are ignored:

node_modules/  
.env  
build/  
.dart_tool/  
.flutter-plugins  
.flutter-plugins-dependencies  
.idea/  
.vscode/  
.DS_Store  

---

## Push Code to GitHub

git add .  
git commit -m "Initial project setup"  
git branch -M main  
git remote add origin https://github.com/pruthviraj-cpu/Skin_buddy.git  
git push -u origin main  

---

## Common Fixes

If `.env` was committed accidentally:

git rm --cached .env  
git commit -m "Remove env file from repo"  

---

## Future Enhancements

- On-device ML model integration
- Background sync
- Push notifications
- Analytics dashboard

---

