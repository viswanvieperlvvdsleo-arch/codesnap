"use client";

import * as React from "react";
import { learnContent } from "@/lib/learn-content";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription, SheetTrigger } from "@/components/ui/sheet";
import { PanelLeft } from "lucide-react";
import { DayList } from "@/components/learn/DayList";
import { LearnContentPanel } from "@/components/learn/LearnContentPanel";
import type { LearnContent } from "@/lib/types";
import { useIsMobile } from "@/hooks/use-mobile";

type Category = "HTML" | "CSS" | "JavaScript";

export default function LearnPage() {
  const [activeDay, setActiveDay] = React.useState(1);
  const [completedDays, setCompletedDays] = React.useState<Set<number>>(
    new Set()
  );
  const [activeTab, setActiveTab] = React.useState<Category>("HTML");
  const [isSheetOpen, setSheetOpen] = React.useState(false);
  const isMobile = useIsMobile();

  React.useEffect(() => {
    // Load completion status from localStorage
    const savedProgress = localStorage.getItem("learnProgress");
    if (savedProgress) {
      setCompletedDays(new Set(JSON.parse(savedProgress)));
    }
  }, []);

  const saveProgress = (newCompletedDays: Set<number>) => {
    setCompletedDays(newCompletedDays);
    localStorage.setItem(
      "learnProgress",
      JSON.stringify(Array.from(newCompletedDays))
    );
  };

  const handleDaySelect = (day: number) => {
    setActiveDay(day);
    if(isMobile) {
      setSheetOpen(false);
    }
  };

  const handleToggleComplete = () => {
    const newCompletedDays = new Set(completedDays);
    if (completedDays.has(activeDay)) {
      newCompletedDays.delete(activeDay);
    } else {
      newCompletedDays.add(activeDay);
    }
    saveProgress(newCompletedDays);
  };

  const navigateDay = (direction: "next" | "prev") => {
    const currentContent = learnContent.find((item) => item.day === activeDay);
    const categoryContent = learnContent.filter(
      (item) => item.category === currentContent?.category
    );
    const currentIndex = categoryContent.findIndex(
      (item) => item.day === activeDay
    );

    if (direction === "next" && currentIndex < categoryContent.length - 1) {
      setActiveDay(categoryContent[currentIndex + 1].day);
    } else if (direction === "prev" && currentIndex > 0) {
      setActiveDay(categoryContent[currentIndex - 1].day);
    }
  };

  const getCategoryForDay = (day: number): Category => {
    if (day <= 20) return "HTML";
    if (day <= 40) return "CSS";
    return "JavaScript";
  };
  
  React.useEffect(() => {
    setActiveTab(getCategoryForDay(activeDay));
  }, [activeDay]);

  const handleTabChange = (value: string) => {
    const newTab = value as Category;
    setActiveTab(newTab);
    // Switch to the first day of the new tab's content
    if (newTab === "HTML") setActiveDay(1);
    else if (newTab === "CSS") setActiveDay(21);
    else if (newTab === "JavaScript") setActiveDay(41);
  };

  const currentContent = learnContent.find((item) => item.day === activeDay);

  const progress = (completedDays.size / learnContent.length) * 100;

  const renderDayList = (category: Category) => {
    const categoryContent = learnContent.filter(
      (item) => item.category === category
    );
    return (
      <DayList
        days={categoryContent}
        activeDay={activeDay}
        completedDays={completedDays}
        onDaySelect={handleDaySelect}
      />
    );
  };

  return (
    <div className="flex flex-col h-[calc(100vh-120px)] space-y-4">
      <div className="px-4 md:px-6">
        <h1 className="text-3xl font-bold font-headline">
          60-Day Web Development Roadmap
        </h1>
        <div className="mt-4 flex items-center gap-4">
          <Progress value={progress} className="flex-1" />
          <span className="text-sm font-medium text-muted-foreground">
            {Math.round(progress)}% Complete
          </span>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={handleTabChange} className="flex-1 flex flex-col min-h-0">
        <div className="px-4 md:px-6">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="HTML">HTML (Day 1-20)</TabsTrigger>
            <TabsTrigger value="CSS">CSS (Day 21-40)</TabsTrigger>
            <TabsTrigger value="JavaScript">JS (Day 41-60)</TabsTrigger>
          </TabsList>
        </div>

        <div className="flex flex-1 mt-4 overflow-hidden">
          {isMobile ? (
            <Sheet open={isSheetOpen} onOpenChange={setSheetOpen}>
              <div className="px-4 md:px-6 fixed bottom-4 right-4 z-40">
                <SheetTrigger asChild>
                  <Button size="icon">
                    <PanelLeft />
                  </Button>
                </SheetTrigger>
              </div>
              <SheetContent side="left" className="p-2 w-72">
                <SheetHeader>
                  <SheetTitle>{activeTab} Days</SheetTitle>
                  <SheetDescription className="sr-only">
                    Select a day to view its content.
                  </SheetDescription>
                </SheetHeader>
                <TabsContent value="HTML" forceMount className={activeTab !== 'HTML' ? 'hidden' : ''}>{renderDayList("HTML")}</TabsContent>
                <TabsContent value="CSS" forceMount className={activeTab !== 'CSS' ? 'hidden' : ''}>{renderDayList("CSS")}</TabsContent>
                <TabsContent value="JavaScript" forceMount className={activeTab !== 'JavaScript' ? 'hidden' : ''}>{renderDayList("JavaScript")}</TabsContent>
              </SheetContent>
            </Sheet>
          ) : (
            <aside className="w-64 border-r overflow-y-auto">
              <TabsContent value="HTML" className="m-0">{renderDayList("HTML")}</TabsContent>
              <TabsContent value="CSS" className="m-0">{renderDayList("CSS")}</TabsContent>
              <TabsContent value="JavaScript" className="m-0">{renderDayList("JavaScript")}</TabsContent>
            </aside>
          )}

          <main className="flex-1 overflow-y-auto p-4 md:p-6">
            {currentContent ? (
              <LearnContentPanel
                content={currentContent}
                isCompleted={completedDays.has(activeDay)}
                onToggleComplete={handleToggleComplete}
                onNavigate={navigateDay}
              />
            ) : (
              <div className="text-center text-muted-foreground">
                Select a day to start learning.
              </div>
            )}
          </main>
        </div>
      </Tabs>
    </div>
  );
}
