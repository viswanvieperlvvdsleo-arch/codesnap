"use client"

import { useRouter } from "next/navigation"
import { useEffect } from "react"
import { useAuth } from "@/contexts/auth-provider"
import { Header } from "@/components/layout/Header"

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const { user } = useAuth()
  const router = useRouter()

  useEffect(() => {
    // In a real app with server-side auth, this would be handled differently.
    // For this mock, we redirect if the user is not "logged in" on the client.
    if (user === null && typeof window !== 'undefined') {
       const storedUser = sessionStorage.getItem("currentUser")
       if (!storedUser) {
        router.push("/login")
       }
    }
  }, [user, router])
  
  if (!user) {
    // Render a loading state or null while checking for user
    return (
        <div className="flex items-center justify-center h-screen">
            <div className="w-16 h-16 border-4 border-dashed rounded-full animate-spin border-primary"></div>
        </div>
    );
  }

  return (
    <div className="flex min-h-screen w-full flex-col bg-background">
      <Header />
      <main className="flex flex-1 flex-col gap-4 p-4 md:gap-8 md:p-8">
        {children}
      </main>
    </div>
  )
}
