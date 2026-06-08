"use client";

import type { ScheduleSlotResponse } from "@/types";
import { DAY_NAMES, LESSON_TYPE_LABELS, formatTime } from "@/types";
import type { useSchedule } from "@/hooks/useSchedule";
import ConsultationInline from "@/components/consultations/ConsultationInline";
import { useState } from "react";

interface Props {
  slots: ScheduleSlotResponse[];
  schedule: ReturnType<typeof useSchedule>;
}

const LESSON_TYPE_COLORS: Record<string, string> = {
  LECTURE:  "bg-blue-50  border-blue-300",
  LAB:      "bg-green-50 border-green-300",
  EXERCISE: "bg-yellow-50 border-yellow-300",
  COMBINED: "bg-purple-50 border-purple-300",
};

export default function TimetableGrid({ slots, schedule }: Props) {
  const [expandedTeacher, setExpandedTeacher] = useState<number | null>(null);

  if (slots.length === 0) {
    return <p className="text-gray-500 mt-8 text-center">No slots match the current filters.</p>;
  }

  const byDay: Record<number, ScheduleSlotResponse[]> = {};
  slots.forEach(s => {
    (byDay[s.dayOfWeek] ??= []).push(s);
  });

  return (
    <div className="space-y-6">
      {DAY_NAMES.map((dayName, dayIndex) => {
        const daySlots = byDay[dayIndex];
        if (!daySlots) return null;
        return (
          <div key={dayIndex}>
            <h2 className="font-semibold text-gray-700 mb-2 border-b pb-1">{dayName}</h2>
            <div className="space-y-2">
              {daySlots
                .sort((a, b) => a.startTime.localeCompare(b.startTime))
                .map(slot => {
                  const inSchedule = schedule.slotIds.has(slot.id);
                  const hasConflict = inSchedule && schedule.conflictIds.has(slot.id);
                  const colorClass = LESSON_TYPE_COLORS[slot.subject.lessonType] ?? "bg-gray-50 border-gray-200";

                  return (
                    <div
                      key={slot.id}
                      className={`border rounded-lg p-3 ${colorClass} ${
                        hasConflict ? "ring-2 ring-red-500" : ""
                      }`}
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div className="min-w-0">
                          <div className="flex items-center gap-2 flex-wrap">
                            <span className="font-medium text-sm">{slot.subject.baseName}</span>
                            <span className="text-xs px-1.5 py-0.5 rounded bg-white border text-gray-600">
                              {LESSON_TYPE_LABELS[slot.subject.lessonType]}
                            </span>
                            {hasConflict && (
                              <span className="text-xs px-1.5 py-0.5 rounded bg-red-100 text-red-700 border border-red-300">
                                Conflict
                              </span>
                            )}
                          </div>
                          <div className="text-xs text-gray-500 mt-1 space-x-2">
                            <span>{formatTime(slot.startTime)} – {formatTime(slot.endTime)}</span>
                            {slot.classroom && <span>· {slot.classroom.name}</span>}
                          </div>
                          {slot.teachers.length > 0 && (
                            <div className="text-xs text-gray-600 mt-1">
                              {slot.teachers.map((t, i) => (
                                <span key={t.id}>
                                  <button
                                    onClick={() => setExpandedTeacher(
                                      expandedTeacher === t.id ? null : t.id
                                    )}
                                    className="text-finki-light hover:underline"
                                  >
                                    {t.cyrillicName ?? t.consultationUsername ?? "Unknown"}
                                  </button>
                                  {i < slot.teachers.length - 1 && ", "}
                                </span>
                              ))}
                            </div>
                          )}
                          {slot.studyClasses.length > 0 && (
                            <div className="text-xs text-gray-400 mt-0.5">
                              {slot.studyClasses.map(sc => sc.name).join(", ")}
                            </div>
                          )}
                        </div>

                        {schedule.loggedIn && (
                          <button
                            onClick={() => inSchedule
                              ? schedule.remove(slot.id)
                              : schedule.add(slot.id)
                            }
                            className={`shrink-0 text-xs px-2 py-1 rounded border font-medium transition-colors ${
                              inSchedule
                                ? "bg-finki-blue text-white border-finki-blue hover:bg-red-600 hover:border-red-600"
                                : "bg-white text-finki-blue border-finki-blue hover:bg-finki-blue hover:text-white"
                            }`}
                          >
                            {inSchedule ? "✓ Added" : "+ Add"}
                          </button>
                        )}
                      </div>

                      {/* Inline consultation slots for this teacher */}
                      {slot.teachers.some(t => t.id === expandedTeacher) && (
                        <div className="mt-3 pt-3 border-t">
                          <ConsultationInline
                            teacherId={expandedTeacher!}
                            teacherName={
                              slot.teachers.find(t => t.id === expandedTeacher)?.cyrillicName ?? ""
                            }
                          />
                        </div>
                      )}
                    </div>
                  );
                })}
            </div>
          </div>
        );
      })}
    </div>
  );
}
