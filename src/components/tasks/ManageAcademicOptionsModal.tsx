"use client"

import * as React from "react"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Trash } from "lucide-react"
import type { AcademicOptions } from "@/lib/types"

interface ManageAcademicOptionsModalProps {
    isOpen: boolean;
    setIsOpen: (open: boolean) => void;
    options: AcademicOptions;
    setOptions: (options: AcademicOptions) => void;
}

export function ManageAcademicOptionsModal({ isOpen, setIsOpen, options, setOptions }: ManageAcademicOptionsModalProps) {
    type OptionKey = keyof AcademicOptions;
    const [newItem, setNewItem] = React.useState({ courses: '', branches: '', sections: '', years: '' });

    const addItem = (type: OptionKey) => {
        const value = newItem[type].trim();
        if (value === '' || options[type].includes(value)) return;
        
        const newOptions = { ...options, [type]: [...options[type], value] };
        setOptions(newOptions);
        setNewItem({ ...newItem, [type]: '' });
    }
    
    const deleteItem = (type: OptionKey, item: string) => {
        const newOptions = { ...options, [type]: options[type].filter(i => i !== item) };
        setOptions(newOptions);
    }
    
    const renderTab = (type: OptionKey, title: string) => (
        <TabsContent value={type} className="space-y-4">
             <div className="max-h-48 overflow-y-auto space-y-2 pr-2">
                {options[type].map((item) => (
                    <div key={item} className="flex items-center justify-between bg-muted p-2 rounded-md">
                        <span className="text-sm">{item}</span>
                        <Button variant="ghost" size="icon" className="h-6 w-6" onClick={() => deleteItem(type, item)}>
                            <Trash className="h-4 w-4 text-destructive"/>
                        </Button>
                    </div>
                ))}
            </div>
            <div className="flex gap-2">
                <Input 
                    placeholder={`New ${title}...`} 
                    value={newItem[type]}
                    onChange={(e) => setNewItem({ ...newItem, [type]: e.target.value })}
                    onKeyDown={(e) => e.key === 'Enter' && addItem(type)}
                />
                <Button onClick={() => addItem(type)}>Add</Button>
            </div>
        </TabsContent>
    );

    return (
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
            <DialogContent className="sm:max-w-md w-full">
                <DialogHeader>
                    <DialogTitle>Manage Academic Options</DialogTitle>
                    <DialogDescription>Add, edit, or remove academic details.</DialogDescription>
                </DialogHeader>
                <Tabs defaultValue="courses" className="w-full">
                    <TabsList className="grid w-full grid-cols-4">
                        <TabsTrigger value="courses">Courses</TabsTrigger>
                        <TabsTrigger value="branches">Branches</TabsTrigger>
                        <TabsTrigger value="sections">Sections</TabsTrigger>
                        <TabsTrigger value="years">Years</TabsTrigger>
                    </TabsList>
                    {renderTab('courses', 'Course')}
                    {renderTab('branches', 'Branch')}
                    {renderTab('sections', 'Section')}
                    {renderTab('years', 'Year')}
                </Tabs>
            </DialogContent>
        </Dialog>
    )
}
