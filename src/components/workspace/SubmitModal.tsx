
"use client"

import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogClose,
} from "@/components/ui/dialog"

interface SubmitModalProps {
  isOpen: boolean
  setIsOpen: (open: boolean) => void
  onConfirm: () => void
}

export function SubmitModal({ isOpen, setIsOpen, onConfirm }: SubmitModalProps) {
  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Confirm Submission</DialogTitle>
          <DialogDescription>
            Are you sure you want to submit your work? You won't be able to make
            changes after submission.
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <DialogClose asChild>
            <Button variant="outline">Cancel</Button>
          </DialogClose>
          <Button onClick={onConfirm}>Confirm & Submit</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
