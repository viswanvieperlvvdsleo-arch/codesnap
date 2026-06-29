"use client"

import { useEffect, useState } from "react"
import { differenceInDays, parseISO } from "date-fns"
import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"

interface CountdownBadgeProps {
  deadline: string;
}

export function CountdownBadge({ deadline }: CountdownBadgeProps) {
  const [daysLeft, setDaysLeft] = useState<number | null>(null);

  useEffect(() => {
    const calculateDays = () => {
      const now = new Date();
      const deadLineDate = parseISO(deadline);
      const diff = differenceInDays(deadLineDate, now);
      setDaysLeft(diff);
    };
    calculateDays();
    const interval = setInterval(calculateDays, 1000 * 60 * 60); // update every hour
    return () => clearInterval(interval);
  }, [deadline]);

  if (daysLeft === null) {
    return <Badge className="w-24 animate-pulse" />;
  }

  let colorClass = "bg-primary/20 text-primary-foreground border-primary/50";
  let text = `${daysLeft + 1} days left`;

  if (daysLeft < 0) {
    colorClass = "bg-destructive/20 text-destructive-foreground border-destructive/50";
    text = "Closed";
  } else if (daysLeft <= 3) {
    colorClass = "bg-warning/20 text-warning-foreground border-warning/50";
    if (daysLeft === 0) {
        text = "Ends today";
    }
  }

  return <Badge className={cn("transition-colors", colorClass)}>{text}</Badge>
}
