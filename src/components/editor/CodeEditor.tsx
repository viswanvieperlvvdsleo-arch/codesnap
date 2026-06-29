"use client";

import { useEffect, useRef } from 'react';
import Editor, { OnMount } from "@monaco-editor/react";
import { useTheme } from '@/contexts/theme-provider';

interface CodeEditorProps {
    value: string;
    onChange: (value: string | undefined) => void;
    language?: string;
}

export function CodeEditor({ value, onChange, language = 'html' }: CodeEditorProps) {
    const { theme } = useTheme();
    const editorRef = useRef<any>(null);

    const handleEditorDidMount: OnMount = (editor, monaco) => {
        editorRef.current = editor;
        
        // Set custom font for the editor
        monaco.editor.remeasureFonts();
        editor.updateOptions({
            fontFamily: "JetBrains Mono",
            fontSize: 14,
            minimap: { enabled: false },
        });
    }

    const currentTheme = theme === 'light' ? 'vs-light' : 'vs-dark';

    return (
        <div className="h-full w-full bg-[#1e1e1e]">
            <Editor
                height="100%"
                language={language}
                value={value}
                onChange={onChange}
                theme={currentTheme}
                onMount={handleEditorDidMount}
                options={{
                    wordWrap: 'on',
                    scrollBeyondLastLine: false,
                    automaticLayout: true,
                }}
            />
        </div>
    );
}
