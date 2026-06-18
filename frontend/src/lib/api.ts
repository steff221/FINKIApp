import type {
  AuthResponse,
  ConsultationSlotResponse,
  CustomEntryRequest,
  CustomEntryResponse,
  ExamResponse,
  ScheduleSlotResponse,
  TeacherWithSlotsResponse,
  TimetableFilters,
  TimetableFiltersResponse,
  UserScheduleResponse,
} from "@/types";

const BASE = "/api";

function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("finki_token");
}

function authHeaders(): HeadersInit {
  const token = getToken();
  return token ? { Authorization: `Bearer ${token}` } : {};
}

function handleAuthError(status: number): never {
  if (status === 401 || status === 403) {
    // clearAuth is not imported here to avoid circular deps — clear manually then signal
    localStorage.removeItem("finki_token");
    localStorage.removeItem("finki_userId");
    localStorage.removeItem("finki_email");
    window.dispatchEvent(new Event("finki:session-expired"));
    throw new Error("Session expired — please log in again.");
  }
  throw new Error(`HTTP ${status}`);
}

async function get<T>(path: string, params?: Record<string, string | number | null | undefined>): Promise<T> {
  const url = new URL(BASE + path, window.location.origin);
  if (params) {
    Object.entries(params).forEach(([k, v]) => {
      if (v !== null && v !== undefined) url.searchParams.set(k, String(v));
    });
  }
  const res = await fetch(url.toString(), { headers: authHeaders() });
  if (!res.ok) {
    if (res.status === 401 || res.status === 403) handleAuthError(res.status);
    throw new Error(`GET ${path} failed: ${res.status}`);
  }
  return res.json() as Promise<T>;
}

async function post<T>(path: string, body?: unknown): Promise<T> {
  const res = await fetch(BASE + path, {
    method: "POST",
    headers: { "Content-Type": "application/json", ...authHeaders() },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) handleAuthError(res.status);
  const text = await res.text();
  if (!text) return undefined as T;
  return JSON.parse(text) as T;
}

async function put<T>(path: string, body: unknown): Promise<T> {
  const res = await fetch(BASE + path, {
    method: "PUT",
    headers: { "Content-Type": "application/json", ...authHeaders() },
    body: JSON.stringify(body),
  });
  if (!res.ok) handleAuthError(res.status);
  const text = await res.text();
  if (!text) return undefined as T;
  return JSON.parse(text) as T;
}

async function del(path: string): Promise<void> {
  const res = await fetch(BASE + path, { method: "DELETE", headers: authHeaders() });
  if (!res.ok) handleAuthError(res.status);
}

// ── Auth ──────────────────────────────────────────────────────────────────────

async function postPublic<T>(path: string, body: unknown): Promise<T> {
  const res = await fetch(BASE + path, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`POST ${path} failed: ${res.status}`);
  return res.json() as Promise<T>;
}

export async function register(email: string, password: string): Promise<AuthResponse> {
  return postPublic("/auth/register", { email, password });
}

export async function login(email: string, password: string): Promise<AuthResponse> {
  return postPublic("/auth/login", { email, password });
}

// ── Timetable ─────────────────────────────────────────────────────────────────

export async function getSlots(
  filters: Partial<TimetableFilters>,
  opts?: { allEditions?: boolean }
): Promise<ScheduleSlotResponse[]> {
  return get("/timetable/slots", {
    year:          filters.year,
    programmeCode: filters.programmeCode,
    teacherId:     filters.teacherId,
    subjectId:     filters.subjectId,
    classroomId:   filters.classroomId,
    lessonType:    filters.lessonType,
    dayOfWeek:     filters.dayOfWeek,
    editionNumber: filters.editionNumber,
    allEditions:   opts?.allEditions ? "true" : undefined,
  });
}

export async function getFilters(): Promise<TimetableFiltersResponse> {
  return get("/timetable/filters");
}

// ── Consultations ─────────────────────────────────────────────────────────────

export async function getConsultations(q?: string): Promise<TeacherWithSlotsResponse[]> {
  return get("/consultations", q ? { q } : undefined);
}

export async function getConsultationsForTeacher(teacherId: number): Promise<ConsultationSlotResponse[]> {
  return get(`/consultations/teacher/${teacherId}`);
}

export async function getMyConsultationBookings(): Promise<number[]> {
  return get("/consultations/bookings/mine");
}

export async function getMyBookedConsultations(): Promise<ConsultationSlotResponse[]> {
  return get("/consultations/bookings/mine/slots");
}

export async function bookConsultation(slotId: number, reason: string): Promise<void> {
  return post(`/consultations/${slotId}/book`, { reason });
}

export async function cancelConsultationBooking(slotId: number): Promise<void> {
  return del(`/consultations/${slotId}/book`);
}

// ── Exams ─────────────────────────────────────────────────────────────────────

export async function getExamSessions(): Promise<string[]> {
  return get("/exams/sessions");
}

export async function getExams(session?: string | null, q?: string): Promise<ExamResponse[]> {
  return get("/exams", { session: session ?? undefined, q: q || undefined });
}

export function getExamsIcsUrl(session?: string | null, q?: string): string {
  const params = new URLSearchParams();
  if (session) params.set("session", session);
  if (q) params.set("q", q);
  const qs = params.toString();
  return `${BASE}/exams/export.ics${qs ? `?${qs}` : ""}`;
}

// ── Personal schedule ─────────────────────────────────────────────────────────

export async function getSchedule(): Promise<UserScheduleResponse> {
  return get("/schedule");
}

export async function addToSchedule(slotId: number): Promise<void> {
  return post(`/schedule/slots/${slotId}`);
}

export async function removeFromSchedule(slotId: number): Promise<void> {
  return del(`/schedule/slots/${slotId}`);
}

// ── Custom schedule entries ───────────────────────────────────────────────────

export async function getCustomEntries(): Promise<CustomEntryResponse[]> {
  return get("/schedule/custom");
}

export async function createCustomEntry(data: CustomEntryRequest): Promise<CustomEntryResponse> {
  return post("/schedule/custom", data);
}

export async function updateCustomEntry(id: number, data: CustomEntryRequest): Promise<CustomEntryResponse> {
  return put(`/schedule/custom/${id}`, data);
}

export async function deleteCustomEntry(id: number): Promise<void> {
  return del(`/schedule/custom/${id}`);
}

// The .ics feed is authenticated by a dedicated, opaque calendar token (fetched
// once and safe to embed in the subscription URL) — never the user's JWT.
export async function getIcsToken(): Promise<string> {
  const data = await get<{ token: string }>("/schedule/ics-token");
  return data.token;
}

export function getIcsUrl(calendarToken: string): string {
  return `${BASE}/schedule/export.ics?token=${calendarToken}`;
}
