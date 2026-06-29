"use client"

import { useState } from "react"
import Link from "next/link"
import { motion } from "framer-motion"
import { CodeXml } from "lucide-react"

import { useAuth } from "@/contexts/auth-provider"
import type { Role } from "@/lib/types"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"

export default function LoginPage() {
  const [role, setRole] = useState<Role>("student")
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const { login } = useAuth()

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault()
    // In a real app, you'd use the email and password.
    // For this mock, we'll log in the default user for the selected role.
    const mockEmail = role === 'student' ? 'student@codesnap.com' : 'teacher@codesnap.com';
    login(mockEmail, role)
  }

  return (
    <div className="flex items-center justify-center min-h-screen bg-background font-body">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.3 }}
      >
        <Card className="mx-auto max-w-sm w-[400px]">
          <CardHeader className="text-center">
            <div className="flex justify-center items-center mb-4">
               <CodeXml className="h-8 w-8 text-primary" />
            </div>
            <CardTitle className="text-2xl font-headline">Welcome to CodeSnap</CardTitle>
            <CardDescription>
              Select your role and enter your credentials to continue
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleLogin}>
              <div className="grid gap-4">
                <div className="grid gap-2">
                  <Label>Role</Label>
                  <Tabs value={role} onValueChange={(value) => setRole(value as Role)} className="w-full">
                    <TabsList className="grid w-full grid-cols-2">
                      <TabsTrigger value="student">Student</TabsTrigger>
                      <TabsTrigger value="teacher">Teacher</TabsTrigger>
                    </TabsList>
                  </Tabs>
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="email">Email</Label>
                  <Input
                    id="email"
                    type="email"
                    placeholder="name@example.com"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="bg-background"
                  />
                </div>
                <div className="grid gap-2">
                  <div className="flex items-center">
                    <Label htmlFor="password">Password</Label>
                    <Link href="#" className="ml-auto inline-block text-sm underline">
                      Forgot your password?
                    </Link>
                  </div>
                  <Input
                    id="password"
                    type="password"
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="bg-background"
                  />
                </div>
                <Button type="submit" className="w-full transition-transform transform hover:scale-105">
                  Login
                </Button>
              </div>
            </form>
            <div className="mt-4 text-center text-sm">
              Don&apos;t have an account?{" "}
              <Link href="/register" className="underline">
                Register
              </Link>
            </div>
          </CardContent>
        </Card>
      </motion.div>
    </div>
  )
}
