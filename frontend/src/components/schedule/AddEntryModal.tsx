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
  defaultDay?: number;
  defaultStart?: string;
  defaultLab?: boolean;
  onSave: (data: CustomEntryRequest) => Promise<void>;
  onDelete?: () => Promise<void>;
  onClose: () => void;
}

const inputCls = "w-full bg-gray-50 border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400/40 focus:border-blue-400 transition-all";
const labelCls = "block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1";

export default function AddEntryModal({ initial, defaultDay = 0, defaultStart = "08:00", defaultLab = false, onSave, onDelete, onClose }: Props) {
  const [title,     setTitle]     = useState(initial?.title ?? "");
  const [professor, setProfessor] = useState(initial?.professor ?? "");
  const [entryType, setEntryType] = useState<"LECTURE" | "LAB" | "EXERCISE" | "COMBINED">(initial?.entryType ?? (defaultLab ? "LAB" : "LECTURE"));
  const [day,       setDay]       = useState(initial?.dayOfWeek ?? defaultDay);
  const [start,     setStart]     = useState(initial?.startTime?.substring(0,5) ?? defaultStart);
  const [end,       setEnd]       = useState(initial?.endTime?.substring(0,5) ?? "");
  const [room,      setRoom]      = useState(initial?.room ?? (defaultLab ? labLabel(LAB_ROOMS[0]) : ""));
  const [color,     setColor]     = useState(initial?.color ?? COLORS[0].value);
  const [saving,    setSaving]    = useState(false);
  const [error,     setError]     = useState<string | null>(null);
  const [sessionIdx, setSessionIdx] = useState(0);

  // Pull scraped subjects + teachers from the timetable filters (public endpoint)
  const { data: filters } = useSWR("/timetable/filters", () => getFilters());
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
    setEntryType(slot.subject.lessonType);
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

  // Professor suggestions — narrowed to the selected subject's teachers when available
  const teacherOptions = useMemo(() => {
    const forSubject = subjectTeacherMap.get(title);
    if (forSubject && forSubject.size > 0) {
      return Array.from(forSubject).sort((a, b) => a.localeCompare(b, "mk"));
    }
    return allTeachers;
  }, [title, subjectTeacherMap, allTeachers]);

  // All real sessions for the currently chosen subject + professor
  const matchingSlots = useMemo(
    () => subjectTeacherSlots.get(`${title}||${professor}`) ?? [],
    [title, professor, subjectTeacherSlots]
  );

  const isSubjectMatched = subjectTeacherMap.has(title) && (subjectTeacherMap.get(title)?.size ?? 0) > 0;
  const isAutoFilled = matchingSlots.length > 0;

  const isLab = entryType === "LAB";

  // Lab-room options — include the current room if it's an off-list (e.g. scraped) lab room
  const labOptions = useMemo(() => {
    const opts = LAB_ROOMS.map(labLabel);
    if (isLab && room && !opts.includes(room)) opts.unshift(room);
    return opts;
  }, [isLab, room]);

  function enterLabMode() {
    setEntryType("LAB");
    if (!room || !labOptions.includes(room)) setRoom(labLabel(LAB_ROOMS[0]));
  }

  function exitLabMode() {
    setEntryType("LECTURE");
    if (room.startsWith("Lab ")) setRoom("");   // clear the lab room when leaving lab mode
  }

  function handleTitleChange(value: string) {
    setTitle(value);
    // If the typed value exactly matches a scraped subject, adopt its lesson type
    const matchedType = subjectTypeMap.get(value);
    if (matchedType) setEntryType(matchedType);
    // Clear professor if it no longer teaches the newly selected subject
    const teachers = subjectTeacherMap.get(value);
    if (teachers && teachers.size > 0 && professor && !teachers.has(professor)) {
      setProfessor("");
    } else if (professor) {
      // Subject + professor still valid together → fill from the first real session
      const list = subjectTeacherSlots.get(`${value}||${professor}`) ?? [];
      if (list.length > 0) { setSessionIdx(0); applySlot(list[0]); }
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
    if (!title.trim()) { setError("Subject name is required."); return; }
    if (end <= start)   { setError("End time must be after start time."); return; }
    setSaving(true);
    try {
      await onSave({ title, professor, entryType, dayOfWeek: day, startTime: start, endTime: end, room, color });
      onClose();
    } catch {
      setError("Failed to save. Please try again.");
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!onDelete) return;
    setSaving(true);
    try { await onDelete(); onClose(); }
    catch { setError("Failed to delete."); }
    finally { setSaving(false); }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />

      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-label={initial ? "Edit entry" : "Add to calendar"}
        className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden"
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <h2 className="font-bold text-gray-900 text-base">
            {initial ? "Edit entry" : "Add to calendar"}
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
            <label className={labelCls}>Subject *</label>
            <input
              className={inputCls}
              placeholder="Search FINKI subjects or type your own…"
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
            {subjectOptions.length > 0 && (
              <p className="text-[11px] text-gray-400 mt-1">
                {subjectOptions.length} subjects from the FINKI timetable — or type a custom one
              </p>
            )}
          </div>

          {/* Professor */}
          <div>
            <label className={labelCls}>Professor / Assistant</label>
            <input
              className={inputCls}
              placeholder={isSubjectMatched ? "Professors for this subject…" : "Type the professor / assistant…"}
              value={professor}
              onChange={e => handleProfessorChange(e.target.value)}
              list={isSubjectMatched ? "finki-teachers" : undefined}
              name="finki-professor-search"
              autoComplete="off"
              data-lpignore="true"
              data-1p-ignore="true"
              data-form-type="other"
            />
            {isSubjectMatched && (
              <datalist id="finki-teachers">
                {teacherOptions.map(t => <option key={t} value={t} />)}
              </datalist>
            )}
            {isSubjectMatched && (
              <p className="text-[11px] text-blue-500 mt-1">
                Showing {teacherOptions.length} professor{teacherOptions.length === 1 ? "" : "s"} who teach “{title}”
              </p>
            )}
          </div>

          {/* Class session picker — shown when this prof teaches the subject more than once */}
          {matchingSlots.length > 1 && (
            <div>
              <label className={labelCls}>Class session ({matchingSlots.length})</label>
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
                Taught on multiple days / groups — pick the one you attend.
              </p>
            </div>
          )}

          {/* Auto-fill banner */}
          {isAutoFilled && (
            <div className="flex items-center gap-2 bg-blue-50 text-blue-700 rounded-lg px-3 py-2 text-xs">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                <path d="M20 6 9 17l-5-5" />
              </svg>
              Day, time &amp; room auto-filled from the FINKI timetable — edit if needed.
            </div>
          )}

          {/* Type / Lab + Day */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <div className="flex items-center justify-between mb-1 h-4">
                <label className="text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Type
                </label>
                <button
                  type="button"
                  onClick={isLab ? exitLabMode : enterLabMode}
                  className="text-[11px] font-semibold text-finki-mid hover:underline"
                >
                  {isLab ? "Use type" : "+ Add lab"}
                </button>
              </div>
              {isLab ? (
                <div className={`${inputCls} flex items-center gap-2 bg-emerald-50 border-emerald-200`}>
                  <span className="w-2 h-2 rounded-full bg-emerald-500" />
                  <span className="text-sm font-semibold text-emerald-700">Lab session</span>
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
              <label className={labelCls}>Day</label>
              <select className={inputCls} value={day} onChange={e => setDay(Number(e.target.value))}>
                {DAY_NAMES.map((d, i) => <option key={i} value={i}>{d}</option>)}
              </select>
            </div>
          </div>

          {/* Start + End */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={labelCls}>Start time</label>
              <input type="time" className={inputCls} value={start} onChange={e => setStart(e.target.value)} />
            </div>
            <div>
              <label className={labelCls}>End time</label>
              <input type="time" className={inputCls} value={end} onChange={e => setEnd(e.target.value)} />
            </div>
          </div>

          {/* Room — a lab-room dropdown in lab mode, free text otherwise */}
          <div>
            <label className={labelCls}>{isLab ? "Lab room" : "Room (optional)"}</label>
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
            <label className={labelCls}>Color</label>
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

          {error && <p className="text-xs text-red-600 bg-red-50 rounded-lg px-3 py-2">{error}</p>}

          {/* Actions */}
          <div className="flex items-center gap-2 pt-1">
            {onDelete && (
              <button
                type="button"
                onClick={handleDelete}
                disabled={saving}
                className="px-3 py-2 rounded-lg text-sm text-red-600 hover:bg-red-50 transition-colors font-medium"
              >
                Delete
              </button>
            )}
            <div className="ml-auto flex gap-2">
              <button type="button" onClick={onClose} className="px-4 py-2 rounded-lg text-sm text-gray-600 hover:bg-gray-100 transition-colors">
                Cancel
              </button>
              <button
                type="submit"
                disabled={saving}
                className="px-4 py-2 rounded-lg text-sm bg-finki-navy text-white font-semibold hover:bg-finki-mid transition-colors disabled:opacity-50"
              >
                {saving ? "Saving…" : initial ? "Save changes" : "Add entry"}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}
