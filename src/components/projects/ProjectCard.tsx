"use client";

import Image from "next/image";
import { useRouter } from "next/navigation";
import { Code, Eye, FileText, Clock } from "lucide-react";
import type { Project } from "@/lib/types";
import { cn } from "@/lib/utils";

import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { DifficultyBadge } from "./DifficultyBadge";

interface ProjectCardProps {
  project: Project;
  onPreview: (project: Project) => void;
  onDetails: (project: Project) => void;
}

export function ProjectCard({ project, onPreview, onDetails }: ProjectCardProps) {
  const router = useRouter();

  const handleOpenWorkspace = () => {
    router.push(`/workspace?projectId=${project.id}`);
  };

  const techStackColors: Record<string, string> = {
    HTML: "bg-orange-500/20 text-orange-400 border-orange-500/30",
    CSS: "bg-blue-500/20 text-blue-400 border-blue-500/30",
    JS: "bg-yellow-500/20 text-yellow-400 border-yellow-500/30",
  };

  return (
    <Card className="flex flex-col group overflow-hidden transition-all duration-300 hover:shadow-primary/20 hover:shadow-lg hover:-translate-y-1 hover:border-primary/30">
      <CardHeader className="p-0">
        <div className="relative h-48 w-full">
          <Image
            src={project.thumbnailUrl}
            alt={project.title}
            fill
            className="object-cover transition-transform duration-300 group-hover:scale-105"
          />
           <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
           <div className="absolute bottom-4 left-4">
              <DifficultyBadge difficulty={project.difficulty} />
           </div>
        </div>
      </CardHeader>
      <CardContent className="p-4 flex-grow">
        <CardTitle className="text-xl mb-2">{project.title}</CardTitle>
        <CardDescription className="text-sm line-clamp-2 h-[40px]">
          {project.description}
        </CardDescription>
        <div className="flex flex-wrap gap-2 mt-4 text-xs">
          {project.techStack.map((tech) => (
            <Badge key={tech} variant="secondary" className={cn(techStackColors[tech])}>{tech}</Badge>
          ))}
        </div>
      </CardContent>
      <CardFooter className="p-4 pt-0 flex flex-col items-start gap-4">
         <div className="w-full text-xs text-muted-foreground flex items-center justify-between">
            <span className="flex items-center gap-1.5"><Clock className="h-3 w-3" /> {project.estimatedTime}</span>
            <span className="flex items-center gap-1.5"><Code className="h-3 w-3" /> {project.category}</span>
        </div>
        <div className="w-full grid grid-cols-3 gap-2">
            <Button size="sm" variant="outline" onClick={() => onPreview(project)}>
                <Eye className="mr-2 h-4 w-4" /> Preview
            </Button>
            <Button size="sm" variant="outline" onClick={handleOpenWorkspace}>
                <Code className="mr-2 h-4 w-4" /> Workspace
            </Button>
             <Button size="sm" variant="outline" onClick={() => onDetails(project)}>
                <FileText className="mr-2 h-4 w-4" /> Details
            </Button>
        </div>
      </CardFooter>
    </Card>
  );
}
