const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const Submission = require("./Submission");

const app = express();

app.use(cors());
app.use(express.json());

mongoose
  .connect("mongodb://127.0.0.1:27017/student_form_db")
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.error("MongoDB connection error:", err));

app.post("/api/submit", async (req, res) => {
  try {
    const { name, email, subject, message } = req.body;
    const newSubmission = new Submission({ name, email, subject, message });
    await newSubmission.save();
    res.status(201).json({ message: "Form submitted successfully" });
  } catch (err) {
    console.error("Error submitting form:", err);
    res.status(500).json({ message: "Server error while submitting form" });
  }
});

app.get("/api/submissions", async (req, res) => {
  try {
    const submissions = await Submission.find();
    res.status(200).json(submissions);
  } catch (err) {
    res.status(500).json({ message: "Failed to fetch submissions" });
  }
});

const PORT = 5000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
