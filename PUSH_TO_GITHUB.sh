#!/bin/bash

# Simple script to push to GitHub

cd /Users/aziz/Documents/ursus

echo "Pushing to GitHub..."
git push origin main

if [ $? -eq 0 ]; then
    echo "✅ Push successful!"
    echo "Files are now on GitHub"
else
    echo "❌ Push failed"
    echo "Make sure you have internet connection"
fi

