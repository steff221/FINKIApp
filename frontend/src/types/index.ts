// ── API response types — mirror the Java DTOs exactly ────────────────────────

export interface ClassroomResponse {
  id: number;
  name: string;
  shortName: string | null;
}

export interface SubjectResponse {
  id: number;
  fullName: string;
  baseName: string;
  lessonType: "LECTURE" | "LAB" | "EXERCISE" | "COMBINED";
}

export interface TeacherResponse {
  id: number;
  cyrillicName: string | null;
  canonicalName: string | null;
  consultationUsername: string | null;
}

export interface StudyClassResponse {
  id: number;
  name: string;
  year: number | null;
  programmeCode: string | null;
}

export interface ScheduleSlotResponse {
  id: number;
  subject: SubjectResponse;
  teachers: TeacherResponse[];
  studyClasses: StudyClassResponse[];
  classroom: ClassroomResponse | null;
  dayOfWeek: number;     // 0=Mon … 4=Fri
  startTime: string;     // "HH:mm:ss" from Jackson LocalTime
  endTime: string;
  editionNumber: string;
}

export interface ConsultationSlotResponse {
  id: number;
  teacher: TeacherResponse;
  date: string;          // "YYYY-MM-DD"
  startTime: string;
  endTime: string;
  room: string | null;
  link: string | null;
  instructions: string | null;
  enrolledCount: number;
}

export interface TeacherWithSlotsResponse {
  teacher: TeacherResponse;
  slots: ConsultationSlotResponse[];
}

export interface TimetableFiltersResponse {
  years: number[];
  programmes: string[];
  subjects: SubjectResponse[];
  teachers: TeacherResponse[];
  classrooms: ClassroomResponse[];
  editions: string[];
  currentEdition: string | null;
}

export interface UserScheduleResponse {
  slots: ScheduleSlotResponse[];
  conflicts: number[][];
}

export interface AuthResponse {
  token: string;
  userId: number;
  email: string;
}

export interface CustomEntryResponse {
  id: number;
  title: string;
  professor: string | null;
  entryType: "LECTURE" | "LAB" | "EXERCISE" | "COMBINED";
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  room: string | null;
  color: string | null;
}

export interface CustomEntryRequest {
  title: string;
  professor: string;
  entryType: string;
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  room: string;
  color: string;
}

// ── Local state types ─────────────────────────────────────────────────────────

export interface TimetableFilters {
  year: number | null;
  programmeCode: string | null;
  teacherId: number | null;
  subjectId: number | null;
  classroomId: number | null;
  lessonType: string | null;
  dayOfWeek: number | null;
  editionNumber: string | null;
}

export const DAY_NAMES = ["Понеделник", "Вторник", "Среда", "Четврток", "Петок"];

// Human labels for known EduPage timetable editions (semesters)
export const EDITION_LABELS: Record<string, string> = {
  "28": "Летен 2025/26",
  "27": "Летен 2025/26 (прва недела)",
  "26": "Зимски 2025/26",
  "25": "Летен 2024/25",
  "23": "Зимски 2024/25",
};
export function editionLabel(num: string): string {
  return EDITION_LABELS[num] ?? `Едиција ${num}`;
}

export const LESSON_TYPE_LABELS: Record<string, string> = {
  LECTURE:  "Предавање",
  LAB:      "Лабораториски вежби",
  EXERCISE: "Аудиториски вежби",
  COMBINED: "Комбинирано",
};

// Formats "HH:mm:ss" → "HH:mm"
export function formatTime(t: string): string {
  return t.substring(0, 5);
}
