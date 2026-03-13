# 🗄️ backup.sh — Advanced Automated Backup Script

<div align="center">

![Bash](https://img.shields.io/badge/Bash-5.0%2B-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-Compatible-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![macOS](https://img.shields.io/badge/macOS-Compatible-000000?style=for-the-badge&logo=apple&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-2.0.0-orange?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge)

**A production-grade Bash script that automatically backs up files modified in the last 24 hours, with logging, email alerts, dry-run mode, and cron scheduling support.**

[Features](#-features) · [Architecture](#-architecture) · [Installation](#-installation) · [Usage](#-usage) · [Configuration](#-configuration) · [Contributing](#-contributing)

</div>

---

## 📖 Background

This project was built as the final capstone of the **IBM Linux Commands and Shell Scripting** course on Coursera. The real-world scenario: engineers at ABC International Inc. were manually backing up encrypted password files every day — a slow, error-prone, and insecure process.

`backup.sh` eliminates that bottleneck entirely.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🕐 **24h File Detection** | Automatically finds files modified in the last 24 hours |
| 📦 **Compressed Archives** | Creates timestamped `.tar.gz` archives for every run |
| 📋 **Rotating Log File** | Keeps a clean log with automatic rotation at 1000 lines |
| 🎨 **Color Output** | Color-coded terminal output for instant status reading |
| 📧 **Email Alerts** | Sends alert emails on failure (configurable) |
| 🧪 **Dry-Run Mode** | Test the script without creating or moving any files |
| ⚙️ **Config File** | Override defaults via `~/.backup.conf` |
| 🔒 **Defensive Scripting** | Validates all inputs and exits safely on any error |
| ⏰ **Cron Ready** | Designed to run unattended via cron every 24 hours |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        backup.sh                            │
│                                                             │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │   Validate  │───▶│  Scan Files  │───▶│ Create Archive│  │
│  │   Arguments │    │  (24h check) │    │  (.tar.gz)    │  │
│  └─────────────┘    └──────────────┘    └───────┬───────┘  │
│         │                  │                    │           │
│         ▼                  ▼                    ▼           │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │    Logger   │    │  toBackup[]  │    │  Move to Dest │  │
│  │  (rotating) │    │   (array)    │    │  Directory    │  │
│  └─────────────┘    └──────────────┘    └───────────────┘  │
│         │                                       │           │
│         ▼                                       ▼           │
│  ~/.backup_logs/                     /destination/          │
│  backup.log                          backup-[TS].tar.gz     │
└─────────────────────────────────────────────────────────────┘

                         ┌──────────┐
                         │  crontab │
                         │ 0 0 * * *│
                         └────┬─────┘
                              │ triggers every 24h
                              ▼
                         backup.sh
```

### Flow Diagram

```
START
  │
  ├─▶ Validate arguments (count + directory existence)
  │         │ FAIL ──▶ Log ERROR + Send Email Alert + EXIT
  │         │ PASS
  │
  ├─▶ Set variables (targetDir, destDir, timestamp, filename)
  │
  ├─▶ Navigate to destination → save absolute path
  │
  ├─▶ Navigate to target directory
  │
  ├─▶ Calculate yesterdayTS (currentTS - 86400 seconds)
  │
  ├─▶ Loop through all files with wildcard (*)
  │     │
  │     ├─▶ Get file modification timestamp
  │     ├─▶ Compare to yesterdayTS
  │     └─▶ If newer → append to toBackup[] array
  │
  ├─▶ If toBackup[] is empty → Log WARNING + EXIT gracefully
  │
  ├─▶ tar -czvf archive ${toBackup[@]}
  │         │ FAIL ──▶ Log ERROR + Send Email Alert + EXIT
  │
  ├─▶ mv archive → destination directory
  │
  └─▶ Print summary report
        END
```

---

## 🚀 Installation

### Prerequisites

- Bash `5.0+`
- `tar`, `date`, `mv`, `pwd` (standard on all Linux/macOS)
- `mail` command (optional, for email alerts)

### Quick Install

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/backup-sh.git
cd backup-sh

# 2. Make the script executable
chmod +x backup.sh

# 3. Deploy system-wide (optional)
sudo cp backup.sh /usr/local/bin/

# 4. Verify installation
backup.sh --help
```

---

## 📦 Usage

### Basic Usage

```bash
bash backup.sh <target_directory> <destination_directory>
```

### Examples

```bash
# Backup important documents to /backups
bash backup.sh /home/user/documents /backups

# Backup project files to external drive
bash backup.sh /home/user/projects /mnt/external/backups

# Test run without creating any files
bash backup.sh /home/user/documents /backups --dry-run
```

### Dry-Run Mode

Use `--dry-run` to see what the script *would* do without actually creating or moving anything:

```bash
bash backup.sh /source /destination --dry-run
```

```
[2024-03-13 10:00:00] [INFO] Target Directory      : /source
[2024-03-13 10:00:00] [INFO] Destination Directory : /destination
[2024-03-13 10:00:00] [DRY-RUN] Would create archive: backup-1710374400.tar.gz
[2024-03-13 10:00:00] [DRY-RUN] Would include files : report.txt config.yaml
[2024-03-13 10:00:00] [DRY-RUN] Would move backup-1710374400.tar.gz → /destination/
```

### Sample Output

```
=============================================
   backup.sh — Advanced Backup Script v2.0
=============================================
[2024-03-13 10:00:01] [INFO] Target Directory      : /home/user/documents
[2024-03-13 10:00:01] [INFO] Destination Directory : /backups
[2024-03-13 10:00:01] [INFO] Backup archive name   : backup-1710374400.tar.gz
[2024-03-13 10:00:01] [INFO] Files found for backup: 3
[2024-03-13 10:00:01] [INFO]   + Queued: report.txt (modified: 2024-03-13 09:45:00)
[2024-03-13 10:00:01] [INFO]   + Queued: config.yaml (modified: 2024-03-13 08:30:00)
[2024-03-13 10:00:01] [INFO]   + Queued: notes.md (modified: 2024-03-13 07:15:00)
[2024-03-13 10:00:02] [SUCCESS] Archive created: backup-1710374400.tar.gz
[2024-03-13 10:00:02] [SUCCESS] Archive moved to: /backups/backup-1710374400.tar.gz

=============================================
   BACKUP COMPLETE
=============================================
  Files backed up : 3
  Archive         : /backups/backup-1710374400.tar.gz
  Log file        : /home/user/.backup_logs/backup.log
  Timestamp       : 2024-03-13 10:00:02
```

---

## ⚙️ Configuration

Create `~/.backup.conf` to override defaults without editing the script:

```bash
# ~/.backup.conf

# Log settings
LOG_DIR="/var/log/backups"
MAX_LOG_LINES=5000

# Email alerts
EMAIL_ALERTS=true
ALERT_EMAIL="admin@yourcompany.com"
```

### Configuration Options

| Variable | Default | Description |
|---|---|---|
| `LOG_DIR` | `~/.backup_logs` | Directory where logs are stored |
| `LOG_FILE` | `$LOG_DIR/backup.log` | Full path to log file |
| `MAX_LOG_LINES` | `1000` | Max lines before log rotation |
| `EMAIL_ALERTS` | `false` | Enable/disable email alerts |
| `ALERT_EMAIL` | `""` | Email address for failure alerts |

---

## ⏰ Scheduling with Cron

Schedule the script to run automatically every 24 hours:

```bash
# Open crontab editor
crontab -e
```

Add this line:
```
0 0 * * * /usr/local/bin/backup.sh /path/to/source /path/to/destination
```

### Cron Syntax Reference

```
0 0 * * *
│ │ │ │ │
│ │ │ │ └── Day of week   (0-7, 0=Sunday)
│ │ │ └──── Month         (1-12)
│ │ └────── Day of month  (1-31)
│ └──────── Hour          (0-23)
└────────── Minute        (0-59)
```

| Schedule | Cron Expression |
|---|---|
| Every day at midnight | `0 0 * * *` |
| Every day at 6 AM | `0 6 * * *` |
| Every hour | `0 * * * *` |
| Every Monday at midnight | `0 0 * * 1` |

---

## 📁 Project Structure

```
backup-sh/
│
├── backup.sh          # Main script
├── README.md          # This file
├── LICENSE            # MIT License
└── .backup.conf       # Example config file (optional)
```

---

## 🔑 Key Concepts Demonstrated

| Concept | Where Used |
|---|---|
| Positional arguments `$1` `$2` | Argument parsing |
| Command substitution `$()` `` ` ` `` | Timestamps, paths |
| Arithmetic expansion `$(( ))` | 24h calculation |
| Arrays `declare -a` / `+=` | File collection |
| Glob wildcard `*` | File iteration |
| `tar -czvf` | Archive creation |
| `date -r` | File modification time |
| Cron scheduling | Automation |
| Log rotation | Production reliability |
| Error handling `\|\| exit` | Defensive scripting |

---

## 🤝 Contributing

Contributions are welcome! Here's how to get involved:

### Getting Started

```bash
# 1. Fork the repository on GitHub
# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/backup-sh.git

# 3. Create a feature branch
git checkout -b feature/your-feature-name

# 4. Make your changes and test them
bash backup.sh /tmp/test_source /tmp/test_dest --dry-run

# 5. Commit with a clear message
git commit -m "feat: add cloud upload support for S3"

# 6. Push and open a Pull Request
git push origin feature/your-feature-name
```

### Contribution Ideas

- [ ] AWS S3 / Google Cloud Storage upload support
- [ ] Slack/Discord webhook notifications
- [ ] Backup retention policy (auto-delete archives older than N days)
- [ ] Checksum verification after archive creation
- [ ] Multi-directory support
- [ ] Compression level configuration
- [ ] Unit tests with `bats` (Bash Automated Testing System)

### Commit Message Convention

```
feat:     New feature
fix:      Bug fix
docs:     Documentation update
refactor: Code restructure (no behavior change)
test:     Adding tests
chore:    Maintenance tasks
```

### Code Style

- Use `shellcheck` to lint your code before submitting
- Always add comments for non-obvious logic
- Follow the existing error handling pattern (`|| handle_error`)
- Test with `--dry-run` before submitting

---

## 📜 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Omar Jebbari**

- GitHub: [@YOUR_USERNAME](https://github.com/YOUR_USERNAME)
- LinkedIn: [your-linkedin](https://linkedin.com/in/your-linkedin)

---

<div align="center">

Built with ❤️ as part of the **IBM Linux Commands and Shell Scripting** course

⭐ Star this repo if you found it useful!

</div>
