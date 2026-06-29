"use client"

import Link from "next/link"
import { usePathname } from "next/navigation"
import React from "react"
import {
  Bell,
  Menu,
  CodeXml,
  ClipboardList,
  BookOpen,
  FolderKanban,
  Code,
  Share2,
} from "lucide-react"

import { useAuth } from "@/contexts/auth-provider"
import { useTheme } from "@/contexts/theme-provider"

import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
  DropdownMenuSub,
  DropdownMenuSubTrigger,
  DropdownMenuPortal,
  DropdownMenuSubContent,
} from "@/components/ui/dropdown-menu"
import {
  Sheet,
  SheetContent,
  SheetTrigger,
  SheetHeader,
  SheetTitle,
  SheetDescription,
} from "@/components/ui/sheet"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from "@/components/ui/breadcrumb"
import { cn } from "@/lib/utils"
import { useToast } from "@/hooks/use-toast"


const navItems = [
  { href: "/tasks", icon: ClipboardList, label: "Tasks" },
  { href: "/learn", icon: BookOpen, label: "Learn" },
  { href: "/projects", icon: FolderKanban, label: "Projects" },
  { href: "/workspace", icon: Code, label: "Workspace" },
]

function getInitials(name: string) {
  if (!name) return ""
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
}

export function Header() {
  const { user, logout } = useAuth()
  const { setTheme } = useTheme()
  const pathname = usePathname()
  const { toast } = useToast()

  const breadcrumbParts = pathname.split('/').filter(p => p);

  const handleShare = () => {
    const url = typeof window !== 'undefined' ? window.location.href : '';
    navigator.clipboard.writeText(url).then(() => {
      toast({
        title: "Link Copied!",
        description: "Project link has been copied to your clipboard.",
      });
    });
  };


  return (
    <header className="sticky top-0 flex h-16 items-center gap-4 border-b bg-card px-4 md:px-6 z-50">
      <nav className="hidden flex-col gap-6 text-lg font-medium md:flex md:flex-row md:items-center md:gap-5 md:text-sm lg:gap-6">
        <Link
          href="/tasks"
          className="flex items-center gap-2 text-lg font-semibold md:text-base"
        >
          <CodeXml className="h-6 w-6 text-primary" />
          <span className="sr-only">CodeSnap</span>
        </Link>
        {navItems.map((item) => (
            <Link
                key={item.href}
                href={item.href}
                className={cn("transition-colors hover:text-foreground", 
                    pathname.startsWith(item.href) ? 'text-foreground' : 'text-muted-foreground'
                )}
            >
                {item.label}
            </Link>
        ))}
      </nav>
      
      <Sheet>
        <SheetTrigger asChild>
          <Button
            variant="outline"
            size="icon"
            className="shrink-0 md:hidden"
          >
            <Menu className="h-5 w-5" />
            <span className="sr-only">Toggle navigation menu</span>
          </Button>
        </SheetTrigger>
        <SheetContent side="left">
          <SheetHeader>
            <SheetTitle asChild>
                <Link
                href="/tasks"
                className="flex items-center gap-2 text-lg font-semibold"
                >
                <CodeXml className="h-6 w-6 text-primary" />
                <span>CodeSnap</span>
                </Link>
            </SheetTitle>
            <SheetDescription className="sr-only">Main Navigation</SheetDescription>
          </SheetHeader>
          <nav className="grid gap-6 text-lg font-medium mt-4">
            {navItems.map((item) => (
                 <Link
                    key={item.href}
                    href={item.href}
                    className={cn("hover:text-foreground",
                        pathname.startsWith(item.href) ? 'text-foreground' : 'text-muted-foreground'
                    )}
                >
                    {item.label}
                </Link>
            ))}
          </nav>
        </SheetContent>
      </Sheet>

      <div className="flex w-full items-center justify-between md:ml-auto">
        <div className="flex-1">
          <Breadcrumb className="hidden md:flex">
            <BreadcrumbList>
              <BreadcrumbItem>
                <BreadcrumbLink asChild>
                  <Link href="/tasks">Dashboard</Link>
                </BreadcrumbLink>
              </BreadcrumbItem>
              {breadcrumbParts.map((part, index) => {
                  const href = `/${breadcrumbParts.slice(0, index + 1).join('/')}`;
                  const isLast = index === breadcrumbParts.length - 1;
                  const label = part.charAt(0).toUpperCase() + part.slice(1);
                  return (
                      <React.Fragment key={href}>
                        <BreadcrumbSeparator />
                        <BreadcrumbItem>
                            {isLast ? (
                            <BreadcrumbPage>{label}</BreadcrumbPage>
                            ) : (
                            <BreadcrumbLink asChild>
                                <Link href={href}>{label}</Link>
                            </BreadcrumbLink>
                            )}
                        </BreadcrumbItem>
                      </React.Fragment>
                  )
              })}
            </BreadcrumbList>
          </Breadcrumb>
        </div>

        <div className="flex items-center gap-2 md:gap-4">
          <Button variant="outline" size="sm" onClick={handleShare} className="hidden sm:flex">
            <Share2 className="mr-2 h-4 w-4" /> Share
          </Button>
          <Button variant="outline" size="icon" className="relative h-8 w-8">
              <Bell className="h-4 w-4" />
              <span className="sr-only">Notifications</span>
              <span className="absolute -top-1 -right-1 flex h-3 w-3">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-3 w-3 bg-primary"></span>
              </span>
          </Button>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="secondary" size="icon" className="rounded-full h-8 w-8">
                <Avatar className="h-8 w-8">
                  <AvatarImage src={user?.avatarUrl} alt={user?.name} />
                  <AvatarFallback>{user ? getInitials(user.name) : "U"}</AvatarFallback>
                </Avatar>
                <span className="sr-only">Toggle user menu</span>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuLabel>My Account</DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem asChild>
                <Link href="/profile">Profile</Link>
              </DropdownMenuItem>
              <DropdownMenuSub>
                  <DropdownMenuSubTrigger>
                    <span>Theme</span>
                  </DropdownMenuSubTrigger>
                  <DropdownMenuPortal>
                    <DropdownMenuSubContent>
                      <DropdownMenuItem onClick={() => setTheme('light')}>Light</DropdownMenuItem>
                      <DropdownMenuItem onClick={() => setTheme('dark')}>Dark</DropdownMenuItem>
                      <DropdownMenuItem onClick={() => setTheme('system')}>System</DropdownMenuItem>
                    </DropdownMenuSubContent>
                  </DropdownMenuPortal>
                </DropdownMenuSub>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={logout}>Logout</DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>
    </header>
  )
}
