"use client"

import { createContext, useContext, useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import type { User, Role } from "@/lib/types"
import { mockUsers } from "@/lib/mock-data"

interface AuthContextType {
  user: User | null
  login: (email: string, role: Role) => void
  logout: () => void
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const router = useRouter()

  useEffect(() => {
    // For demo purposes, check if a user is "logged in" from a previous session
    const storedUser = sessionStorage.getItem("currentUser")
    if (storedUser) {
      setUser(JSON.parse(storedUser))
    }
  }, [])

  const login = (email: string, role: Role) => {
    const foundUser = mockUsers.find(
      (u) => u.email === email && u.role === role
    )
    if (foundUser) {
      setUser(foundUser)
      sessionStorage.setItem("currentUser", JSON.stringify(foundUser))
      router.push("/tasks")
    } else {
      // In a real app, you'd show an error.
      // For this demo, we'll just log in as the default for the selected role.
      const defaultUser = mockUsers.find(u => u.role === role);
      if (defaultUser) {
        setUser(defaultUser);
        sessionStorage.setItem("currentUser", JSON.stringify(defaultUser));
        router.push("/tasks");
      }
    }
  }

  const logout = () => {
    setUser(null)
    sessionStorage.removeItem("currentUser")
    router.push("/login")
  }

  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider")
  }
  return context
}
