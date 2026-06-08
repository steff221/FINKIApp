"use client";

import type { useSchedule } from "@/hooks/useSchedule";
import { DAY_NAMES, formatTime } from "@/types";
import { getIcsUrl } from "@/lib/api";

interface Props { schedule: ReturnType<typeof useSchedule>; }

export default function SchedulePanel({ schedule }: Props) {
  const { schedule: data, conflictIds, remove } = schedule;

  if (!data) return <div className="text-sm text-gray-400">Loading schedule…</div>;

  const byDay: Record<number, typeof data.slots> = {};
  data.slots.forEach(s => (byDay[s.dayOfWeek] ??= []).push(s));

  return (
    <div className="bg-white border rounded-lg p-4 space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="font-semibold text-gray-800">My Schedule</h2>
        {data.slots.length > 0 && (
          <a
            href={getIcsUrl()}
            download="finki-schedule.ics"
            className="text-xs text-finki-light hover:underline"
          >
            Export .ics
          </a>
        )}
      </div>

      {data.conflicts.length > 0 && (
        <div className="bg-red-50 border border-red-200 rounded p-2 text-xs text-red-700">
          {data.conflicts.length} conflict{data.conflicts.length > 1 ? "s" : ""} detected.
          Conflicting slots are highlighted in red.
        </div>
      )}

      {data.slots.length === 0 ? (
        <p className="text-sm text-gray-400">
          Add classes from the timetable to build your schedule.
        </p>
      ) : (
        <div className="space-y-4 text-sm">
          {DAY_NAMES.map((dayName, i) => {
            const daySlots = byDay[i];
            if (!daySlots) return null;
            return (
              <div key={i}>
                <p className="text-xs font-semibold text-gray-500 uppercase mb-1">{dayName}</p>
                <div className="space-y-1">
                  {daySlots
                    .sort((a, b) => a.startTime.localeCompare(b.startTime))
                    .map(slot => (
                      <div
                        key={slot.id}
                        className={`flex items-center justify-between gap-1 rounded px-2 py-1 ${
                          conflictIds.has(slot.id)
                            ? "bg-red-50 border border-red-300"
                            : "bg-gray-50 border border-gray-200"
                        }`}
                      >
                        <div className="min-w-0">
                          <p className="font-medium truncate text-xs">{slot.subject.baseName}</p>
                          <p className="text-xs text-gray-500">
                            {formatTime(slot.startTime)}–{formatTime(slot.endTime)}
                            {slot.classroom && ` · ${slot.classroom.name}`}
                          </p>
                        </div>
                        <button
                          onClick={() => remove(slot.id)}
                          className="shrink-0 text-gray-400 hover:text-red-500 text-sm"
                          title="Remove"
                        >
                          ✕
                        </button>
                      </div>
                    ))}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
