"use client"

import Link from "next/link"
import { usePathname } from "next/navigation"
import {
  BookOpen,
  ClipboardList,
  CodeXml,
  FolderKanban,
  LayoutGrid,
  Bell,
} from "lucide-react"

import { cn } from "@/lib/utils"
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip"

const navItems = [
  { href: "/tasks", icon: ClipboardList, label: "Tasks" },
  { href: "/learn", icon: BookOpen, label: "Learn" },
  { href: "/projects", icon: FolderKanban, label: "Projects" },
  { href: "/workspace", icon: CodeXml, label: "Workspace" },
]

export function SidebarNav() {
  const pathname = usePathname()

  return (
    <nav className="flex flex-col items-center gap-4 px-2 sm:py-5">
      <Tooltip>
        <TooltipTrigger asChild>
          <Link
            href="#"
            className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary text-primary-foreground transition-colors md:h-8 md:w-8"
          >
            <CodeXml className="h-5 w-5" />
            <span className="sr-only">CodeSnap</span>
          </Link>
        </TooltipTrigger>
        <TooltipContent side="right">CodeSnap</TooltipContent>
      </Tooltip>
      {navItems.map((item) => (
        <Tooltip key={item.href}>
          <TooltipTrigger asChild>
            <Link
              href={item.href}
              className={cn(
                "flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8",
                pathname.startsWith(item.href) && "bg-accent text-accent-foreground"
              )}
            >
              <item.icon className="h-5 w-5" />
              <span className="sr-only">{item.label}</span>
            </Link>
          </TooltipTrigger>
          <TooltipContent side="right">{item.label}</TooltipContent>
        </Tooltip>
      ))}
    </nav>
  )
}
