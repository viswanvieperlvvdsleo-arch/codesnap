"use client"

import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from "@/components/ui/sheet"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import type { Task, Submission } from "@/lib/types"
import { Check, X, Code, Clock } from "lucide-react"
import { useToast } from "@/hooks/use-toast"
import { formatDistanceToNow, parseISO } from "date-fns"

interface SubmissionsDrawerProps {
  isOpen: boolean;
  setIsOpen: (open: boolean) => void;
  task: Task | null;
  submissions: Submission[];
}

export function SubmissionsDrawer({ isOpen, setIsOpen, task, submissions }: SubmissionsDrawerProps) {
    const { toast } = useToast()

    const handleApprove = (submissionId: string) => {
        toast({ title: "Approved!", description: `Submission ${submissionId} marked as approved.`, className: "bg-success text-success-foreground" })
    }

    const handleReject = (submissionId: string) => {
        toast({ title: "Rejected", description: `Submission ${submissionId} marked as rejected.`, variant: "destructive" })
    }

    return (
        <Sheet open={isOpen} onOpenChange={setIsOpen}>
            <SheetContent className="w-full sm:max-w-lg p-0 flex flex-col">
                <SheetHeader className="p-6 border-b">
                    <SheetTitle className="text-2xl">Submissions for "{task?.title}"</SheetTitle>
                    <SheetDescription>{submissions.length} submissions received so far.</SheetDescription>
                </SheetHeader>
                <div className="flex-1 overflow-y-auto p-6 space-y-4">
                    {submissions.length > 0 ? submissions.map(sub => (
                        <Card key={sub.id} className="bg-card/50">
                            <CardHeader>
                                <div className="flex justify-between items-center">
                                    <CardTitle className="text-lg">{sub.studentName}</CardTitle>
                                    <Badge variant={
                                        sub.status === 'approved' ? 'default' 
                                        : sub.status === 'rejected' ? 'destructive' 
                                        : 'secondary'
                                    } className={sub.status === 'approved' ? 'bg-success hover:bg-success/90' : ''}>
                                        {sub.status}
                                    </Badge>
                                </div>
                            </CardHeader>
                            <CardContent className="text-sm text-muted-foreground space-y-2">
                                <div className="flex items-center gap-2"><Clock className="h-4 w-4" /> Submitted {formatDistanceToNow(parseISO(sub.submittedAt), { addSuffix: true })}</div>
                                <div className="flex items-center gap-2"><Code className="h-4 w-4" /> Version: {sub.versionCount}</div>
                            </CardContent>
                            <CardFooter className="gap-2">
                                <Button size="sm" className="flex-1">View Code</Button>
                                <Button size="sm" variant="outline" className="flex-1 bg-success/20 border-success text-success-foreground hover:bg-success/30 hover:text-success-foreground" onClick={() => handleApprove(sub.id)}><Check className="mr-2 h-4 w-4" /> Approve</Button>
                                <Button size="sm" variant="outline" className="flex-1 bg-destructive/20 border-destructive text-destructive-foreground hover:bg-destructive/30 hover:text-destructive-foreground" onClick={() => handleReject(sub.id)}><X className="mr-2 h-4 w-4" /> Reject</Button>
                            </CardFooter>
                        </Card>
                    )) : (
                        <div className="text-center text-muted-foreground pt-16">
                            <p>No submissions for this task yet.</p>
                        </div>
                    )}
                </div>
            </SheetContent>
        </Sheet>
    )
}
