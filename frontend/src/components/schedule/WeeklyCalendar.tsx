"use client";

import { useMemo, useState } from "react";
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

interface Props {
  entries: CustomEntryResponse[];
  onAdd: (day: number, startTime: string) => void;
  onEdit: (entry: CustomEntryResponse) => void;
}

export default function WeeklyCalendar({ entries, onAdd, onEdit }: Props) {
  const [hoverCell, setHoverCell] = useState<{ day: number; hour: number } | null>(null);

  const byDay = useMemo(() => {
    const map: Record<number, CustomEntryResponse[]> = {};
    for (let i = 0; i < 5; i++) map[i] = [];
    entries.forEach(e => {
      if (e.dayOfWeek >= 0 && e.dayOfWeek <= 4) map[e.dayOfWeek].push(e);
    });
    return map;
  }, [entries]);

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
    <div className="bg-white rounded-2xl shadow-card overflow-hidden border border-gray-100">
      {/* Day headers */}
      <div className="grid grid-cols-[56px_repeat(5,1fr)] border-b border-gray-100 bg-gray-50/60">
        <div className="py-3" />
        {DAY_NAMES.map((day, i) => (
          <div key={i} className="py-3 text-center">
            <span className="text-xs font-bold text-gray-500 uppercase tracking-widest">{day}</span>
          </div>
        ))}
      </div>

      {/* Grid body */}
      <div className="grid grid-cols-[56px_repeat(5,1fr)] overflow-auto" style={{ maxHeight: "calc(100vh - 220px)" }}>
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

            {/* Entries */}
            {byDay[day].map(entry => {
              const top    = topPct(entry.startTime);
              const height = Math.max(heightPct(entry.startTime, entry.endTime), 24);
              const style  = TYPE_STYLE[entry.entryType] ?? TYPE_STYLE.LECTURE;
              const bgColor = entry.color ?? undefined;
              const shortTitle = entry.title.length > 20 ? entry.title.slice(0, 18) + "…" : entry.title;

              return (
                <div
                  key={entry.id}
                  className={`absolute left-1 right-1 rounded-lg ${style.text} px-2 py-1 overflow-hidden shadow-sm hover:shadow-md transition-shadow cursor-pointer z-10`}
                  style={{ top, height, backgroundColor: bgColor ?? undefined, filter: bgColor ? undefined : undefined }}
                  onClick={e => { e.stopPropagation(); onEdit(entry); }}
                >
                  <div className={`inline-block text-[9px] font-bold uppercase tracking-wide rounded px-1 mb-0.5 ${
                    bgColor ? "bg-black/20 text-white" : style.badge
                  }`}>
                    {LESSON_TYPE_LABELS[entry.entryType]}
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
  );
}
