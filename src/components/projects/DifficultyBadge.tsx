"use client";

import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import type { Project } from "@/lib/types";

interface DifficultyBadgeProps {
  difficulty: Project["difficulty"];
}

export function DifficultyBadge({ difficulty }: DifficultyBadgeProps) {
  const badgeClass = cn({
    "bg-green-500/20 text-green-400 border-green-500/30": difficulty === "Beginner",
    "bg-yellow-500/20 text-yellow-400 border-yellow-500/30": difficulty === "Intermediate",
    "bg-red-500/20 text-red-400 border-red-500/30": difficulty === "Advanced",
  });

  return <Badge className={badgeClass}>{difficulty}</Badge>;
}
