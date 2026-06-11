"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useSearchParams } from "next/navigation";

function isFemale(name: string): boolean {
  const first = name.trim().split(" ")[0] ?? "";
  return first.endsWith("а");
}
import useSWR, { mutate } from "swr";
import {
  getConsultationsForTeacher,
  getMyConsultationBookings,
  bookConsultation,
  cancelConsultationBooking,
} from "@/lib/api";
import { getAuth } from "@/lib/auth";
import type { ConsultationSlotResponse } from "@/types";
import { formatTime } from "@/types";

const MK_DAYS = ["недела", "понеделник", "вторник", "среда", "четврток", "петок", "сабота"];

function parseDateInfo(dateStr: string) {
  const [y, m, d] = dateStr.split("-").map(Number);
  const date = new Date(y, m - 1, d);
  const now   = new Date();
  const midnight = (dt: Date) => new Date(dt.getFullYear(), dt.getMonth(), dt.getDate());
  const diff  = Math.round((midnight(date).getTime() - midnight(now).getTime()) / 86_400_000);
  const label = `${d}.${m}.${y} (${MK_DAYS[date.getDay()]})`;
  let badge: string | null = null;
  let badgeCls = "";
  if (diff === 0)      { badge = "Денес";            badgeCls = "bg-emerald-100 text-emerald-700"; }
  else if (diff === 1) { badge = "Утре";             badgeCls = "bg-orange-100 text-orange-700"; }
  else if (diff > 1)   { badge = `За ${diff} дена`;  badgeCls = "bg-blue-50 text-blue-600"; }
  return { label, badge, badgeCls };
}

interface Props { params: { id: string } }

export default function ProfessorConsultationsPage({ params }: Props) {
  const teacherId   = Number(params.id);
  const auth        = typeof window !== "undefined" ? getAuth() : null;
  const searchParams = useSearchParams();
  const nameFromUrl  = searchParams.get("name") ?? "";

  const slotKey  = `/api/consultations/teacher/${teacherId}`;
  const mineKey  = auth ? "/api/consultations/bookings/mine" : null;

  const { data: slots, isLoading } = useSWR<ConsultationSlotResponse[]>(
    slotKey, () => getConsultationsForTeacher(teacherId)
  );
  const { data: mySlots } = useSWR<number[]>(mineKey, () => getMyConsultationBookings());

  const teacherName = slots?.[0]?.teacher?.cyrillicName ?? (nameFromUrl || "Професор");
  const female      = isFemale(teacherName);

  const [reasons, setReasons] = useState<Record<number, string>>({});
  const [saving,  setSaving]  = useState<Record<number, boolean>>({});
  const [errors,  setErrors]  = useState<Record<number, string>>({});

  async function handleBook(slotId: number) {
    setSaving(s => ({ ...s, [slotId]: true }));
    setErrors(e => ({ ...e, [slotId]: "" }));
    try {
      await bookConsultation(slotId, reasons[slotId] ?? "");
      await mutate(slotKey);
      await mutate(mineKey);
    } catch (err) {
      const msg = err instanceof Error ? err.message : "";
      setErrors(e => ({
        ...e,
        [slotId]: msg.includes("Session expired") ? msg : "Неуспешна пријава. Обидете се повторно.",
      }));
    } finally {
      setSaving(s => ({ ...s, [slotId]: false }));
    }
  }

  async function handleCancel(slotId: number) {
    setSaving(s => ({ ...s, [slotId]: true }));
    try {
      await cancelConsultationBooking(slotId);
      await mutate(slotKey);
      await mutate(mineKey);
    } catch {
      setErrors(e => ({ ...e, [slotId]: "Неуспешно откажување." }));
    } finally {
      setSaving(s => ({ ...s, [slotId]: false }));
    }
  }

  return (
    <div className="space-y-6">

      {/* ── Breadcrumb ── */}
      <Link
        href="/consultations"
        className="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-finki-navy transition-colors"
      >
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
          <path d="M19 12H5M12 5l-7 7 7 7" />
        </svg>
        Назад кон консултации
      </Link>

      {/* ── Professor header ── */}
      <div className="bg-white border border-gray-200 rounded-2xl px-6 py-5 flex items-center gap-4">
        <div className="w-14 h-14 rounded-full bg-gray-100 flex items-center justify-center shrink-0 overflow-hidden">
          <Image
            src={female ? "/Womanproffessor.png" : "/proffessor.png"}
            alt=""
            width={44}
            height={44}
            className="object-contain"
          />
        </div>
        <div>
          <h1 className="text-xl font-bold text-gray-900">{teacherName}</h1>
          {!isLoading && (
            <p className="text-sm text-gray-500 mt-0.5">
              {slots && slots.length > 0
                ? `${slots.length} ${slots.length === 1 ? "претстоен термин" : "претстојни термини"}`
                : "Нема претстојни термини"}
            </p>
          )}
        </div>
      </div>

      {/* ── Loading ── */}
      {isLoading && (
        <div className="flex justify-center py-16">
          <div className="w-8 h-8 border-2 border-gray-200 border-t-finki-navy rounded-full animate-spin" />
        </div>
      )}

      {/* ── Empty state ── */}
      {!isLoading && (!slots || slots.length === 0) && (
        <div className="bg-white border border-gray-200 rounded-2xl px-6 py-14 text-center">
          <svg className="mx-auto text-gray-300 mb-3" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
            <rect x="3" y="4" width="18" height="18" rx="2" />
            <path d="M16 2v4M8 2v4M3 10h18" />
          </svg>
          <p className="text-gray-500 text-sm font-medium">Нема закажани консултации</p>
          <p className="text-gray-400 text-xs mt-1">Проверете повторно подоцна</p>
        </div>
      )}

      {/* ── Slot cards ── */}
      {slots && slots.length > 0 && (
        <div className="space-y-4">
          {slots.map(slot => {
            const { label, badge, badgeCls } = parseDateInfo(slot.date);
            const isBooked = mySlots?.includes(slot.id) ?? false;
            const isSaving = saving[slot.id] ?? false;

            return (
              <div
                key={slot.id}
                className={`bg-white rounded-2xl border overflow-hidden transition-all ${
                  isBooked ? "border-emerald-300 shadow-sm shadow-emerald-100" : "border-gray-200"
                }`}
              >
                {/* Booked banner */}
                {isBooked && (
                  <div className="bg-emerald-500 px-5 py-2 flex items-center gap-2">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5">
                      <path d="M20 6 9 17l-5-5" />
                    </svg>
                    <span className="text-white text-xs font-semibold">Пријавени сте за оваа консултација</span>
                  </div>
                )}

                <div className="grid grid-cols-1 md:grid-cols-5">

                  {/* ── Left: details (3/5) ── */}
                  <div className="md:col-span-3 p-5 space-y-3.5">

                    {/* Date + time row */}
                    <div className="flex flex-wrap gap-4">
                      <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-lg bg-finki-navy/5 flex items-center justify-center shrink-0">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-finki-navy">
                            <rect x="3" y="4" width="18" height="18" rx="2" /><path d="M16 2v4M8 2v4M3 10h18" />
                          </svg>
                        </div>
                        <div>
                          <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest">Датум</p>
                          <div className="flex items-center gap-1.5 mt-0.5 flex-wrap">
                            <span className="text-sm font-medium text-gray-800">{label}</span>
                            {badge && (
                              <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full ${badgeCls}`}>
                                {badge}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-lg bg-finki-navy/5 flex items-center justify-center shrink-0">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-finki-navy">
                            <circle cx="12" cy="12" r="10" /><path d="M12 6v6l4 2" />
                          </svg>
                        </div>
                        <div>
                          <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest">Време</p>
                          <p className="text-sm font-medium text-gray-800 mt-0.5">
                            {formatTime(slot.startTime)} – {formatTime(slot.endTime)}
                          </p>
                        </div>
                      </div>
                    </div>

                    {/* Location + enrolled */}
                    <div className="flex flex-wrap gap-4">
                      {slot.room && (
                        <div className="flex items-center gap-2.5">
                          <div className="w-8 h-8 rounded-lg bg-finki-navy/5 flex items-center justify-center shrink-0">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-finki-navy">
                              <path d="M20 10c0 6-8 12-8 12S4 16 4 10a8 8 0 1 1 16 0Z" /><circle cx="12" cy="10" r="3" />
                            </svg>
                          </div>
                          <div>
                            <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest">Локација</p>
                            <p className="text-sm font-medium text-gray-800 mt-0.5">{slot.room}</p>
                          </div>
                        </div>
                      )}

                      <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-lg bg-finki-navy/5 flex items-center justify-center shrink-0">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-finki-navy">
                            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" />
                            <path d="M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" />
                          </svg>
                        </div>
                        <div>
                          <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest">Пријавени</p>
                          <p className="text-sm font-medium text-gray-800 mt-0.5">
                            {slot.enrolledCount} {slot.enrolledCount === 1 ? "студент" : "студенти"}
                          </p>
                        </div>
                      </div>
                    </div>

                    {/* Link */}
                    {slot.link && (
                      <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-lg bg-blue-50 flex items-center justify-center shrink-0">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-blue-600">
                            <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71" />
                            <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71" />
                          </svg>
                        </div>
                        <div>
                          <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest">Онлајн линк</p>
                          <a
                            href={slot.link.startsWith("http") ? slot.link : `https://${slot.link}`}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-sm text-blue-600 hover:underline mt-0.5 block"
                          >
                            {slot.link.replace(/^https?:\/\//, "").split("/")[0]}
                          </a>
                        </div>
                      </div>
                    )}

                    {/* Instructions */}
                    {slot.instructions && (
                      <div className="border-l-4 border-finki-navy pl-4 py-1">
                        <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Напомена</p>
                        <p className="text-sm text-gray-700 leading-relaxed">{slot.instructions}</p>
                      </div>
                    )}
                  </div>

                  {/* ── Right: registration (2/5) ── */}
                  <div className="md:col-span-2 border-t md:border-t-0 md:border-l border-gray-100 p-5 flex flex-col gap-3">
                    <p className="text-xs font-bold text-gray-500 uppercase tracking-widest">Пријава</p>

                    {!auth ? (
                      <div className="flex-1 flex flex-col items-center justify-center bg-gray-50 rounded-xl border border-dashed border-gray-200 px-4 py-8 text-center gap-3">
                        <svg className="text-gray-300" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                          <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" />
                        </svg>
                        <p className="text-sm text-gray-500">
                          <Link href="/" className="text-blue-600 hover:underline font-semibold">
                            Најавете се
                          </Link>{" "}
                          за да се пријавите
                        </p>
                      </div>
                    ) : isBooked ? (
                      <div className="flex-1 flex flex-col gap-3">
                        <div className="flex-1 flex items-center justify-center bg-emerald-50 rounded-xl px-4 py-6">
                          <p className="text-sm text-emerald-700 font-semibold text-center">Успешно пријавени</p>
                        </div>
                        <button
                          onClick={() => handleCancel(slot.id)}
                          disabled={isSaving}
                          className="w-full border border-red-200 text-red-600 rounded-xl py-2.5 text-sm font-semibold hover:bg-red-50 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
                        >
                          {isSaving
                            ? <span className="w-4 h-4 border-2 border-red-300 border-t-red-600 rounded-full animate-spin" />
                            : <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M18 6 6 18M6 6l12 12" /></svg>}
                          Откажи пријава
                        </button>
                      </div>
                    ) : (
                      <div className="flex-1 flex flex-col gap-3">
                        <textarea
                          className="flex-1 border border-gray-200 rounded-xl px-3 py-2.5 text-sm resize-none focus:outline-none focus:ring-2 focus:ring-finki-navy/25 focus:border-finki-navy transition-all min-h-[100px] bg-gray-50 placeholder:text-gray-400"
                          placeholder="Причина за консултации (незадолжително)…"
                          maxLength={500}
                          value={reasons[slot.id] ?? ""}
                          onChange={e => setReasons(r => ({ ...r, [slot.id]: e.target.value }))}
                        />
                        {errors[slot.id] && (
                          <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-lg px-3 py-2">
                            {errors[slot.id]}
                          </p>
                        )}
                        <button
                          onClick={() => handleBook(slot.id)}
                          disabled={isSaving}
                          className="w-full bg-finki-navy text-white rounded-xl py-3 text-sm font-semibold hover:bg-finki-mid transition-colors disabled:opacity-50 flex items-center justify-center gap-2 shadow-sm"
                        >
                          {isSaving
                            ? <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                            : <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20 6 9 17l-5-5" /></svg>}
                          {isSaving ? "Се пријавува…" : "Пријави се"}
                        </button>
                      </div>
                    )}
                  </div>

                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
