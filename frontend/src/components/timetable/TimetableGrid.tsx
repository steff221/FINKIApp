"use client";

import Link from "next/link";
import type { ScheduleSlotResponse } from "@/types";
import { DAY_NAMES, LESSON_TYPE_LABELS, formatTime } from "@/types";
import type { useSchedule } from "@/hooks/useSchedule";
import ConsultationInline from "@/components/consultations/ConsultationInline";
import { useState } from "react";

interface Props {
  slots: ScheduleSlotResponse[];
  schedule: ReturnType<typeof useSchedule>;
}

const TYPE_STYLES: Record<string, { pill: string; card: string; dot: string }> = {
  LECTURE:  { pill: "bg-blue-100 text-blue-700",   card: "border-l-blue-400",   dot: "bg-blue-400" },
  LAB:      { pill: "bg-emerald-100 text-emerald-700", card: "border-l-emerald-400", dot: "bg-emerald-400" },
  EXERCISE: { pill: "bg-amber-100 text-amber-700",  card: "border-l-amber-400",  dot: "bg-amber-400" },
  COMBINED: { pill: "bg-violet-100 text-violet-700",card: "border-l-violet-400", dot: "bg-violet-400" },
};
const FALLBACK = { pill: "bg-gray-100 text-gray-600", card: "border-l-gray-300", dot: "bg-gray-400" };

const MK_DAYS_SHORT = ["Пон", "Вто", "Сре", "Чет", "Пет"];

export default function TimetableGrid({ slots, schedule }: Props) {
  const [expandedTeacher, setExpandedTeacher] = useState<number | null>(null);
  const todayIdx = (() => { const d = new Date().getDay(); return d >= 1 && d <= 5 ? d - 1 : 0; })();
  const [mobileDay, setMobileDay] = useState(todayIdx);

  if (slots.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-24 text-center">
        <div className="w-12 h-12 rounded-full bg-gray-100 flex items-center justify-center mb-3">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor"
            strokeWidth="1.5" className="text-gray-400">
            <rect x="3" y="4" width="18" height="18" rx="2" />
            <path d="M16 2v4M8 2v4M3 10h18" />
          </svg>
        </div>
        <p className="font-medium text-gray-600">Нема часови за избраните филтри</p>
        <p className="text-sm text-gray-400 mt-1">Обидете се да ги промените или ресетирате филтрите</p>
      </div>
    );
  }

  const byDay: Record<number, ScheduleSlotResponse[]> = {};
  slots.forEach(s => { (byDay[s.dayOfWeek] ??= []).push(s); });
  const daysWithSlots = DAY_NAMES.map((_, i) => i).filter(i => byDay[i]);

  return (
    <>
      {/* ── Mobile day tabs ── */}
      <div className="flex lg:hidden gap-1 mb-4 bg-gray-100 p-1 rounded-xl overflow-x-auto">
        {daysWithSlots.map(i => (
          <button
            key={i}
            onClick={() => setMobileDay(i)}
            className={`flex-1 min-w-[52px] py-2 rounded-lg text-xs font-bold transition-all ${
              mobileDay === i
                ? "bg-white text-finki-navy shadow-sm"
                : "text-gray-500 hover:text-gray-700"
            }`}
          >
            <div>{MK_DAYS_SHORT[i]}</div>
            {byDay[i] && (
              <div className={`text-[10px] mt-0.5 ${mobileDay === i ? "text-finki-mid" : "text-gray-400"}`}>
                {byDay[i].length}
              </div>
            )}
          </button>
        ))}
      </div>

    <div className="space-y-8">
      {DAY_NAMES.map((dayName, dayIndex) => {
        const daySlots = byDay[dayIndex];
        if (!daySlots) return null;
        const hiddenOnMobile = dayIndex !== mobileDay;

        return (
          <section key={dayIndex} className={hiddenOnMobile ? "hidden lg:block" : ""}>
            {/* Day header */}
            <div className="flex items-center gap-3 mb-3">
              <h2 className="text-xs font-semibold text-gray-400 uppercase tracking-widest whitespace-nowrap">
                {dayName}
              </h2>
              <div className="flex-1 h-px bg-gray-200" />
              <span className="text-xs text-gray-400 font-medium">{daySlots.length}</span>
            </div>

            {/* Slot cards */}
            <div className="space-y-2.5">
              {daySlots
                .sort((a, b) => a.startTime.localeCompare(b.startTime))
                .map(slot => {
                  const inSchedule  = schedule.slotIds.has(slot.id);
                  const hasConflict = inSchedule && schedule.conflictIds.has(slot.id);
                  const style = TYPE_STYLES[slot.subject.lessonType] ?? FALLBACK;

                  return (
                    <div
                      key={slot.id}
                      className={`group bg-white rounded-xl shadow-card hover:shadow-card-hover transition-all duration-150 border-l-4 ${style.card} overflow-hidden ${
                        hasConflict ? "ring-2 ring-red-400 ring-offset-1" : ""
                      }`}
                    >
                      <div className="px-4 py-3">
                        <div className="flex items-start gap-3">
                          {/* Time column */}
                          <div className="shrink-0 text-center min-w-[52px]">
                            <p className="text-xs font-semibold text-gray-800 tabular-nums">
                              {formatTime(slot.startTime)}
                            </p>
                            <div className="flex justify-center my-0.5">
                              <div className="w-px h-4 bg-gray-200" />
                            </div>
                            <p className="text-xs text-gray-400 tabular-nums">
                              {formatTime(slot.endTime)}
                            </p>
                          </div>

                          {/* Divider */}
                          <div className="w-px self-stretch bg-gray-100 mx-1" />

                          {/* Content */}
                          <div className="flex-1 min-w-0">
                            <div className="flex items-start justify-between gap-2">
                              <div className="min-w-0">
                                <div className="flex items-center gap-2 flex-wrap">
                                  <span className="font-semibold text-sm text-gray-900 leading-tight">
                                    {slot.subject.baseName}
                                  </span>
                                  <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${style.pill}`}>
                                    {LESSON_TYPE_LABELS[slot.subject.lessonType]}
                                  </span>
                                  {hasConflict && (
                                    <span className="text-xs px-2 py-0.5 rounded-full bg-red-100 text-red-700 font-medium">
                                      Конфликт
                                    </span>
                                  )}
                                </div>

                                {/* Meta row */}
                                <div className="flex items-center gap-3 mt-1.5 flex-wrap">
                                  {slot.classroom && (
                                    <span className="flex items-center gap-1 text-xs text-gray-500">
                                      <svg width="11" height="11" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" strokeWidth="2" className="shrink-0">
                                        <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
                                        <polyline points="9 22 9 12 15 12 15 22" />
                                      </svg>
                                      {slot.classroom.name}
                                    </span>
                                  )}
                                  {slot.studyClasses.length > 0 && (
                                    <span className="text-xs text-gray-400">
                                      {slot.studyClasses.map(sc => sc.name).join(", ")}
                                    </span>
                                  )}
                                </div>

                                {/* Teachers */}
                                {slot.teachers.length > 0 && (
                                  <div className="flex flex-wrap gap-1 mt-2">
                                    {slot.teachers.map((t, i) => (
                                      <span key={t.id} className="inline-flex items-center gap-1">
                                        <button
                                          onClick={() =>
                                            setExpandedTeacher(
                                              expandedTeacher === t.id ? null : t.id
                                            )
                                          }
                                          className={`text-xs px-2 py-0.5 rounded-md border transition-colors ${
                                            expandedTeacher === t.id
                                              ? "bg-finki-navy text-white border-finki-navy"
                                              : "bg-gray-50 text-finki-mid border-gray-200 hover:border-finki-mid hover:bg-blue-50"
                                          }`}
                                        >
                                          {t.cyrillicName ?? t.consultationUsername ?? "Unknown"}
                                        </button>
                                        {t.consultationUsername && (
                                          <Link
                                            href={`/consultations/professor/${t.id}?name=${encodeURIComponent(t.cyrillicName ?? "")}`}
                                            onClick={e => e.stopPropagation()}
                                            title="Консултации"
                                            className="text-gray-300 hover:text-finki-navy transition-colors"
                                          >
                                            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                                              <rect x="3" y="4" width="18" height="18" rx="2" /><path d="M16 2v4M8 2v4M3 10h18" /><path d="m9 16 2 2 4-4" />
                                            </svg>
                                          </Link>
                                        )}
                                        {i < slot.teachers.length - 1 && " "}
                                      </span>
                                    ))}
                                  </div>
                                )}
                              </div>

                              {/* Add/remove button */}
                              {schedule.loggedIn && (
                                <button
                                  onClick={() =>
                                    inSchedule
                                      ? schedule.remove(slot.id)
                                      : schedule.add(slot.id)
                                  }
                                  className={`shrink-0 text-xs px-3 py-1.5 rounded-lg font-semibold border transition-all duration-150 ${
                                    inSchedule
                                      ? "bg-finki-navy text-white border-finki-navy hover:bg-red-600 hover:border-red-600"
                                      : "bg-white text-finki-mid border-gray-200 hover:border-finki-mid hover:bg-blue-50"
                                  }`}
                                >
                                  {inSchedule ? "✓ Додадено" : "+ Додај"}
                                </button>
                              )}
                            </div>
                          </div>
                        </div>

                        {/* Inline consultation panel */}
                        {slot.teachers.some(t => t.id === expandedTeacher) && (
                          <div className="mt-3 pt-3 border-t border-gray-100">
                            <ConsultationInline
                              teacherId={expandedTeacher!}
                              teacherName={
                                slot.teachers.find(t => t.id === expandedTeacher)
                                  ?.cyrillicName ?? ""
                              }
                            />
                          </div>
                        )}
                      </div>
                    </div>
                  );
                })}
            </div>
          </section>
        );
      })}
    </div>
    </>
  );
}
