"use client";

import { useState, useEffect, useMemo, useRef } from "react";
import useSWR from "swr";
import type { CustomEntryResponse, CustomEntryRequest, ScheduleSlotResponse } from "@/types";
import { DAY_NAMES, LESSON_TYPE_LABELS } from "@/types";
import { getFilters, getSlots } from "@/lib/api";
import { useFocusTrap } from "@/hooks/useFocusTrap";

// FINKI lab rooms selectable via the "Add lab" button
const LAB_ROOMS = ["2", "3", "13", "12", "117", "200b", "200v"];
const labLabel = (n: string) => `Lab ${n}`;

// Laboratory assistants per subject, suggested in the "Add lab" flow.
// Matched by keywords (case/spacing/spelling tolerant) so both the exact scraped
// name and loosely-typed variants resolve to the right assistant.
const LAB_ASSISTANT_RULES: { keywords: string[]; assistants: string[] }[] = [
  { keywords: ["дизајн", "интеракциј", "компјутер"], assistants: ["Христина Здравеска"] },
];
// Assistants explicitly mapped to this subject ([] if none match)
function matchedLabAssistants(title: string): string[] {
  const t = title.toLowerCase();
  for (const rule of LAB_ASSISTANT_RULES) {
    if (rule.keywords.every(k => t.includes(k))) return rule.assistants;
  }
  return [];
}

// Suggestions for the lab-mode assistant field (only explicitly mapped ones)

const COLORS = [
  { value: "#3b82f6", label: "Blue",    tw: "bg-blue-500" },
  { value: "#10b981", label: "Green",   tw: "bg-emerald-500" },
  { value: "#8b5cf6", label: "Violet",  tw: "bg-violet-500" },
  { value: "#f59e0b", label: "Amber",   tw: "bg-amber-500" },
  { value: "#ef4444", label: "Red",     tw: "bg-red-500" },
  { value: "#06b6d4", label: "Cyan",    tw: "bg-cyan-500" },
  { value: "#6366f1", label: "Indigo",  tw: "bg-indigo-500" },
  { value: "#ec4899", label: "Pink",    tw: "bg-pink-500" },
];

interface Props {
  initial?: CustomEntryResponse | null;
  prefill?: Partial<CustomEntryRequest>;
  defaultDay?: number;
  defaultStart?: string;
  defaultLab?: boolean;
  onSave: (data: CustomEntryRequest) => Promise<void>;
  onDelete?: () => Promise<void>;
  onDuplicate?: (data: CustomEntryRequest) => void;
  onClose: () => void;
}

const inputCls = "w-full bg-gray-50 border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400/40 focus:border-blue-400 transition-all";
const labelCls = "block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1";

export default function AddEntryModal({ initial, prefill, defaultDay = 0, defaultStart = "08:00", defaultLab = false, onSave, onDelete, onDuplicate, onClose }: Props) {
  const [title,     setTitle]     = useState(initial?.title     ?? prefill?.title     ?? "");
  const [professor, setProfessor] = useState(initial?.professor ?? prefill?.professor ?? "");
  const [entryType, setEntryType] = useState<"LECTURE" | "LAB" | "EXERCISE" | "COMBINED">((initial?.entryType ?? prefill?.entryType ?? (defaultLab ? "LAB" : "LECTURE")) as "LECTURE" | "LAB" | "EXERCISE" | "COMBINED");
  const [day,       setDay]       = useState(initial?.dayOfWeek ?? prefill?.dayOfWeek ?? defaultDay);
  const [start,     setStart]     = useState(initial?.startTime?.substring(0,5) ?? prefill?.startTime?.substring(0,5) ?? defaultStart);
  const [end,       setEnd]       = useState(initial?.endTime?.substring(0,5)   ?? prefill?.endTime?.substring(0,5)   ?? "");
  const [room,      setRoom]      = useState(initial?.room  ?? prefill?.room  ?? (defaultLab ? labLabel(LAB_ROOMS[0]) : ""));
  const [color,     setColor]     = useState(initial?.color ?? prefill?.color ?? COLORS[0].value);
  const [saving,    setSaving]    = useState(false);
  const [saved,     setSaved]     = useState(false);
  const [error,     setError]     = useState<string | null>(null);
  const closeTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  useEffect(() => () => { if (closeTimerRef.current) clearTimeout(closeTimerRef.current); }, []);
  const [sessionIdx, setSessionIdx] = useState(0);

  // Pull scraped subjects + teachers from the timetable filters (public endpoint)
  const { data: filters, isLoading: filtersLoading, error: filtersError } = useSWR("/timetable/filters", () => getFilters());
  // Pull all timetable slots (every edition) so we can link each subject to its teachers/sessions
  const { data: slots } = useSWR("/timetable/slots/all", () => getSlots({}, { allEditions: true }));

  // Unique scraped subject names (baseName) for the Subject autocomplete
  const subjectOptions = useMemo(() => {
    const set = new Set<string>();
    filters?.subjects.forEach(s => { if (s.baseName) set.add(s.baseName); });
    return Array.from(set).sort((a, b) => a.localeCompare(b, "mk"));
  }, [filters]);

  // Map a subject baseName → its lesson type, so picking a subject pre-sets the type
  const subjectTypeMap = useMemo(() => {
    const m = new Map<string, "LECTURE" | "LAB" | "EXERCISE" | "COMBINED">();
    filters?.subjects.forEach(s => { if (s.baseName && !m.has(s.baseName)) m.set(s.baseName, s.lessonType); });
    return m;
  }, [filters]);

  // Map a subject baseName → the set of teacher names who teach it (built from real slots)
  const subjectTeacherMap = useMemo(() => {
    const m = new Map<string, Set<string>>();
    slots?.forEach(slot => {
      const key = slot.subject.baseName;
      if (!key) return;
      if (!m.has(key)) m.set(key, new Set());
      slot.teachers.forEach(t => { if (t.cyrillicName) m.get(key)!.add(t.cyrillicName); });
    });
    return m;
  }, [slots]);

  // Map "subject||teacher" → ALL real slots (a prof may teach the same subject on
  // several days / for different study groups, e.g. Mon·СИИС and Tue·SEIS)
  const subjectTeacherSlots = useMemo(() => {
    const m = new Map<string, ScheduleSlotResponse[]>();
    slots?.forEach(slot => {
      const subjKey = slot.subject.baseName;
      if (!subjKey) return;
      slot.teachers.forEach(t => {
        if (!t.cyrillicName) return;
        const key = `${subjKey}||${t.cyrillicName}`;
        if (!m.has(key)) m.set(key, []);
        m.get(key)!.push(slot);
      });
    });
    // Sort each list by day then start time so the picker reads top-to-bottom
    m.forEach(list => list.sort((a, b) =>
      a.dayOfWeek - b.dayOfWeek || a.startTime.localeCompare(b.startTime)));
    return m;
  }, [slots]);

  // Map a subject baseName → ALL its real slots (any teacher), sorted by day/time.
  // Lets us auto-fill day/time/room the moment a subject is picked, before a
  // specific professor is chosen.
  const subjectSlots = useMemo(() => {
    const m = new Map<string, ScheduleSlotResponse[]>();
    slots?.forEach(slot => {
      const key = slot.subject.baseName;
      if (!key) return;
      if (!m.has(key)) m.set(key, []);
      m.get(key)!.push(slot);
    });
    m.forEach(list => list.sort((a, b) =>
      a.dayOfWeek - b.dayOfWeek || a.startTime.localeCompare(b.startTime)));
    return m;
  }, [slots]);

  // Suppresses the auto-end-time effect when we prefill start+end from a real slot
  const prefilling = useRef(false);
  const dialogRef = useRef<HTMLDivElement>(null);
  useFocusTrap(dialogRef);

  function applySlot(slot: ScheduleSlotResponse) {
    prefilling.current = true;
    setDay(slot.dayOfWeek);
    setStart(slot.startTime.substring(0, 5));
    setEnd(slot.endTime.substring(0, 5));
    if (slot.classroom?.name) setRoom(slot.classroom.name);
    // Don't override explicit lab mode — user made a deliberate choice
    if (entryType !== "LAB") setEntryType(slot.subject.lessonType);
  }

  // Human label for a session option, e.g. "Tuesday 08:00–10:45 · 1г-СИИС · Барака 1"
  function sessionLabel(slot: ScheduleSlotResponse): string {
    const groups = slot.studyClasses.map(c => c.name).join(" / ");
    const time   = `${slot.startTime.substring(0, 5)}–${slot.endTime.substring(0, 5)}`;
    const room   = slot.classroom?.name ? ` · ${slot.classroom.name}` : "";
    return `${DAY_NAMES[slot.dayOfWeek]} ${time}${groups ? " · " + groups : ""}${room}`;
  }

  // All scraped teacher names (fallback when no specific subject is selected)
  const allTeachers = useMemo(() => {
    const set = new Set<string>();
    filters?.teachers.forEach(t => { if (t.cyrillicName) set.add(t.cyrillicName); });
    return Array.from(set).sort((a, b) => a.localeCompare(b, "mk"));
  }, [filters]);

  // Memoized so matchedLabAssistants(title) is computed once per title change
  const matchedAssistants = useMemo(() => matchedLabAssistants(title), [title]);

  // Professor suggestions — narrowed to the selected subject's teachers when available,
  // plus any lab assistants explicitly mapped to that subject
  const teacherOptions = useMemo(() => {
    const forSubject = subjectTeacherMap.get(title);
    const base = forSubject && forSubject.size > 0 ? Array.from(forSubject) : allTeachers;
    const merged = Array.from(new Set([...base, ...matchedAssistants]));
    return merged.sort((a, b) => a.localeCompare(b, "mk"));
  }, [title, subjectTeacherMap, allTeachers, matchedAssistants]);

  // All real sessions for the currently chosen subject + professor
  const matchingSlots = useMemo(
    () => subjectTeacherSlots.get(`${title}||${professor}`) ?? [],
    [title, professor, subjectTeacherSlots]
  );

  const subjectHasTeachers = (subjectTeacherMap.get(title)?.size ?? 0) > 0;
  const isSubjectMatched = subjectHasTeachers || matchedAssistants.length > 0;
  const isAutoFilled = matchingSlots.length > 0;

  const isLab = entryType === "LAB";

  // Lab-room options — include the current room if it's an off-list (e.g. scraped) lab room
  const labOptions = useMemo(() => {
    const opts = LAB_ROOMS.map(labLabel);
    if (isLab && room && !opts.includes(room)) opts.unshift(room);
    return opts;
  }, [isLab, room]);


  function handleTitleChange(value: string) {
    setTitle(value);
    // If the typed value exactly matches a scraped subject, adopt its lesson type
    // but don't override explicit lab mode — user made a deliberate choice
    const matchedType = subjectTypeMap.get(value);
    if (matchedType && entryType !== "LAB") setEntryType(matchedType);

    const teachers = subjectTeacherMap.get(value);
    // Keep the current professor only if they actually teach the new subject.
    const keepProfessor = !!professor && (teachers?.has(professor) ?? false);
    if (professor && !keepProfessor) setProfessor("");

    if (keepProfessor) {
      // Subject + professor still valid together → fill from their first session
      const list = subjectTeacherSlots.get(`${value}||${professor}`) ?? [];
      if (list.length > 0) { setSessionIdx(0); applySlot(list[0]); }
    } else {
      // No professor yet → auto-fill day/time/room from the subject's first real
      // session, adopting that session's teacher (the user can still change it).
      const list = subjectSlots.get(value) ?? [];
      if (list.length > 0) {
        const first = list[0];
        const teacher = first.teachers.find(t => t.cyrillicName)?.cyrillicName ?? "";
        if (teacher) setProfessor(teacher);
        setSessionIdx(0);
        applySlot(first);
      }
    }
  }

  function handleProfessorChange(value: string) {
    setProfessor(value);
    // When this professor teaches the selected subject, fill from the first real session
    const list = subjectTeacherSlots.get(`${title}||${value}`) ?? [];
    if (list.length > 0) { setSessionIdx(0); applySlot(list[0]); }
  }

  // Close on Escape
  useEffect(() => {
    const h = (e: KeyboardEvent) => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", h);
    return () => window.removeEventListener("keydown", h);
  }, [onClose]);

  // Auto-set end time 1.5h after start when start changes — skipped when prefilling from a real slot
  useEffect(() => {
    if (prefilling.current) { prefilling.current = false; return; }
    if (!initial && start) {
      const [h, m] = start.split(":").map(Number);
      const totalMin = h * 60 + m + 90;
      setEnd(`${String(Math.floor(totalMin / 60)).padStart(2, "0")}:${String(totalMin % 60).padStart(2, "0")}`);
    }
  }, [start]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim()) { setError("Името на предметот е задолжително."); return; }
    if (end <= start)   { setError("Крајното врeme мора да биде после почетното."); return; }
    setSaving(true);
    setError(null);
    try {
      await onSave({ title, professor, entryType, dayOfWeek: day, startTime: start, endTime: end, room, color });
      setSaved(true);
      closeTimerRef.current = setTimeout(onClose, 600);
    } catch (err) {
      const msg = err instanceof Error ? err.message : "";
      setError(msg.includes("Session expired") ? msg : "Грешка при зачувување. Обидете се повторно.");
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!onDelete) return;
    setSaving(true);
    try { await onDelete(); onClose(); }
    catch { setError("Грешка при бришење."); }
    finally { setSaving(false); }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />

      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-label={initial ? "Уреди запис" : "Додај во календар"}
        className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md max-h-[90vh] overflow-y-auto"
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <h2 className="font-bold text-gray-900 text-base">
            {initial ? "Уреди запис" : "Додај во календар"}
          </h2>
          <button onClick={onClose} className="w-7 h-7 rounded-full hover:bg-gray-100 flex items-center justify-center transition-colors">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <path d="M18 6 6 18M6 6l12 12" />
            </svg>
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-5 space-y-4" autoComplete="off">
          {/* Subject */}
          <div>
            <label className={labelCls}>Предмет *</label>
            <input
              className={inputCls}
              placeholder="Пребарај ФИНКИ предмети или внесете свој…"
              value={title}
              onChange={e => handleTitleChange(e.target.value)}
              list="finki-subjects"
              name="finki-subject-search"
              autoComplete="off"
              data-lpignore="true"
              data-1p-ignore="true"
              data-form-type="other"
              autoFocus
            />
            <datalist id="finki-subjects">
              {subjectOptions.map(s => <option key={s} value={s} />)}
            </datalist>
            {filtersLoading ? (
              <p className="text-[11px] text-gray-400 mt-1 flex items-center gap-1.5">
                <span className="inline-block w-2.5 h-2.5 border border-gray-300 border-t-gray-500 rounded-full animate-spin" />
                Се вчитуваат предметите…
              </p>
            ) : filtersError ? (
              <p className="text-[11px] text-red-400 mt-1">Не може да се вчита листата — може да внесете свое имe</p>
            ) : subjectOptions.length > 0 ? (
              <p className="text-[11px] text-gray-400 mt-1">
                {subjectOptions.length} предмети од ФИНКИ распоредот — или внесете свој
              </p>
            ) : null}
          </div>

          {/* Professor */}
          <div>
            <label className={labelCls}>Предавач / Асистент</label>
            <input
              className={inputCls}
              placeholder={
                isLab ? "Лабораториски асистент…"
                : isSubjectMatched ? "Предавачи за овој предмет…"
                : "Внесете предавач / асистент…"
              }
              value={professor}
              onChange={e => handleProfessorChange(e.target.value)}
              list={isLab ? "finki-lab-assistants" : isSubjectMatched ? "finki-teachers" : undefined}
              name="finki-professor-search"
              autoComplete="off"
              data-lpignore="true"
              data-1p-ignore="true"
              data-form-type="other"
            />
            {isSubjectMatched && !isLab && (
              <datalist id="finki-teachers">
                {teacherOptions.map(t => <option key={t} value={t} />)}
              </datalist>
            )}
            {isLab && (
              <datalist id="finki-lab-assistants">
                {matchedAssistants.map((t: string) => <option key={t} value={t} />)}
              </datalist>
            )}
            {subjectHasTeachers && !isLab && (
              <p className="text-[11px] text-blue-500 mt-1">
                {teacherOptions.length} предавач{teacherOptions.length === 1 ? "" : "и"} за „{title}"
              </p>
            )}
          </div>

          {/* Class session picker — shown when this prof teaches the subject more than once */}
          {matchingSlots.length > 1 && (
            <div>
              <label className={labelCls}>Термин ({matchingSlots.length})</label>
              <select
                className={inputCls}
                value={sessionIdx}
                onChange={e => { const i = Number(e.target.value); setSessionIdx(i); applySlot(matchingSlots[i]); }}
              >
                {matchingSlots.map((s, i) => (
                  <option key={i} value={i}>{sessionLabel(s)}</option>
                ))}
              </select>
              <p className="text-[11px] text-gray-400 mt-1">
                Предметот се предава во повеќе термини — изберете го вашиот.
              </p>
            </div>
          )}

          {/* Auto-fill banner */}
          {isAutoFilled && (
            <div className="flex items-center gap-2 bg-blue-50 text-blue-700 rounded-lg px-3 py-2 text-xs">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                <path d="M20 6 9 17l-5-5" />
              </svg>
              Ден, врeme и просторија автоматски пополнети од ФИНКИ распоредот — уредете ако е потребно.
            </div>
          )}

          {/* Type / Lab + Day */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <div className="flex items-center mb-1 h-4">
                <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Тип
                </label>
              </div>
              {isLab ? (
                <div className={`${inputCls} flex items-center gap-2 bg-emerald-50 border-emerald-200`}>
                  <span className="w-2 h-2 rounded-full bg-emerald-500" />
                  <span className="text-sm font-semibold text-emerald-700 flex-1">{LESSON_TYPE_LABELS.LAB}</span>
                </div>
              ) : (
                <select className={inputCls} value={entryType} onChange={e => setEntryType(e.target.value as "LECTURE" | "EXERCISE" | "COMBINED")}>
                  <option value="LECTURE">{LESSON_TYPE_LABELS.LECTURE}</option>
                  <option value="EXERCISE">{LESSON_TYPE_LABELS.EXERCISE}</option>
                  <option value="COMBINED">{LESSON_TYPE_LABELS.COMBINED}</option>
                </select>
              )}
            </div>
            <div>
              <label className={labelCls}>Ден</label>
              <select className={inputCls} value={day} onChange={e => setDay(Number(e.target.value))}>
                {DAY_NAMES.map((d, i) => <option key={i} value={i}>{d}</option>)}
              </select>
            </div>
          </div>

          {/* Start + End */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={labelCls}>Почеток</label>
              <input type="time" className={inputCls} value={start} onChange={e => setStart(e.target.value)} />
            </div>
            <div>
              <label className={labelCls}>Крај</label>
              <input type="time" className={inputCls} value={end} onChange={e => setEnd(e.target.value)} />
            </div>
          </div>

          {/* Room — a lab-room dropdown in lab mode, free text otherwise */}
          <div>
            <label className={labelCls}>{isLab ? "Просторија" : "Просторија (незадолжително)"}</label>
            {isLab ? (
              <select className={inputCls} value={room} onChange={e => setRoom(e.target.value)}>
                {labOptions.map(l => <option key={l} value={l}>{l}</option>)}
              </select>
            ) : (
              <input
                className={inputCls}
                placeholder="e.g. Барака 1"
                value={room}
                onChange={e => setRoom(e.target.value)}
              />
            )}
          </div>

          {/* Color */}
          <div>
            <label className={labelCls}>Боја</label>
            <div className="flex gap-2 flex-wrap">
              {COLORS.map(c => (
                <button
                  key={c.value}
                  type="button"
                  title={c.label}
                  onClick={() => setColor(c.value)}
                  className={`w-7 h-7 rounded-full ${c.tw} transition-transform ${
                    color === c.value ? "ring-2 ring-offset-2 ring-gray-400 scale-110" : "hover:scale-105"
                  }`}
                />
              ))}
            </div>
          </div>

          {error && (
            <p className="text-xs text-red-600 bg-red-50 rounded-lg px-3 py-2 flex items-center gap-2">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" className="shrink-0">
                <circle cx="12" cy="12" r="10"/><path d="M12 8v4M12 16h.01"/>
              </svg>
              {error}
            </p>
          )}

          {/* Actions */}
          <div className="flex items-center gap-2 pt-1">
            {onDelete && (
              <button
                type="button"
                onClick={handleDelete}
                disabled={saving || saved}
                className="px-3 py-2 rounded-lg text-sm text-red-600 hover:bg-red-50 transition-colors font-medium"
              >
                Избриши
              </button>
            )}
            {onDuplicate && (
              <button
                type="button"
                onClick={() => onDuplicate({ title, professor, entryType, dayOfWeek: day, startTime: start, endTime: end, room, color })}
                disabled={saving || saved}
                className="px-3 py-2 rounded-lg text-sm text-gray-500 hover:bg-gray-100 transition-colors font-medium flex items-center gap-1.5"
              >
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                  <rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
                </svg>
                Дуплирај
              </button>
            )}
            <div className="ml-auto flex gap-2">
              <button type="button" onClick={onClose} disabled={saving || saved} className="px-4 py-2 rounded-lg text-sm text-gray-600 hover:bg-gray-100 transition-colors disabled:opacity-40">
                Откажи
              </button>
              <button
                type="submit"
                disabled={saving || saved}
                className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all flex items-center gap-2 ${
                  saved
                    ? "bg-emerald-500 text-white"
                    : "bg-finki-navy text-white hover:bg-finki-mid disabled:opacity-50"
                }`}
              >
                {saving && <span className="w-3.5 h-3.5 border-2 border-white/40 border-t-white rounded-full animate-spin" />}
                {saved
                  ? <><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3"><path d="M20 6 9 17l-5-5"/></svg> Зачувано</>
                  : saving ? "Се зачувува…"
                  : initial ? "Зачувај промени"
                  : "Додај запис"}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}
