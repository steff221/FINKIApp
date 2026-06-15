"use client";

import { useMemo, useEffect, useRef } from "react";
import type { CustomEntryResponse } from "@/types";
import { DAY_NAMES, LESSON_TYPE_LABELS, formatTime } from "@/types";

const HOUR_HEIGHT = 64;   // px per hour
const START_HOUR  = 7;    // 07:00
const END_HOUR    = 22;   // 22:00
const TOTAL_HOURS = END_HOUR - START_HOUR;

function timeToMinutes(t: string): number {
  const [h, m] = t.split(":").map(Number);
  return h * 60 + m;
}

function topPct(time: string): number {
  const mins = timeToMinutes(time) - START_HOUR * 60;
  return (mins / 60) * HOUR_HEIGHT;
}

function heightPct(start: string, end: string): number {
  const mins = timeToMinutes(end) - timeToMinutes(start);
  return (mins / 60) * HOUR_HEIGHT;
}

const TYPE_STYLE: Record<string, { bg: string; text: string; badge: string }> = {
  LECTURE:  { bg: "bg-blue-500",    text: "text-white",     badge: "bg-blue-700/40" },
  LAB:      { bg: "bg-emerald-500", text: "text-white",     badge: "bg-emerald-700/40" },
  EXERCISE: { bg: "bg-violet-500",  text: "text-white",     badge: "bg-violet-700/40" },
  COMBINED: { bg: "bg-amber-500",   text: "text-white",     badge: "bg-amber-700/40" },
};

// A booked consultation rendered as a read-only block on the weekly grid.
// dayOfWeek is derived from the slot's calendar date (0=Mon … 4=Fri).
export interface CalendarConsultation {
  id: number;
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  title: string;       // teacher name
  room: string | null;
  date: string;        // "YYYY-MM-DD" — shown so the specific day is clear
}

// A positioned item on a day column: either an editable custom entry or a
// read-only booked consultation. `key` is unique across both kinds.
type DayItem =
  | { key: string; kind: "entry"; startTime: string; endTime: string; entry: CustomEntryResponse }
  | { key: string; kind: "consultation"; startTime: string; endTime: string; consultation: CalendarConsultation };

interface Props {
  entries: CustomEntryResponse[];
  consultations?: CalendarConsultation[];
  conflictIds?: Set<number>;
  onAdd: (day: number, startTime: string) => void;
  onEdit: (entry: CustomEntryResponse) => void;
}

// Greedy column assignment so overlapping items render side-by-side rather than
// stacking on top of each other. Returns key → {col, cols}.
function layoutDay(dayItems: DayItem[]): Map<string, { col: number; cols: number }> {
  const tm = (t: string) => timeToMinutes(t);
  const sorted = [...dayItems].sort(
    (a, b) => tm(a.startTime) - tm(b.startTime) || tm(a.endTime) - tm(b.endTime)
  );
  const result = new Map<string, { col: number; cols: number }>();

  let cluster: DayItem[] = [];
  let clusterEnd = -1;
  const flush = (group: DayItem[]) => {
    const colEnds: number[] = [];
    group.forEach(e => {
      let placed = false;
      for (let c = 0; c < colEnds.length; c++) {
        if (tm(e.startTime) >= colEnds[c]) { colEnds[c] = tm(e.endTime); result.set(e.key, { col: c, cols: 0 }); placed = true; break; }
      }
      if (!placed) { result.set(e.key, { col: colEnds.length, cols: 0 }); colEnds.push(tm(e.endTime)); }
    });
    group.forEach(e => { result.get(e.key)!.cols = colEnds.length; });
  };

  sorted.forEach(e => {
    if (cluster.length === 0 || tm(e.startTime) < clusterEnd) {
      cluster.push(e);
      clusterEnd = Math.max(clusterEnd, tm(e.endTime));
    } else {
      flush(cluster);
      cluster = [e];
      clusterEnd = tm(e.endTime);
    }
  });
  if (cluster.length) flush(cluster);
  return result;
}

export default function WeeklyCalendar({ entries, consultations = [], conflictIds, onAdd, onEdit }: Props) {
  // Current time indicator
  const now = new Date();
  const nowH = now.getHours() + now.getMinutes() / 60;
  const showTimeIndicator = nowH >= START_HOUR && nowH < END_HOUR;
  const timeTop = (nowH - START_HOUR) * HOUR_HEIGHT;
  // DAY_NAMES is Mon–Fri (0–4); JS getDay() is Sun=0. Returns -1 on weekends.
  const todayIdx = (now.getDay() + 6) % 7;

  const scrollRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (scrollRef.current && showTimeIndicator) {
      scrollRef.current.scrollTop = Math.max(0, timeTop - 120);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const byDay = useMemo(() => {
    const map: Record<number, DayItem[]> = {};
    for (let i = 0; i < 5; i++) map[i] = [];
    entries.forEach(e => {
      if (e.dayOfWeek >= 0 && e.dayOfWeek <= 4)
        map[e.dayOfWeek].push({ key: `e-${e.id}`, kind: "entry", startTime: e.startTime, endTime: e.endTime, entry: e });
    });
    consultations.forEach(c => {
      if (c.dayOfWeek >= 0 && c.dayOfWeek <= 4)
        map[c.dayOfWeek].push({ key: `c-${c.id}`, kind: "consultation", startTime: c.startTime, endTime: c.endTime, consultation: c });
    });
    return map;
  }, [entries, consultations]);

  const layouts = useMemo(() => {
    const m: Record<number, Map<string, { col: number; cols: number }>> = {};
    for (let i = 0; i < 5; i++) m[i] = layoutDay(byDay[i]);
    return m;
  }, [byDay]);

  const hours = Array.from({ length: TOTAL_HOURS }, (_, i) => START_HOUR + i);

  function handleColumnClick(day: number, e: React.MouseEvent<HTMLDivElement>) {
    const rect = e.currentTarget.getBoundingClientRect();
    const y = e.clientY - rect.top;
    const mins = Math.round((y / HOUR_HEIGHT) * 60 / 15) * 15;
    const totalMins = START_HOUR * 60 + mins;
    const h = Math.floor(totalMins / 60);
    const m = totalMins % 60;
    onAdd(day, `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`);
  }

  return (
    <div className="bg-white rounded-2xl shadow-card border border-gray-100 overflow-x-auto">
      <div className="min-w-[560px]">
      {/* Day headers */}
      <div className="grid grid-cols-[56px_repeat(5,1fr)] border-b border-gray-100 bg-gray-50/60">
        <div className="py-3" />
        {DAY_NAMES.map((day, i) => {
          const isToday = i === todayIdx;
          return (
            <div key={i} className={`py-3 text-center ${isToday ? "bg-finki-navy/5" : ""}`}>
              <span className={`text-xs font-bold uppercase tracking-widest ${isToday ? "text-finki-navy" : "text-gray-500"}`}>{day}</span>
              {isToday && <span className="block mx-auto mt-1 w-1.5 h-1.5 rounded-full bg-finki-navy" />}
            </div>
          );
        })}
      </div>

      {/* Grid body */}
      <div ref={scrollRef} className="grid grid-cols-[56px_repeat(5,1fr)] overflow-y-auto" style={{ maxHeight: "calc(100vh - 220px)" }}>
        {/* Time gutter */}
        <div className="relative" style={{ height: TOTAL_HOURS * HOUR_HEIGHT }}>
          {hours.map(h => (
            <div
              key={h}
              className="absolute w-full flex items-start justify-end pr-3"
              style={{ top: (h - START_HOUR) * HOUR_HEIGHT, height: HOUR_HEIGHT }}
            >
              <span className="text-[10px] font-medium text-gray-400 -translate-y-[6px]">
                {String(h).padStart(2, "0")}:00
              </span>
            </div>
          ))}
          {showTimeIndicator && (
            <div
              className="absolute right-2 w-2 h-2 rounded-full bg-red-500 z-20 -translate-y-1 pointer-events-none"
              style={{ top: timeTop }}
            />
          )}
        </div>

        {/* Day columns */}
        {Array.from({ length: 5 }, (_, day) => (
          <div
            key={day}
            className="relative border-l border-gray-100 cursor-pointer group"
            style={{ height: TOTAL_HOURS * HOUR_HEIGHT }}
            onClick={e => handleColumnClick(day, e)}
          >
            {/* Hour lines */}
            {hours.map(h => (
              <div
                key={h}
                className="absolute w-full border-t border-gray-100"
                style={{ top: (h - START_HOUR) * HOUR_HEIGHT }}
              />
            ))}

            {/* Half-hour lines */}
            {hours.map(h => (
              <div
                key={`${h}-half`}
                className="absolute w-full border-t border-gray-50"
                style={{ top: (h - START_HOUR) * HOUR_HEIGHT + HOUR_HEIGHT / 2 }}
              />
            ))}

            {/* Hover add hint */}
            <div className="absolute inset-0 group-hover:bg-blue-50/30 transition-colors pointer-events-none" />

            {/* Current-time indicator */}
            {showTimeIndicator && (
              <div
                className="absolute left-0 right-0 border-t-2 border-red-400 z-20 pointer-events-none"
                style={{ top: timeTop }}
              />
            )}

            {/* Entries + booked consultations */}
            {byDay[day].map(item => {
              const top    = topPct(item.startTime);
              const height = Math.max(heightPct(item.startTime, item.endTime), 24);

              // Side-by-side placement within the day column when items overlap
              const { col, cols } = layouts[day].get(item.key) ?? { col: 0, cols: 1 };
              const widthPct = 100 / cols;
              const leftCalc = `calc(${col * widthPct}% + 4px)`;
              const widthStyle = `calc(${widthPct}% - ${cols > 1 ? 6 : 8}px)`;
              const posStyle = { top, height, left: leftCalc, width: widthStyle };

              if (item.kind === "consultation") {
                const c = item.consultation;
                const shortTitle = c.title.length > 20 ? c.title.slice(0, 18) + "…" : c.title;
                return (
                  <div
                    key={item.key}
                    title={`Консултации — ${c.title}${c.room ? ` · ${c.room}` : ""} (${c.date})`}
                    className="absolute rounded-lg bg-slate-700 text-white px-2 py-1 overflow-hidden shadow-sm cursor-default z-10 ring-1 ring-white/10"
                    style={posStyle}
                    onClick={e => e.stopPropagation()}
                  >
                    <div className="flex items-center gap-1 mb-0.5">
                      <span className="inline-flex items-center gap-1 text-[9px] font-bold uppercase tracking-wide rounded px-1 bg-white/15">
                        <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" className="shrink-0">
                          <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
                        </svg>
                        Консултации
                      </span>
                    </div>
                    <p className="text-xs font-semibold leading-tight truncate">{shortTitle}</p>
                    {height > 36 && c.room && (
                      <p className="text-[10px] opacity-80 truncate">{c.room}</p>
                    )}
                    {height > 52 && (
                      <p className="text-[10px] opacity-60 mt-0.5">
                        {formatTime(c.startTime)}–{formatTime(c.endTime)}
                      </p>
                    )}
                  </div>
                );
              }

              const entry  = item.entry;
              const style  = TYPE_STYLE[entry.entryType] ?? TYPE_STYLE.LECTURE;
              const bgColor = entry.color ?? undefined;
              const shortTitle = entry.title.length > 20 ? entry.title.slice(0, 18) + "…" : entry.title;
              const conflict = conflictIds?.has(entry.id) ?? false;

              return (
                <div
                  key={item.key}
                  title={conflict ? "Overlaps another entry" : entry.title}
                  className={`absolute rounded-lg ${style.text} px-2 py-1 overflow-hidden shadow-sm hover:shadow-md hover:z-20 transition-shadow cursor-pointer z-10 ${
                    conflict ? "ring-2 ring-red-500 ring-offset-1" : ""
                  }`}
                  style={{ ...posStyle, backgroundColor: bgColor ?? undefined }}
                  onClick={e => { e.stopPropagation(); onEdit(entry); }}
                >
                  <div className="flex items-center gap-1 mb-0.5">
                    <span className={`inline-block text-[9px] font-bold uppercase tracking-wide rounded px-1 ${
                      bgColor ? "bg-black/20 text-white" : style.badge
                    }`}>
                      {LESSON_TYPE_LABELS[entry.entryType]}
                    </span>
                    {conflict && (
                      <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" className="shrink-0">
                        <path d="M12 9v4M12 17h.01M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z" />
                      </svg>
                    )}
                  </div>
                  <p className="text-xs font-semibold leading-tight truncate">{shortTitle}</p>
                  {height > 36 && entry.professor && (
                    <p className="text-[10px] opacity-80 truncate">{entry.professor}</p>
                  )}
                  {height > 52 && (
                    <p className="text-[10px] opacity-60 mt-0.5">
                      {formatTime(entry.startTime)}–{formatTime(entry.endTime)}
                    </p>
                  )}
                </div>
              );
            })}
          </div>
        ))}
      </div>
      </div>
    </div>
  );
}
