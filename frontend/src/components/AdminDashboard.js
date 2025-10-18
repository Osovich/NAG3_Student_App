import React, { useEffect, useState } from "react";
import axios from "axios";

function AdminDashboard() {
  const [submissions, setSubmissions] = useState([]);

  useEffect(() => {
    axios.get("http://localhost:5000/api/submissions").then((res) => {
      setSubmissions(res.data);
    });
  }, []);

  return (
    <div className="container mt-4">
      <h3>Admin Dashboard</h3>
      <table className="table table-striped">
        <thead className="table-dark">
          <tr>
            <th>Name</th>
            <th>Email</th>
            <th>Subject</th>
            <th>Message</th>
          </tr>
        </thead>
        <tbody>
          {submissions.map((sub, i) => (
            <tr key={i}>
              <td>{sub.name}</td>
              <td>{sub.email}</td>
              <td>{sub.subject}</td>
              <td>{sub.message}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default AdminDashboard;
