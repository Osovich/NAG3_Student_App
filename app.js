const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'NAG3 Student App - DevOps Pipeline Demo',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    timestamp: new Date().toISOString()
  });
});

app.get('/api/students', (req, res) => {
  const students = [
    { id: 1, name: 'Alice Johnson', grade: 'A', course: 'DevOps' },
    { id: 2, name: 'Bob Smith', grade: 'B+', course: 'DevOps' },
    { id: 3, name: 'Carol Davis', grade: 'A-', course: 'DevOps' },
    { id: 4, name: 'David Wilson', grade: 'B', course: 'DevOps' }
  ];
  
  res.json({
    students,
    count: students.length,
    timestamp: new Date().toISOString()
  });
});

app.get('/api/students/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const students = [
    { id: 1, name: 'Alice Johnson', grade: 'A', course: 'DevOps' },
    { id: 2, name: 'Bob Smith', grade: 'B+', course: 'DevOps' },
    { id: 3, name: 'Carol Davis', grade: 'A-', course: 'DevOps' },
    { id: 4, name: 'David Wilson', grade: 'B', course: 'DevOps' }
  ];
  
  const student = students.find(s => s.id === id);
  if (!student) {
    return res.status(404).json({ error: 'Student not found' });
  }
  
  res.json(student);
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
