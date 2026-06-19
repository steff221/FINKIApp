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

## Tech stack

| Layer | Technology |
|---|---|
| **Frontend** | Next.js 14 (App Router, TypeScript, Tailwind) |
| **Backend** | Spring Boot (Java 21), JWT auth |
| **Database** | PostgreSQL 16 |
| **Data** | Class timetable scraped from EduPage; consultations scraped from the FINKI site |

---

## Screenshots

### Landing

<img src="photos/REPLACE_landing.png" alt="Landing page" width="600" />

### Распоред · Консултации

| Распоред | Консултации |
|---|---|
| <img src="photos/REPLACE_schedule.png" alt="Schedule" width="300" /> | <img src="photos/REPLACE_consultations.png" alt="Consultations" width="300" /> |

### Мој Распоред · Испити

| Мој Распоред | Испити |
|---|---|
| <img src="photos/REPLACE_my-schedule.png" alt="My schedule" width="300" /> | <img src="photos/REPLACE_exams.png" alt="Exams" width="300" /> |

### Карта

<img src="photos/REPLACE_map.png" alt="Campus map" width="600" />
