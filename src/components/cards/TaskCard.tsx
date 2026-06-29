"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { formatDistanceToNow, parseISO } from "date-fns"
import { MoreHorizontal, Calendar, Code, User, Users, Book, Trash, Edit, Eye, Send, FileText } from "lucide-react"
import type { Task, User } from "@/lib/types"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Badge } from "@/components/ui/badge"
import { CountdownBadge } from "@/components/tasks/CountdownBadge"
import { ConfirmDialog } from "@/components/tasks/ConfirmDialog"
import { TaskDetailsModal } from "@/components/tasks/TaskDetailsModal"

interface TaskCardProps {
  task: Task
  user: User
  onEdit: (task: Task) => void
  onDelete: (taskId: string) => void
  onViewSubmissions: (task: Task) => void
}

export function TaskCard({ task, user, onEdit, onDelete, onViewSubmissions }: TaskCardProps) {
  const router = useRouter()
  const [isDetailsModalOpen, setDetailsModalOpen] = useState(false)
  const [isConfirmDeleteOpen, setConfirmDeleteOpen] = useState(false)

  const handleStartTask = () => {
    router.push(`/workspace?taskId=${task.id}`)
  }

  const isOwner = task.ownerId === user.id

  return (
    <>
      <Card className="flex flex-col hover:shadow-primary/20 hover:shadow-lg transition-shadow duration-300 transform hover:-translate-y-1">
        <CardHeader className="flex flex-row items-start justify-between pb-2">
          <div className="space-y-1 pr-4">
            <CardTitle>{task.title}</CardTitle>
            <CardDescription className="line-clamp-2 h-[40px]">{task.description}</CardDescription>
          </div>
          {user.role === "teacher" && isOwner && (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="h-8 w-8 flex-shrink-0">
                  <MoreHorizontal className="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuLabel>Actions</DropdownMenuLabel>
                <DropdownMenuItem onClick={() => onEdit(task)}>
                  <Edit className="mr-2 h-4 w-4" /> Edit
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => setConfirmDeleteOpen(true)} className="text-destructive focus:text-destructive focus:bg-destructive/10">
                  <Trash className="mr-2 h-4 w-4" /> Delete
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          )}
        </CardHeader>
        <CardContent className="flex-grow space-y-4">
          <div className="flex flex-wrap gap-2 text-xs">
              <Badge variant="secondary" className="flex items-center gap-1"><Book className="h-3 w-3"/>{task.course}</Badge>
              <Badge variant="secondary" className="flex items-center gap-1"><Code className="h-3 w-3"/>{task.branch}</Badge>
              <Badge variant="secondary" className="flex items-center gap-1"><Users className="h-3 w-3"/>Sec {task.section}</Badge>
              <Badge variant="secondary" className="flex items-center gap-1"><User className="h-3 w-3"/>Year {task.year}</Badge>
          </div>
          <div className="text-xs text-muted-foreground flex items-center justify-between">
            <div className="flex items-center gap-2">
                <Calendar className="h-4 w-4" />
                <span>Due: {new Date(task.deadline).toLocaleDateString()}</span>
            </div>
            <CountdownBadge deadline={task.deadline} />
          </div>
          {user.role === 'teacher' && (
            <div className="text-xs text-muted-foreground flex items-center justify-between pt-2 border-t border-border">
                <span>Created {formatDistanceToNow(parseISO(task.createdAt), { addSuffix: true })}</span>
                <span>{task.submissionCount} Submissions</span>
            </div>
          )}
        </CardContent>
        <CardFooter>
          {user.role === "student" ? (
            <div className="w-full flex justify-between items-center">
              <Button onClick={handleStartTask} disabled={new Date(task.deadline) < new Date()}>
                <Send className="mr-2" /> Start Task
              </Button>
               <Button variant="secondary" onClick={() => setDetailsModalOpen(true)}>
                 <Eye className="mr-2"/> View Details
               </Button>
            </div>
          ) : (
            <div className="w-full flex justify-between items-center">
                <Button variant="secondary" onClick={() => onEdit(task)}>
                    <Edit className="mr-2" /> Edit Task
                </Button>
                <Button onClick={() => onViewSubmissions(task)}>
                    <FileText className="mr-2" /> View Submissions
                </Button>
            </div>
          )}
        </CardFooter>
      </Card>
      
      {/* Student Details Modal */}
      <TaskDetailsModal isOpen={isDetailsModalOpen} setIsOpen={setDetailsModalOpen} task={task} />

      {/* Teacher Delete Confirmation */}
      <ConfirmDialog
        isOpen={isConfirmDeleteOpen}
        setIsOpen={setConfirmDeleteOpen}
        title="Delete Task"
        description="Are you sure you want to delete this task? This action cannot be undone."
        onConfirm={() => onDelete(task.id)}
      />
    </>
  )
}
