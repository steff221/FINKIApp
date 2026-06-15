import { describe, it, expect } from "vitest";
import {
  DAY_NAMES,
  LESSON_TYPE_LABELS,
  editionLabel,
  formatTime,
} from "./index";

describe("LESSON_TYPE_LABELS", () => {
  it("labels every lesson type", () => {
    expect(LESSON_TYPE_LABELS).toMatchObject({
      LECTURE: "Предавање",
      LAB: "Лабораториски вежби",
      EXERCISE: "Аудиториски вежби",
      COMBINED: "Комбинирано",
    });
  });

  it("keeps LAB and EXERCISE distinct", () => {
    // Regression guard: a previous change accidentally made both read
    // "Аудиториски вежби", producing duplicate legend entries.
    expect(LESSON_TYPE_LABELS.LAB).not.toBe(LESSON_TYPE_LABELS.EXERCISE);
  });

  it("has no duplicate labels across types", () => {
    const labels = Object.values(LESSON_TYPE_LABELS);
    expect(new Set(labels).size).toBe(labels.length);
  });
});

describe("editionLabel", () => {
  it("returns the human label for a known edition", () => {
    expect(editionLabel("28")).toBe("Летен 2025/26");
    expect(editionLabel("26")).toBe("Зимски 2025/26");
  });

  it("falls back to a generic label for an unknown edition", () => {
    expect(editionLabel("99")).toBe("Едиција 99");
  });
});

describe("formatTime", () => {
  it("trims HH:mm:ss to HH:mm", () => {
    expect(formatTime("08:30:00")).toBe("08:30");
  });

  it("leaves an already-short value unchanged", () => {
    expect(formatTime("14:15")).toBe("14:15");
  });
});

describe("DAY_NAMES", () => {
  it("lists the five weekdays Monday–Friday", () => {
    expect(DAY_NAMES).toEqual([
      "Понеделник",
      "Вторник",
      "Среда",
      "Четврток",
      "Петок",
    ]);
  });
});
