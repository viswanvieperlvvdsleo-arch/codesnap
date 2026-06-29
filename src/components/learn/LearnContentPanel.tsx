"use client";

import type { LearnContent } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { CodeBlock } from "./CodeBlock";
import { Check, ArrowLeft, ArrowRight, BookOpen, Code, Target } from "lucide-react";

interface LearnContentPanelProps {
  content: LearnContent;
  isCompleted: boolean;
  onToggleComplete: () => void;
  onNavigate: (direction: "next" | "prev") => void;
}

export function LearnContentPanel({
  content,
  isCompleted,
  onToggleComplete,
  onNavigate,
}: LearnContentPanelProps) {
  const getLanguage = (category: string) => {
    if (category === "JavaScript") return "javascript";
    if (category === "CSS") return "css";
    return "html";
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-sm font-semibold uppercase tracking-wider text-primary">
          Day {content.day} &bull; {content.category}
        </h2>
        <h1 className="text-4xl font-bold font-headline mt-1">{content.title}</h1>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2"><BookOpen className="h-5 w-5"/> Theory</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-muted-foreground leading-relaxed">{content.theory}</p>
        </CardContent>
      </Card>
      
      <Card>
        <CardHeader>
            <CardTitle className="flex items-center gap-2"><Code className="h-5 w-5"/> Code Example</CardTitle>
        </CardHeader>
        <CardContent>
            <CodeBlock code={content.codeExample} language={getLanguage(content.category)} />
        </CardContent>
      </Card>
      
      <Card>
        <CardHeader>
            <CardTitle className="flex items-center gap-2"><Target className="h-5 w-5"/> Your Task</CardTitle>
        </CardHeader>
        <CardContent>
            <p className="text-muted-foreground">{content.task}</p>
        </CardContent>
      </Card>

      <div className="flex flex-col sm:flex-row justify-between items-center gap-4 mt-8">
        <Button variant="outline" onClick={() => onNavigate("prev")}>
          <ArrowLeft className="mr-2 h-4 w-4" /> Previous Day
        </Button>
        <Button
          onClick={onToggleComplete}
          variant={isCompleted ? "secondary" : "default"}
          className="w-full sm:w-auto"
        >
          <Check className="mr-2 h-4 w-4" />
          {isCompleted ? "Mark as Incomplete" : "Mark as Completed"}
        </Button>
        <Button variant="outline" onClick={() => onNavigate("next")}>
          Next Day <ArrowRight className="ml-2 h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}
