"use client";

import * as React from "react";
import { Search, ListFilter, X } from "lucide-react";

import { mockProjects } from "@/lib/mock-data";
import type { Project } from "@/lib/types";

import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { ProjectCard } from "@/components/projects/ProjectCard";
import { ProjectDetailsModal } from "@/components/projects/ProjectDetailsModal";
import { ProjectPreviewModal } from "@/components/projects/ProjectPreviewModal";
import { FolderSearch } from "lucide-react";

const categories = [
  "All",
  "E-Commerce",
  "Dashboard",
  "Social Media",
  "Forms & Authentication",
  "Portfolio",
  "Education",
  "Restaurant & Booking",
  "Productivity Tools",
];

const difficulties = ["All", "Beginner", "Intermediate", "Advanced"];

export default function ProjectsPage() {
  const [searchTerm, setSearchTerm] = React.useState("");
  const [selectedCategory, setSelectedCategory] = React.useState("All");
  const [selectedDifficulty, setSelectedDifficulty] = React.useState("All");

  const [selectedProject, setSelectedProject] = React.useState<Project | null>(null);
  const [isPreviewModalOpen, setPreviewModalOpen] = React.useState(false);
  const [isDetailsModalOpen, setDetailsModalOpen] = React.useState(false);

  const filteredProjects = React.useMemo(() => {
    return mockProjects.filter((project) => {
      const matchesSearch = project.title
        .toLowerCase()
        .includes(searchTerm.toLowerCase());
      const matchesCategory =
        selectedCategory === "All" || project.category === selectedCategory;
      const matchesDifficulty =
        selectedDifficulty === "All" ||
        project.difficulty === selectedDifficulty;
      return matchesSearch && matchesCategory && matchesDifficulty;
    });
  }, [searchTerm, selectedCategory, selectedDifficulty]);

  const handlePreview = (project: Project) => {
    setSelectedProject(project);
    setPreviewModalOpen(true);
  };

  const handleDetails = (project: Project) => {
    setSelectedProject(project);
    setDetailsModalOpen(true);
  };
  
  const clearFilters = () => {
    setSearchTerm("");
    setSelectedCategory("All");
    setSelectedDifficulty("All");
  };

  return (
    <>
      <div className="container mx-auto p-4 md:p-6 space-y-8">
        <header className="text-center space-y-2">
          <h1 className="text-4xl font-bold font-headline">
            Advanced Project Library
          </h1>
          <p className="text-muted-foreground max-w-2xl mx-auto">
            Browse our collection of pre-built project templates. Use them as a
            starting point for your own creations or to learn advanced coding
            patterns.
          </p>
        </header>

        {/* Filter and Search Bar */}
        <div className="flex flex-col md:flex-row items-center gap-4 p-4 rounded-lg border bg-card">
          <div className="relative w-full md:flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
            <Input
              placeholder="Search projects..."
              className="pl-10 h-11 text-base"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <div className="flex w-full md:w-auto gap-2">
            <Select value={selectedCategory} onValueChange={setSelectedCategory}>
              <SelectTrigger className="w-full md:w-[200px] h-11">
                <SelectValue placeholder="Category" />
              </SelectTrigger>
              <SelectContent>
                {categories.map((cat) => (
                  <SelectItem key={cat} value={cat}>
                    {cat === "All" ? "All Categories" : cat}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Select
              value={selectedDifficulty}
              onValueChange={setSelectedDifficulty}
            >
              <SelectTrigger className="w-full md:w-[180px] h-11">
                <SelectValue placeholder="Difficulty" />
              </SelectTrigger>
              <SelectContent>
                {difficulties.map((diff) => (
                  <SelectItem key={diff} value={diff}>
                    {diff === "All" ? "All Difficulties" : diff}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
             <Button variant="ghost" size="icon" onClick={clearFilters} className="h-11 w-11">
                <X className="h-5 w-5" />
                <span className="sr-only">Clear Filters</span>
            </Button>
          </div>
        </div>

        {/* Projects Grid */}
        {filteredProjects.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredProjects.map((project) => (
              <ProjectCard
                key={project.id}
                project={project}
                onPreview={handlePreview}
                onDetails={handleDetails}
              />
            ))}
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center text-center py-16 text-muted-foreground rounded-lg border-2 border-dashed">
            <FolderSearch className="h-16 w-16 mb-4" />
            <h2 className="text-xl font-semibold">No Projects Found</h2>
            <p>Try adjusting your search or filters to find what you're looking for.</p>
          </div>
        )}
      </div>

      {selectedProject && (
        <>
          <ProjectPreviewModal
            isOpen={isPreviewModalOpen}
            setIsOpen={setPreviewModalOpen}
            project={selectedProject}
          />
          <ProjectDetailsModal
            isOpen={isDetailsModalOpen}
            setIsOpen={setDetailsModalOpen}
            project={selectedProject}
          />
        </>
      )}
    </>
  );
}
