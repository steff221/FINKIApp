"use client";

import type { useSchedule } from "@/hooks/useSchedule";
import { DAY_NAMES, formatTime } from "@/types";
import { getIcsUrl } from "@/lib/api";

interface Props { schedule: ReturnType<typeof useSchedule>; }

export default function SchedulePanel({ schedule }: Props) {
  const { schedule: data, conflictIds, remove } = schedule;

  if (!data) {
    return (
      <div className="bg-white rounded-xl shadow-panel p-5 text-sm text-gray-400 text-center">
        Loading schedule…
      </div>
    );
  }

  const byDay: Record<number, typeof data.slots> = {};
  data.slots.forEach(s => (byDay[s.dayOfWeek] ??= []).push(s));

  return (
    <div className="bg-white rounded-xl shadow-panel overflow-hidden flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100">
        <div className="flex items-center gap-2">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor"
            strokeWidth="2" className="text-finki-mid">
            <rect x="3" y="4" width="18" height="18" rx="2" />
            <path d="M16 2v4M8 2v4M3 10h18" />
          </svg>
          <h2 className="font-semibold text-sm text-gray-800">My Schedule</h2>
          {data.slots.length > 0 && (
            <span className="bg-finki-mid text-white text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center leading-none">
              {data.slots.length}
            </span>
          )}
        </div>
        {data.slots.length > 0 && (
          <a
            href={getIcsUrl()}
            download="finki-schedule.ics"
            className="flex items-center gap-1 text-xs text-finki-mid hover:text-finki-navy font-medium transition-colors"
          >
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
              <polyline points="7 10 12 15 17 10" />
              <line x1="12" y1="15" x2="12" y2="3" />
            </svg>
            Export .ics
          </a>
        )}
      </div>

      {/* Conflict warning */}
      {data.conflicts.length > 0 && (
        <div className="mx-4 mt-3 bg-red-50 border border-red-200 rounded-lg px-3 py-2 flex items-start gap-2">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
            strokeWidth="2" className="text-red-500 shrink-0 mt-0.5">
            <circle cx="12" cy="12" r="10" />
            <line x1="12" y1="8" x2="12" y2="12" />
            <line x1="12" y1="16" x2="12.01" y2="16" />
          </svg>
          <p className="text-xs text-red-700 font-medium">
            {data.conflicts.length} time conflict{data.conflicts.length > 1 ? "s" : ""} detected
          </p>
        </div>
      )}

      {/* Empty state */}
      {data.slots.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-10 px-5 text-center">
          <div className="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center mb-3">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
              strokeWidth="1.5" className="text-gray-400">
              <rect x="3" y="4" width="18" height="18" rx="2" />
              <path d="M16 2v4M8 2v4M3 10h18" />
            </svg>
          </div>
          <p className="text-sm font-medium text-gray-600">Your schedule is empty</p>
          <p className="text-xs text-gray-400 mt-1">Add classes from the timetable</p>
        </div>
      ) : (
        <div className="p-4 space-y-5 overflow-y-auto">
          {DAY_NAMES.map((dayName, i) => {
            const daySlots = byDay[i];
            if (!daySlots) return null;
            return (
              <div key={i}>
                <p className="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2">
                  {dayName}
                </p>
                <div className="space-y-1.5">
                  {daySlots
                    .sort((a, b) => a.startTime.localeCompare(b.startTime))
                    .map(slot => {
                      const conflict = conflictIds.has(slot.id);
                      return (
                        <div
                          key={slot.id}
                          className={`group flex items-center justify-between gap-2 rounded-lg px-3 py-2 transition-colors ${
                            conflict
                              ? "bg-red-50 border border-red-200"
                              : "bg-gray-50 border border-gray-100 hover:border-gray-200"
                          }`}
                        >
                          <div className="min-w-0 flex-1">
                            <p className="text-xs font-semibold text-gray-800 truncate">
                              {slot.subject.baseName}
                            </p>
                            <p className="text-xs text-gray-500 mt-0.5 tabular-nums">
                              {formatTime(slot.startTime)}–{formatTime(slot.endTime)}
                              {slot.classroom && (
                                <span className="text-gray-400"> · {slot.classroom.name}</span>
                              )}
                            </p>
                          </div>
                          <button
                            onClick={() => remove(slot.id)}
                            className="shrink-0 w-6 h-6 rounded-md flex items-center justify-center text-gray-300 hover:text-red-500 hover:bg-red-50 transition-colors opacity-0 group-hover:opacity-100"
                            title="Remove"
                          >
                            <svg width="12" height="12" viewBox="0 0 24 24" fill="none"
                              stroke="currentColor" strokeWidth="2.5">
                              <path d="M18 6 6 18M6 6l12 12" />
                            </svg>
                          </button>
                        </div>
                      );
                    })}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
