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
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"

export default function RegisterPage() {
  const [role, setRole] = useState<Role>("student")
  const { login } = useAuth()

  const handleRegister = (e: React.FormEvent) => {
    e.preventDefault()
    // Mock registration by logging in the user
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
            <CardTitle className="text-2xl font-headline">Create an Account</CardTitle>
            <CardDescription>
              Join CodeSnap to start your coding journey
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleRegister}>
              <div className="grid gap-4">
                <div className="grid gap-2">
                  <Label htmlFor="name">Name</Label>
                  <Input id="name" placeholder="Max Robinson" required className="bg-background" />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="email">Email</Label>
                  <Input
                    id="email"
                    type="email"
                    placeholder="name@example.com"
                    required
                    className="bg-background"
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="password">Password</Label>
                  <Input id="password" type="password" required className="bg-background" />
                </div>
                <div className="grid gap-2">
                  <Label>Role</Label>
                  <Tabs value={role} onValueChange={(value) => setRole(value as Role)} className="w-full">
                    <TabsList className="grid w-full grid-cols-2">
                      <TabsTrigger value="student">Student</TabsTrigger>
                      <TabsTrigger value="teacher">Teacher</TabsTrigger>
                    </TabsList>
                  </Tabs>
                </div>

                {role === "student" && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    transition={{ duration: 0.3 }}
                    className="grid gap-2"
                  >
                    <Label htmlFor="section">Section</Label>
                    <Select>
                      <SelectTrigger>
                        <SelectValue placeholder="Select a section" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="A">Section A</SelectItem>
                        <SelectItem value="B">Section B</SelectItem>
                        <SelectItem value="C">Section C</SelectItem>
                      </SelectContent>
                    </Select>
                  </motion.div>
                )}

                <Button type="submit" className="w-full transition-transform transform hover:scale-105">
                  Create Account
                </Button>
              </div>
            </form>
            <div className="mt-4 text-center text-sm">
              Already have an account?{" "}
              <Link href="/login" className="underline">
                Login
              </Link>
            </div>
          </CardContent>
        </Card>
      </motion.div>
    </div>
  )
}
