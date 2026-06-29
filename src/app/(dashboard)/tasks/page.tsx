"use client"

import * as React from "react"
import { useAuth } from "@/contexts/auth-provider"
import { mockTasks, mockAcademicOptions, mockSubmissions } from "@/lib/mock-data"
import type { Task, AcademicOptions } from "@/lib/types"
import { TaskCard } from "@/components/cards/TaskCard"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { FolderSearch, PlusCircle, Settings, Search } from "lucide-react"
import { ImportTaskModal } from "@/components/tasks/ImportTaskModal"
import { ManageAcademicOptionsModal } from "@/components/tasks/ManageAcademicOptionsModal"
import { SubmissionsDrawer } from "@/components/tasks/SubmissionsDrawer"
import { useToast } from "@/hooks/use-toast"

export default function TasksPage() {
  const { user } = useAuth()
  const { toast } = useToast()
  
  // State management
  const [tasks, setTasks] = React.useState<Task[]>(mockTasks)
  const [academicOptions, setAcademicOptions] = React.useState<AcademicOptions>(mockAcademicOptions)
  const [filteredTasks, setFilteredTasks] = React.useState<Task[]>(tasks)
  const [searchTerm, setSearchTerm] = React.useState("")
  const [filters, setFilters] = React.useState({ course: 'all', branch: 'all', section: 'all', year: 'all' })

  // Modal and Drawer states
  const [isImportModalOpen, setImportModalOpen] = React.useState(false)
  const [isManageModalOpen, setManageModalOpen] = React.useState(false)
  const [isSubmissionsDrawerOpen, setSubmissionsDrawerOpen] = React.useState(false)
  const [editingTask, setEditingTask] = React.useState<Task | null>(null)
  const [viewingSubmissionsTask, setViewingSubmissionsTask] = React.useState<Task | null>(null)

  // Filter and Search Logic
  React.useEffect(() => {
    let result = user?.role === 'teacher'
      ? tasks
      : tasks.filter(task => task.section === user?.section)

    if (searchTerm) {
      result = result.filter(task => task.title.toLowerCase().includes(searchTerm.toLowerCase()))
    }
    
    (Object.keys(filters) as Array<keyof typeof filters>).forEach(key => {
        if (filters[key] !== 'all') {
            result = result.filter(task => task[key] === filters[key]);
        }
    });

    setFilteredTasks(result)
  }, [tasks, searchTerm, filters, user])

  // Handlers
  const handleFilterChange = (filterType: keyof typeof filters) => (value: string) => {
    setFilters(prev => ({ ...prev, [filterType]: value }))
  }
  
  const handleOpenEditModal = (task: Task) => {
    setEditingTask(task)
    setImportModalOpen(true)
  }

  const handleOpenSubmissions = (task: Task) => {
    setViewingSubmissionsTask(task);
    setSubmissionsDrawerOpen(true);
  }

  const handleTaskSave = (taskData: Omit<Task, 'id' | 'createdAt' | 'ownerId' | 'submissionCount'>) => {
    if (editingTask) {
       // Edit existing task
      setTasks(currentTasks => currentTasks.map(t => t.id === editingTask.id ? { ...editingTask, ...taskData } : t));
      toast({ title: "Success", description: "Task updated successfully." });
    } else {
      // Add new task
      const newTask: Task = {
        ...taskData,
        id: `task-${Date.now()}`,
        createdAt: new Date().toISOString(),
        ownerId: user!.id,
        submissionCount: 0,
      };
      setTasks(currentTasks => [newTask, ...currentTasks]);
      toast({ title: "Success", description: "Task created successfully." });
    }
    setEditingTask(null);
    return true; // Indicate success
  };

  const handleDeleteTask = (taskId: string) => {
    setTasks(currentTasks => currentTasks.filter(t => t.id !== taskId));
    toast({ variant: 'destructive', title: "Deleted", description: "Task has been deleted." });
  }

  if (!user) return null

  const FilterSelect = ({ label, value, onValueChange, options }: { label: string, value: string, onValueChange: (value: string) => void, options: string[] }) => (
    <Select value={value} onValueChange={onValueChange}>
      <SelectTrigger className="w-full sm:w-[150px] bg-card">
        <SelectValue placeholder={label} />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value="all">All {label}s</SelectItem>
        {options.map(opt => <SelectItem key={opt} value={opt}>{opt}</SelectItem>)}
      </SelectContent>
    </Select>
  );

  return (
    <div className="container mx-auto p-4 md:p-6 space-y-6">
      {/* Top Action Bar */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
        <h1 className="text-2xl md:text-3xl font-bold font-headline">
          {user.role === 'teacher' ? "Task Dashboard" : "Your Tasks"}
        </h1>
        {user.role === 'teacher' && (
          <div className="flex gap-2">
             <Button onClick={() => { setEditingTask(null); setImportModalOpen(true); }}>
              <PlusCircle className="mr-2 h-4 w-4" /> Import Task
            </Button>
            <Button variant="secondary" onClick={() => setManageModalOpen(true)}>
              <Settings className="mr-2 h-4 w-4" /> Manage Options
            </Button>
          </div>
        )}
      </div>

      {/* Filters and Search */}
      <div className="flex flex-col md:flex-row gap-2">
          <div className="relative flex-1">
             <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
             <Input 
                placeholder="Search by task title..."
                className="pl-9 bg-card"
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
             />
          </div>
          <div className="flex flex-wrap gap-2">
            <FilterSelect label="Course" value={filters.course} onValueChange={handleFilterChange('course')} options={academicOptions.courses} />
            <FilterSelect label="Branch" value={filters.branch} onValueChange={handleFilterChange('branch')} options={academicOptions.branches} />
            <FilterSelect label="Section" value={filters.section} onValueChange={handleFilterChange('section')} options={academicOptions.sections} />
            <FilterSelect label="Year" value={filters.year} onValueChange={handleFilterChange('year')} options={academicOptions.years} />
          </div>
      </div>

      {/* Task Cards Grid */}
      {filteredTasks.length > 0 ? (
        <div className="grid gap-4 md:gap-6 md:grid-cols-2 xl:grid-cols-3">
          {filteredTasks.map((task) => (
            <TaskCard 
              key={task.id} 
              task={task} 
              user={user} 
              onEdit={handleOpenEditModal}
              onDelete={handleDeleteTask}
              onViewSubmissions={handleOpenSubmissions}
            />
          ))}
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center text-center py-16 text-muted-foreground rounded-lg border-2 border-dashed">
            <FolderSearch className="h-16 w-16 mb-4" />
            <h2 className="text-xl font-semibold">No Tasks Available</h2>
            <p>
                {searchTerm || Object.values(filters).some(f => f !== 'all') 
                ? "Try adjusting your search or filters." 
                : "Check back later for new assignments."}
            </p>
        </div>
      )}

      {/* Modals and Drawers */}
      {user.role === 'teacher' && (
        <>
          <ImportTaskModal
            isOpen={isImportModalOpen}
            setIsOpen={setImportModalOpen}
            onSave={handleTaskSave}
            task={editingTask}
            academicOptions={academicOptions}
          />
          <ManageAcademicOptionsModal
            isOpen={isManageModalOpen}
            setIsOpen={setManageModalOpen}
            options={academicOptions}
            setOptions={setAcademicOptions}
          />
          <SubmissionsDrawer
            isOpen={isSubmissionsDrawerOpen}
            setIsOpen={setSubmissionsDrawerOpen}
            task={viewingSubmissionsTask}
            submissions={mockSubmissions.filter(s => s.taskId === viewingSubmissionsTask?.id)}
          />
        </>
      )}
    </div>
  )
}
