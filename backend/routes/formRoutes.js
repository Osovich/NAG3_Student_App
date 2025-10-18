const express = require("express");
const router = express.Router();
const Submission = require("../models/Submission");

// POST
router.post("/submit", async (req, res) => {
  try {
    const newSubmission = new Submission(req.body);
    await newSubmission.save();
    res.status(201).json({ message: "Form submitted successfully!" });
  } catch (err) {
    res.status(500).json({ error: "Failed to submit form" });
  }
});

// GET
router.get("/submissions", async (req, res) => {
  try {
    const data = await Submission.find();
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch data" });
  }
});

module.exports = router;
