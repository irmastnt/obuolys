import { Button } from "@/components/ui/button";

export default function Home() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center gap-6 p-8">
      <h1 className="text-3xl font-semibold tracking-tight">
        Advanced Vibe Coding Starter
      </h1>
      <p className="text-muted-foreground max-w-md text-center">
        Patikrintas Next.js 16.2+ ir React 19 starter kit su CI, testais ir
        AI powerpack. Vite, Supabase ir Vercel keliai adaptuojami pagal
        projektą.
      </p>
      <Button>Pradėti</Button>
    </main>
  );
}
