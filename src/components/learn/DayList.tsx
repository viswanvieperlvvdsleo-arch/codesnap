"use client";

import { Button } from "@/components/ui/button";
import { CheckCircle2 } from "lucide-react";
import { cn } from "@/lib/utils";
import type { LearnContent } from "@/lib/types";

interface DayListProps {
  days: LearnContent[];
  activeDay: number;
  completedDays: Set<number>;
  onDaySelect: (day: number) => void;
}

export function DayList({
  days,
  activeDay,
  completedDays,
  onDaySelect,
}: DayListProps) {
  return (
    <div className="p-2 space-y-1">
      {days.map((item) => (
        <Button
          key={item.day}
          variant={item.day === activeDay ? "secondary" : "ghost"}
          className="w-full justify-start gap-3"
          onClick={() => onDaySelect(item.day)}
        >
          <CheckCircle2
            className={cn(
              "h-5 w-5",
              completedDays.has(item.day)
                ? "text-success"
                : "text-muted-foreground/50"
            )}
          />
          <span className="flex-1 text-left">Day {item.day}: {item.title}</span>
        </Button>
      ))}
    </div>
  );
}
