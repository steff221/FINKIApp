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
  instructions: string | null;
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
}

export const DAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

export const LESSON_TYPE_LABELS: Record<string, string> = {
  LECTURE:  "Lecture",
  LAB:      "Lab",
  EXERCISE: "Exercise",
  COMBINED: "Combined",
};

// Formats "HH:mm:ss" → "HH:mm"
export function formatTime(t: string): string {
  return t.substring(0, 5);
}
