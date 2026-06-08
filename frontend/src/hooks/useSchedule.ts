"use client";

import useSWR from "swr";
import { addToSchedule, getSchedule, removeFromSchedule } from "@/lib/api";
import type { UserScheduleResponse } from "@/types";
import { isLoggedIn } from "@/lib/auth";

const SCHEDULE_KEY = "/api/schedule";

export function useSchedule() {
  const loggedIn = typeof window !== "undefined" && isLoggedIn();

  const { data, error, mutate } = useSWR<UserScheduleResponse>(
    loggedIn ? SCHEDULE_KEY : null,
    getSchedule
  );

  async function add(slotId: number) {
    await addToSchedule(slotId);
    await mutate();
  }

  async function remove(slotId: number) {
    await removeFromSchedule(slotId);
    await mutate();
  }

  const slotIds = new Set((data?.slots ?? []).map(s => s.id));
  const conflictIds = new Set((data?.conflicts ?? []).flat());

  return {
    schedule: data,
    isLoading: !error && !data && loggedIn,
    slotIds,
    conflictIds,
    add,
    remove,
    loggedIn,
  };
}
