"use client";

import { useState } from "react";
import { useTheme } from "next-themes";
import { CodeEditor } from "@/components/editor/CodeEditor";
import { Button } from "@/components/ui/button";
import { Check, Clipboard } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

interface CodeBlockProps {
  code: string;
  language?: string;
}

export function CodeBlock({ code, language = "html" }: CodeBlockProps) {
  const [isCopied, setIsCopied] = useState(false);
  const { toast } = useToast();

  const handleCopy = () => {
    navigator.clipboard.writeText(code).then(() => {
      setIsCopied(true);
      toast({ title: "Copied!", description: "Code has been copied to your clipboard." });
      setTimeout(() => setIsCopied(false), 2000);
    });
  };

  return (
    <div className="relative rounded-md border bg-card overflow-hidden my-4">
      <div className="h-64">
        <CodeEditor
          value={code}
          onChange={() => {}} // Read-only
          language={language}
        />
      </div>
      <Button
        size="icon"
        variant="ghost"
        className="absolute top-2 right-2 h-8 w-8"
        onClick={handleCopy}
      >
        {isCopied ? <Check className="h-4 w-4 text-success" /> : <Clipboard className="h-4 w-4" />}
      </Button>
    </div>
  );
}
