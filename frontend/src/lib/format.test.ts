import { describe, it, expect } from "vitest";
import { formatDuration } from "./format";

describe("formatDuration", () => {
  it("formats whole hours without minutes", () => {
    expect(formatDuration(60)).toBe("1ч");
    expect(formatDuration(120)).toBe("2ч");
  });

  it("formats sub-hour durations as minutes only", () => {
    expect(formatDuration(45)).toBe("45мин");
    expect(formatDuration(0)).toBe("0мин");
  });

  it("formats hours and minutes together", () => {
    expect(formatDuration(90)).toBe("1ч 30мин");
    expect(formatDuration(150)).toBe("2ч 30мин");
  });
});
