"use client";

export function saveAuth(token: string, userId: number, email: string) {
  localStorage.setItem("finki_token", token);
  localStorage.setItem("finki_userId", String(userId));
  localStorage.setItem("finki_email", email);
}

export function clearAuth() {
  localStorage.removeItem("finki_token");
  localStorage.removeItem("finki_userId");
  localStorage.removeItem("finki_email");
}

export function getAuth(): { token: string; userId: number; email: string } | null {
  if (typeof window === "undefined") return null;
  const token = localStorage.getItem("finki_token");
  const userId = localStorage.getItem("finki_userId");
  const email = localStorage.getItem("finki_email");
  if (!token || !userId || !email) return null;
  return { token, userId: Number(userId), email };
}

export function isLoggedIn(): boolean {
  return getAuth() !== null;
}
