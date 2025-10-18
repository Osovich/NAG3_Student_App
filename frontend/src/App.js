import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import "./App.css";
import Login from "./components/Login";
import StudentForm from "./components/StudentForm";
import AdminDashboard from "./components/AdminDashboard";
import "bootstrap/dist/css/bootstrap.min.css";
// import "./styles/login.css";

function App() {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" element={<Login />} />
          <Route path="/student-form" element={<StudentForm />} />
          <Route path="/admin" element={<AdminDashboard />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
