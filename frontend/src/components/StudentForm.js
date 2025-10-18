import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import '../styles/studentForm.css';

function StudentForm() {
  const navigate = useNavigate();

  const [studentData] = useState({
    studentID: '120938467',
    email: '120938467@student.edu',
  });

  const [formData, setFormData] = useState({
    subject: '',
    message: '',
  });

  const [status, setStatus] = useState({ type: '', message: '' });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        ...studentData,
        ...formData,
      };

      await axios.post('http://localhost:5000/api/submit', payload);
      setStatus({ type: 'success', message: 'Form submitted successfully!' });
      setFormData({ subject: '', message: '' });
    } catch (err) {
      setStatus({ type: 'error', message: 'Failed to submit form' });
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    navigate('/login');
  };

  return (
    <div className="student-form-container">
      <h2>Student Form</h2>

      <form onSubmit={handleSubmit}>
        <label>Student ID</label>
        <input type="text" value={studentData.studentID} disabled />

        <label>Email</label>
        <input type="email" value={studentData.email} disabled />

        <label>Subject</label>
        <input
          type="text"
          name="subject"
          value={formData.subject}
          onChange={handleChange}
          placeholder="Enter your subject"
          required
        />

        <label>Message</label>
        <textarea
          name="message"
          value={formData.message}
          onChange={handleChange}
          placeholder="Enter your message"
          rows="4"
          required
        ></textarea>

        <button type="submit">Submit</button>
      </form>

      {status.message && (
        <p className={status.type === 'success' ? 'success' : 'error'}>
          {status.message}
        </p>
      )}

      <button className="logout-btn" onClick={handleLogout}>
        Logout
      </button>
    </div>
  );
}

export default StudentForm;
