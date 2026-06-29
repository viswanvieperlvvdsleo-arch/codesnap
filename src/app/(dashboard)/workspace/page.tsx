
"use client"

import { useState, useEffect, useRef } from "react"
import { useSearchParams } from "next/navigation"
import { CodeEditor } from "@/components/editor/CodeEditor"
import { Button } from "@/components/ui/button"
import { Undo, Redo, FileDown, Eye, Code, BookOpen, Send, FileUp, Upload, ExternalLink, Trash2 } from "lucide-react"
import { mockTasks, mockProjects } from "@/lib/mock-data"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { useAuth } from "@/contexts/auth-provider"
import { useToast } from "@/hooks/use-toast"
import { useIsMobile } from "@/hooks/use-mobile"
import type { Task, Project } from "@/lib/types"
import { cn } from "@/lib/utils"

import { SubmitModal } from "@/components/workspace/SubmitModal"
import { UploadToProjectModal } from "@/components/workspace/UploadToProjectModal"
import { TaskDetailsModal } from "@/components/tasks/TaskDetailsModal"

export default function WorkspacePage() {
  const searchParams = useSearchParams()
  const taskId = searchParams.get("taskId")
  const projectId = searchParams.get("projectId")
  const { user } = useAuth()
  const { toast } = useToast()
  const isMobile = useIsMobile()
  const fileInputRef = useRef<HTMLInputElement>(null)

  const [code, setCode] = useState("")
  const [task, setTask] = useState<Task | null>(null)
  const [project, setProject] = useState<Project | null>(null);

  const [activeView, setActiveView] = useState('editor');
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [logs, setLogs] = useState<{ type: 'log' | 'error' | 'warn', message: string, timestamp: string }[]>([])

  const [isSubmitModalOpen, setSubmitModalOpen] = useState(false)
  const [isUploadModalOpen, setUploadModalOpen] = useState(false)
  const [isTaskDetailsOpen, setTaskDetailsOpen] = useState(false)
  
  useEffect(() => {
    if (taskId) {
      const foundTask = mockTasks.find((t) => t.id === taskId)
      if (foundTask) {
        setTask(foundTask)
        setCode(foundTask.starterCode || "")
      }
    } else if (projectId) {
      const foundProject = mockProjects.find((p) => p.id === projectId);
      if (foundProject) {
        setProject(foundProject);
        const fullCode = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${foundProject.title}</title>
    <style>
        ${foundProject.cssTemplate}
    </style>
</head>
<body>
    ${foundProject.htmlTemplate}
    <script>
        ${foundProject.jsTemplate}
    </script>
</body>
</html>`;
        setCode(fullCode);
      }
    }
  }, [taskId, projectId])

  // Listen for messages from the iframe console
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (event.data && event.data.source === 'codesnap-preview') {
        setLogs(prev => [...prev, {
          type: event.data.type,
          message: event.data.message,
          timestamp: new Date().toLocaleTimeString()
        }].slice(-50)) // Keep last 50 logs
      }
    }

    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [])
  
  const handleDownload = () => {
    const blob = new Blob([code], { type: 'text/html' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'index.html';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    toast({ title: "Success", description: "Code downloaded as index.html" })
  };

  const handleFullPreview = () => {
    try {
        const blob = new Blob([code], { type: 'text/html' });
        const url = URL.createObjectURL(blob);
        const newWindow = window.open(url, '_blank', 'noopener,noreferrer');
        if(newWindow) {
          newWindow.document.title = "CodeSnap Preview";
          setTimeout(() => URL.revokeObjectURL(url), 1000);
        } else {
            toast({ variant: 'destructive', title: "Error", description: "Could not open preview. Please allow pop-ups."})
        }
    } catch(error) {
        console.error("Full preview error:", error);
        toast({ variant: 'destructive', title: "Error", description: "Failed to generate full preview."})
    }
  }

  const handleOpenFileClick = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file && file.type === 'text/html') {
      const reader = new FileReader();
      reader.onload = (e) => {
        const content = e.target?.result as string;
        setCode(content);
        setLogs([]);
        toast({ title: "Success", description: `${file.name} loaded into editor.`})
      };
      reader.readAsText(file);
    } else {
      toast({ variant: 'destructive', title: "Invalid File", description: "Please select an HTML file."})
    }
    if(fileInputRef.current) {
        fileInputRef.current.value = "";
    }
  };

  const handleSubmit = () => {
    setIsSubmitted(true);
    setSubmitModalOpen(false);
    toast({
        title: "Submission Successful!",
        description: "Your work has been submitted to your teacher.",
        className: "bg-success text-success-foreground"
    });
  }

  const handleUploadProject = ({title, description}: {title: string, description: string}) => {
    toast({
      title: "Project Uploaded!",
      description: `"${title}" has been added to the projects showcase.`,
      className: "bg-success text-success-foreground"
    })
  }

  const clearLogs = () => setLogs([]);

  // Inject console hook script into the code
  const getInjectedCode = () => {
    const hookScript = `
      <script>
        (function() {
          const originalLog = console.log;
          const originalError = console.error;
          const originalWarn = console.warn;

          const sendToParent = (type, args) => {
            window.parent.postMessage({
              source: 'codesnap-preview',
              type: type,
              message: args.map(arg => 
                typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
              ).join(' ')
            }, '*');
          };

          console.log = function(...args) {
            sendToParent('log', args);
            originalLog.apply(console, args);
          };
          console.error = function(...args) {
            sendToParent('error', args);
            originalError.apply(console, args);
          };
          console.warn = function(...args) {
            sendToParent('warn', args);
            originalWarn.apply(console, args);
          };

          window.onerror = function(message, source, lineno, colno, error) {
            sendToParent('error', [\`Error: \${message} at line \${lineno}:\${colno}\`]);
          };
        })();
      </script>
    `;
    
    // Insert hook script right after <body> or at the beginning
    if (code.includes('<body>')) {
      return code.replace('<body>', '<body>' + hookScript);
    }
    return hookScript + code;
  }

  return (
    <div className="flex flex-col h-[calc(100vh-65px)] bg-card text-foreground">
      <header className="flex h-14 items-center gap-2 border-b px-4 shrink-0">
        <div className="flex-1">
             <div className="flex items-center gap-2 md:hidden">
                <Button variant={activeView === 'editor' ? 'secondary' : 'ghost'} size="sm" onClick={() => setActiveView('editor')}>
                    <Code className="h-4 w-4 md:mr-2" /> <span className="hidden md:inline">Editor</span>
                </Button>
                 <Button variant={activeView === 'preview' ? 'secondary' : 'ghost'} size="sm" onClick={() => setActiveView('preview')}>
                    <Eye className="h-4 w-4 md:mr-2" /> <span className="hidden md:inline">Preview</span>
                </Button>
            </div>
        </div>
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar py-1">
            <Button variant="ghost" size="icon" title="Undo"><Undo className="h-4 w-4" /></Button>
            <Button variant="ghost" size="icon" title="Redo"><Redo className="h-4 w-4" /></Button>
            <input type="file" ref={fileInputRef} onChange={handleFileChange} accept=".html" className="hidden" />
            <Button variant="outline" size="sm" onClick={handleOpenFileClick}>
                <FileUp className="md:mr-2 h-4 w-4" /> <span className="hidden md:inline">Open</span>
            </Button>
            <Button variant="outline" size="sm" onClick={handleDownload}>
                <FileDown className="md:mr-2 h-4 w-4" /> <span className="hidden md:inline">Download</span>
            </Button>
            {task && <Button variant="outline" size="sm" onClick={() => setTaskDetailsOpen(true)}><BookOpen className="md:mr-2 h-4 w-4" /> <span className="hidden md:inline">View Task</span></Button>}
            <Button variant="outline" size="sm" onClick={handleFullPreview}>
                <ExternalLink className="md:mr-2 h-4 w-4" /> <span className="hidden md:inline">Full Preview</span>
            </Button>
            <Button variant="outline" size="sm" onClick={() => setUploadModalOpen(true)}>
                <Upload className="md:mr-2 h-4 w-4" /> <span className="hidden md:inline">Upload</span>
            </Button>
            {user?.role === 'student' && task && (
                 <Button onClick={() => setSubmitModalOpen(true)} disabled={isSubmitted}>
                    <Send className="md:mr-2 h-4 w-4" /> <span>{isSubmitted ? "Submitted" : "Submit"}</span>
                </Button>
            )}
        </div>
      </header>

      <div className="flex-1 flex overflow-hidden">
        <div className={cn("hidden md:flex flex-1 w-1/2 border-r", isMobile ? "hidden" : "flex")}>
          <CodeEditor value={code} onChange={(c) => {
            setCode(c || "");
            // Optional: reset logs on code change if desired, or keep them
          }} />
        </div>
        <div className={cn("hidden md:flex flex-1 w-1/2 flex-col", isMobile ? "hidden" : "flex")}>
            <div className="flex-1">
                <iframe
                    srcDoc={getInjectedCode()}
                    title="Live Preview"
                    sandbox="allow-scripts allow-modals"
                    className="w-full h-full border-0 bg-white"
                />
            </div>
             <div className="h-64 border-t flex flex-col">
                <Tabs defaultValue="console" className="flex-1 flex flex-col min-h-0">
                    <div className="flex items-center justify-between border-b bg-muted/50 px-2 shrink-0">
                        <TabsList className="h-9 rounded-none bg-transparent">
                            <TabsTrigger value="console" className="rounded-none data-[state=active]:bg-background">Console</TabsTrigger>
                            <TabsTrigger value="errors" className="rounded-none data-[state=active]:bg-background">Errors</TabsTrigger>
                        </TabsList>
                        <Button variant="ghost" size="icon" className="h-7 w-7" onClick={clearLogs} title="Clear Console">
                            <Trash2 className="h-3.5 w-3.5" />
                        </Button>
                    </div>
                    <TabsContent value="console" className="flex-1 m-0 p-0 bg-background overflow-hidden flex flex-col">
                        <div className="flex-1 overflow-y-auto p-2 font-code text-xs space-y-1">
                            {logs.length === 0 ? (
                                <p className="text-muted-foreground italic">&gt; Console output will appear here...</p>
                            ) : (
                                logs.map((log, i) => (
                                    <div key={i} className={cn(
                                        "flex gap-2 py-0.5 border-b border-border/30 last:border-0",
                                        log.type === 'error' ? 'text-destructive' : log.type === 'warn' ? 'text-warning' : 'text-foreground'
                                    )}>
                                        <span className="text-muted-foreground shrink-0">[{log.timestamp}]</span>
                                        <span className="shrink-0">{log.type === 'error' ? '✖' : log.type === 'warn' ? '⚠' : '>'}</span>
                                        <span className="break-all whitespace-pre-wrap">{log.message}</span>
                                    </div>
                                ))
                            )}
                        </div>
                    </TabsContent>
                    <TabsContent value="errors" className="flex-1 m-0 p-2 bg-background font-code text-xs text-destructive overflow-auto">
                        {logs.filter(l => l.type === 'error').length === 0 ? (
                            <p className="text-muted-foreground">No errors detected.</p>
                        ) : (
                            logs.filter(l => l.type === 'error').map((log, i) => (
                                <div key={i} className="py-1 border-b border-border/30 last:border-0">
                                    <span className="font-bold mr-2">[{log.timestamp}]</span>
                                    {log.message}
                                </div>
                            ))
                        )}
                    </TabsContent>
                </Tabs>
            </div>
        </div>
        
        {/* Mobile View */}
        {isMobile && (
            <div className="w-full h-full flex flex-col">
                <div className="flex-1 relative">
                    {activeView === 'editor' ? (
                        <CodeEditor value={code} onChange={(c) => setCode(c || "")} />
                    ) : (
                        <iframe
                            srcDoc={getInjectedCode()}
                            title="Live Preview"
                            sandbox="allow-scripts allow-modals"
                            className="w-full h-full border-0 bg-white"
                        />
                    )}
                </div>
                {/* Minimal mobile console log indicator */}
                {activeView === 'preview' && logs.length > 0 && (
                    <div className="absolute bottom-0 left-0 right-0 max-h-24 bg-black/80 text-white text-[10px] p-1 overflow-y-auto pointer-events-none">
                        {logs.slice(-3).map((l, i) => (
                            <div key={i} className={l.type === 'error' ? 'text-red-400' : 'text-gray-300'}>
                                {l.message}
                            </div>
                        ))}
                    </div>
                )}
            </div>
        )}

      </div>
      
      {/* Modals */}
      <SubmitModal isOpen={isSubmitModalOpen} setIsOpen={setSubmitModalOpen} onConfirm={handleSubmit} />
      <UploadToProjectModal isOpen={isUploadModalOpen} setIsOpen={setUploadModalOpen} onConfirm={handleUploadProject} />
      {task && <TaskDetailsModal isOpen={isTaskDetailsOpen} setIsOpen={setTaskDetailsOpen} task={task} />}
    </div>
  )
}
