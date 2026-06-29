"use client"

import { ThemeProvider } from "@/contexts/theme-provider"
import { AuthProvider } from "@/contexts/auth-provider"

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider defaultTheme="dark" storageKey="codesnap-theme">
      <AuthProvider>{children}</AuthProvider>
    </ThemeProvider>
  )
}
