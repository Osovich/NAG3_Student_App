#!/bin/bash

echo "Starting integration tests..."

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Check if frontend is accessible
echo "Testing frontend connectivity..."
curl -f http://frontend-test:3000 || {
    echo "Frontend not accessible"
    exit 1
}

# Check if backend is accessible
echo "Testing backend connectivity..."
curl -f http://backend-test:5000/health || {
    echo "Backend not accessible"
    exit 1
}

# Run API tests
echo "Running API tests..."
npm test

echo "All tests completed successfully!"
