# ФИНКИ Распоред · FINKI Schedule

A web app for FINKI students to view their class timetable, browse professor consultations, build a personal weekly schedule, track exams, and find rooms on a campus map.

---

## Features

| Section | Description |
|---|---|
| **Распоред** · Schedule | Full faculty timetable with filters (year, program, day, professor, room) and one-click add to your schedule. |
| **Консултации** · Consultations | Browse all professors and book consultation slots. |
| **Мој Распоред** · My Schedule | Personal weekly calendar — add classes, labs, and custom entries, then export to `.ics`. |
| **Испити** · Exams | All your exams in one place. |
| **Карта** · Map | Interactive map of the FINKI campus to locate rooms and buildings. |

---

## Screenshots

### Landing

<img width="1440" alt="Landing page" src="https://github.com/user-attachments/assets/9b21eca7-f6a6-4e9e-86b5-67f44ed9cf6c" />

### Распоред · Консултации

| Распоред | Консултации |
|---|---|
| <img width="600" alt="Schedule" src="https://github.com/user-attachments/assets/204ba2c1-3f29-440f-8b23-22d2b0cda41e" /> | <img width="600" alt="Consultations" src="https://github.com/user-attachments/assets/e4eafc5e-3be7-48cb-9873-0cd348036a52" /> |

### Мој Распоред · Испити

| Мој Распоред | Испити |
|---|---|
| <img width="600" alt="My schedule" src="https://github.com/user-attachments/assets/55291eef-4229-43e1-9905-5b8e0b26d0a9" /> | <img width="600" alt="Exams" src="https://github.com/user-attachments/assets/8c98fa63-458e-4e95-ae25-7f53ec4433fc" /> |

### Карта

<img width="1440" alt="Campus map" src="https://github.com/user-attachments/assets/6f530486-d232-47ef-9cb2-6ae6e74f1bbc" />

---

## Tech stack

- **Frontend** — Next.js 14 (App Router, TypeScript, Tailwind)
- **Backend** — Spring Boot (Java 21), JWT auth
- **Database** — PostgreSQL 16
- **Data** — class timetable scraped from EduPage; consultations scraped from the FINKI site
