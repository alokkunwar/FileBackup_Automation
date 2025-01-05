# Backup Automation Script

This repository contains a Bash script that automates the process of taking complete, incremental, and differential backups of a specified root directory. The script is designed to be flexible, allowing users to specify file extensions to be included in the backups, and runs indefinitely with a configurable interval between each backup type.

## Features

- **Complete Backup:** Captures all files in the root directory, excluding hidden files and the backup directory itself.
- **Incremental Backup:** Performs two rounds of incremental backups:
  1. The first round includes files modified after the last complete backup.
  2. The second and third rounds include files modified after the previous incremental backup or differential backup, respectively.
- **Differential Backup:** Captures files modified after the last complete backup.
- **Customizable File Extensions:** Users can specify up to three file extensions to include in the backup process.
- **Logging:** All backup activities are logged with timestamps for easy tracking.

## Project Overview

This project was developed to provide a robust and automated solution for managing backups in a Linux environment. It features different backup strategies—complete, incremental, and differential—to ensure data is preserved and easily restored in various scenarios. The script is designed to be lightweight and efficient, using temporary files and excluding unnecessary directories to optimize the backup process.

## Workflow

1. **Directory Setup:** Automatically creates necessary directories for storing complete, incremental, and differential backups.
2. **Timestamp Management:** Uses timestamp files to keep track of when the last backup was performed.
3. **Backup Process:** Each type of backup follows a specific strategy to capture only the files that have changed, minimizing storage usage.
4. **Logging:** Detailed logs are maintained to track backup operations and identify any issues quickly.

## Important Notes

This script is intended for educational and demonstration purposes. The implementation showcases various techniques for automating backup processes in a Unix-like environment.