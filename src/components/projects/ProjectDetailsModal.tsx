"use client";

import { Folder, CheckCircle, Clock } from "lucide-react";
import type { Project } from "@/lib/types";

import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { DifficultyBadge } from "./DifficultyBadge";

interface ProjectDetailsModalProps {
  isOpen: boolean;
  setIsOpen: (open: boolean) => void;
  project: Project;
}

export function ProjectDetailsModal({ isOpen, setIsOpen, project }: ProjectDetailsModalProps) {
  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogContent className="max-w-2xl h-full md:h-auto flex flex-col">
        <DialogHeader>
          <DialogTitle className="text-2xl font-bold">{project.title}</DialogTitle>
           <DialogDescription className="flex flex-wrap items-center gap-4 pt-2">
             <DifficultyBadge difficulty={project.difficulty} />
             <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Clock className="h-4 w-4" />
                <span>Est. Time: {project.estimatedTime}</span>
             </div>
           </DialogDescription>
        </DialogHeader>
        <div className="flex-grow space-y-6 overflow-y-auto pr-2 text-sm">
          <div>
            <h3 className="font-semibold mb-2 text-base">Project Overview</h3>
            <p className="text-muted-foreground">{project.description}</p>
          </div>
           <div>
            <h3 className="font-semibold mb-3 text-base">Key Features</h3>
            <ul className="space-y-2">
              {project.features.map((feature, index) => (
                <li key={index} className="flex items-start gap-2">
                  <CheckCircle className="h-4 w-4 mt-0.5 text-success flex-shrink-0" />
                  <span className="text-muted-foreground">{feature}</span>
                </li>
              ))}
            </ul>
          </div>
           <div>
            <h3 className="font-semibold mb-3 text-base">Folder Structure</h3>
            <div className="p-3 bg-muted/50 rounded-md font-code text-xs">
                <div className="flex items-center gap-2"><Folder className="h-3 w-3"/> project/</div>
                <div className="pl-4 border-l border-muted ml-2">
                    <div className="flex items-center gap-2"> └─ index.html</div>
                    <div className="flex items-center gap-2"> └─ style.css</div>
                    <div className="flex items-center gap-2"> └─ script.js</div>
                </div>
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => setIsOpen(false)}>
            Close
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
