# Student Form Management System

## Overview
This project is a full-stack web application that allows **students** to submit forms and **administrators** to view submitted data.  
The **frontend** is built using **React**, while the **backend** is built using **Node.js**, **Express**, and **MongoDB**.

It supports two roles:
- **Student** – can log in and submit a form.
- **Admin** – can view all student submissions.

---

## Project Structure
```bash


student-app/
│
├── frontend/                # React application (UI)
│   ├── src/
│   │   ├── components/      
│   │   └── styles/          
│   ├── package.json
│   └── ...
│
└── backend/                 # Node.js + Express + MongoDB backend
    ├── server.js            
    ├── models/              # Mongoose schemas
    │   └── Submission.js
    ├── routes/              # API routes
    │   └── submissionRoutes.js
    ├── controllers/         # Handles API logic
    │   └── submissionController.js
    ├── config/              # MongoDB connection
    │   └── db.js
    └── package.json

```

---

## Features

### Student Features
- Log in using a student email (e.g. `name@student.edu`).
- Submit form details: subject and message.
- Receive confirmation after submission.

### Admin Features
- View all submitted student forms.
- Display student ID, email, subject, and message.
- Logout functionality.

### Backend Features
- REST API built using Express.
- MongoDB used to store form submissions.
- CORS enabled to allow frontend-backend communication.

---

## Technologies Used

| Layer | Technologies |
|--------|---------------|
| **Frontend** | React, Axios, React Router, CSS / Bootstrap |
| **Backend** | Node.js, Express.js, Mongoose, MongoDB |
| **Development Tools** | Nodemon, Concurrently |

---

## Installation & Setup

### Clone the Repository
```bash
git clone https://github.com/your-username/student-app.git
cd student-app
```
### Install Dependencies
#### Frontend
```bash
cd frontend
npm install
```

#### Backend
```bash
cd ../backend
npm install
```
### Setup MongoDB
```bash

```

### Start the Servers
#### Run the Backend
cd backend
npm start

#### Run the Frontend
Open a new terminal and run:
```bash
cd frontend
npm start
```
Default URLs

Frontend → http://localhost:3000

Backend → http://localhost:5000

