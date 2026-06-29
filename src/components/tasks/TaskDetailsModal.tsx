"use client"

import { Task } from "@/lib/types"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog"
import { CodeEditor } from "@/components/editor/CodeEditor"
import { Badge } from "../ui/badge"
import { Calendar } from "lucide-react"

interface TaskDetailsModalProps {
  isOpen: boolean
  setIsOpen: (open: boolean) => void
  task: Task
}

export function TaskDetailsModal({ isOpen, setIsOpen, task }: TaskDetailsModalProps) {
  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogContent className="max-w-3xl h-full md:h-auto flex flex-col">
        <DialogHeader>
          <DialogTitle className="text-2xl">{task.title}</DialogTitle>
          <DialogDescription className="flex items-center gap-2 pt-2">
            <Calendar className="h-4 w-4" />
            <span className="font-medium">Deadline:</span> {new Date(task.deadline).toLocaleString()}
          </DialogDescription>
        </DialogHeader>
        <div className="flex-grow space-y-4 overflow-y-auto pr-2">
            <p className="text-muted-foreground">{task.description}</p>
            {task.starterCode && (
                <div>
                    <h3 className="font-semibold mb-2">Starter Code</h3>
                    <div className="h-64 rounded-md border overflow-hidden">
                        <CodeEditor value={task.starterCode} onChange={() => {}} />
                    </div>
                </div>
            )}
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => setIsOpen(false)}>Close</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
