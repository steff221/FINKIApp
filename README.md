# ФИНКИ Распоред [FINKI SCHEDULE]

A web app for FINKI students to view their class timetable, browse professor
consultations, build a personal weekly schedule, and find rooms on a campus map.

<p align="center">
  <img src="README_photos/landing.png" alt="ФИНКИ Распоред — home" width="100%" />
</p>

## Features

| | |
|---|---|
| **Распоред [Schedule]** | Full faculty timetable with filters (year, program, day, professor, room) and one-click add to your schedule. |
| **Консултации[Consultations]** | Browse all professors and book consultation slots. |
| **Мој Распоред[My Schedule]** | Your personal weekly calendar — add classes, labs, and custom entries, then export to `.ics`. |
| **Карта[Map]** | Interactive map of the FINKI campus to locate rooms and buildings. |

### Screenshots

| Распоред | Консултации |
|---|---|
| ![Schedule](README_photos/schedule.png) | ![Consultations](README_photos/consultations.png) |
| **Испити** | **Мој Распоред** |
| ![Exams](README_photos/exams.png) | ![My Schedule](README_photos/my%20schedule.png) |
| **Карта** | **Почетна** |
| ![Campus Map](README_photos/Campus%20map.png) | ![Home](README_photos/landing.png) |

## Tech stack

- **Frontend** — Next.js 14 (App Router, TypeScript, Tailwind)
- **Backend** — Spring Boot (Java 21), JWT auth
- **Database** — PostgreSQL 16
- **Data** — class timetable scraped from EduPage; consultations scraped from the FINKI site
