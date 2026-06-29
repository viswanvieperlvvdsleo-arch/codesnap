
"use client";

import { useAuth } from "@/contexts/auth-provider";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

function getInitials(name: string) {
    if (!name) return "";
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase();
}

export default function ProfilePage() {
    const { user } = useAuth();

    if (!user) {
        return (
             <div className="flex items-center justify-center h-screen">
                <div className="w-16 h-16 border-4 border-dashed rounded-full animate-spin border-primary"></div>
            </div>
        );
    }

    return (
        <div className="flex justify-center items-start p-4 sm:p-6 md:p-8">
            <Card className="w-full max-w-2xl">
                <CardHeader>
                    <CardTitle>My Profile</CardTitle>
                    <CardDescription>View and manage your personal information.</CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                    <div className="flex items-center space-x-4">
                        <Avatar className="h-24 w-24">
                            <AvatarImage src={user.avatarUrl} alt={user.name} />
                            <AvatarFallback>{getInitials(user.name)}</AvatarFallback>
                        </Avatar>
                        <div className="space-y-1">
                            <h2 className="text-2xl font-bold">{user.name}</h2>
                            <p className="text-muted-foreground">{user.email}</p>
                            <p className="text-sm font-medium text-primary capitalize">{user.role}</p>
                        </div>
                    </div>
                    <form className="space-y-4">
                        <div className="grid gap-2">
                            <Label htmlFor="name">Full Name</Label>
                            <Input id="name" defaultValue={user.name} />
                        </div>
                        <div className="grid gap-2">
                            <Label htmlFor="email">Email</Label>
                            <Input id="email" type="email" defaultValue={user.email} disabled />
                        </div>
                         {user.role === 'student' && user.section && (
                            <div className="grid gap-2">
                                <Label htmlFor="section">Section</Label>
                                <Input id="section" defaultValue={`Section ${user.section}`} disabled />
                            </div>
                        )}
                        <Button type="submit">Save Changes</Button>
                    </form>
                </CardContent>
            </Card>
        </div>
    )
}
