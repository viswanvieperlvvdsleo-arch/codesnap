"use client";

import { ExternalLink, Maximize } from "lucide-react";
import type { Project } from "@/lib/types";

import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";
import { useToast } from "@/hooks/use-toast";

interface ProjectPreviewModalProps {
  isOpen: boolean;
  setIsOpen: (open: boolean) => void;
  project: Project;
}

export function ProjectPreviewModal({ isOpen, setIsOpen, project }: ProjectPreviewModalProps) {
  const { toast } = useToast();
  const fullCode = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${project.title}</title>
    <style>
        body { margin: 0; }
        ${project.cssTemplate}
    </style>
</head>
<body>
    ${project.htmlTemplate}
    <script>
        ${project.jsTemplate}
    </script>
</body>
</html>`;

  const handleFullPreview = () => {
    try {
      const blob = new Blob([fullCode], { type: "text/html" });
      const url = URL.createObjectURL(blob);
      const newWindow = window.open(url, "_blank", "noopener,noreferrer");
      if (newWindow) {
        newWindow.document.title = `${project.title} - CodeSnap Preview`;
        setTimeout(() => URL.revokeObjectURL(url), 1000);
      } else {
        toast({
          variant: "destructive",
          title: "Error",
          description: "Could not open preview. Please allow pop-ups.",
        });
      }
    } catch (error) {
      console.error("Full preview error:", error);
      toast({
        variant: "destructive",
        title: "Error",
        description: "Failed to generate full preview.",
      });
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogContent className="max-w-5xl w-[90vw] h-[90vh] flex flex-col p-0">
        <DialogHeader className="p-4 border-b flex-row items-center justify-between">
          <div className="space-y-1">
             <DialogTitle className="text-lg">{project.title} - Live Preview</DialogTitle>
             <DialogDescription className="text-xs">This is a live demo of the project.</DialogDescription>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" onClick={handleFullPreview}>
                <ExternalLink className="h-4 w-4 mr-2" />
                Open in New Tab
            </Button>
          </div>
        </DialogHeader>
        <div className="flex-1 bg-white">
          <iframe
            srcDoc={fullCode}
            title={`${project.title} Live Preview`}
            sandbox="allow-scripts allow-modals"
            className="w-full h-full border-0"
          />
        </div>
      </DialogContent>
    </Dialog>
  );
}
