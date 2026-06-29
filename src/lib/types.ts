export type Role = 'teacher' | 'student';

export type User = {
  id: string;
  name: string;
  email: string;
  role: Role;
  section?: string;
  avatarUrl: string;
};

export type Task = {
  id: string;
  title: string;
  description: string;
  course: string;
  branch: string;
  section: string;
  year: string;
  deadline: string;
  createdAt: string;
  ownerId: string;
  submissionCount: number;
  starterCode?: string;
};

export type AcademicOptions = {
  courses: string[];
  branches: string[];
  sections: string[];
  years: string[];
};

export type Submission = {
  id: string;
  taskId: string;
  studentId: string;
  studentName: string;
  code: string;
  submittedAt: string;
  status: 'pending' | 'approved' | 'rejected';
  versionCount: number;
};

export type Project = {
  id: string;
  title: string;
  category: string;
  difficulty: "Beginner" | "Intermediate" | "Advanced";
  description: string;
  features: string[];
  techStack: ("HTML" | "CSS" | "JS")[];
  estimatedTime: string;
  thumbnailUrl: string;
  htmlTemplate: string;
  cssTemplate: string;
  jsTemplate: string;
};

export type Notification = {
  id: string;
  userId: string;
  message: string;
  createdAt: string;
  read: boolean;
  type: 'submission' | 'approval' | 'project';
};

export interface LearnContent {
  day: number;
  category: "HTML" | "CSS" | "JavaScript";
  title: string;
  theory: string;
  codeExample: string;
  task: string;
}
