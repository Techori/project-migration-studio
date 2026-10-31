import { useState } from "react";
import { z } from "zod";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

const authSchema = z.object({ email: z.string().trim().email("Enter a valid email").max(255), password: z.string().min(8, "Password must be at least 8 characters").max(72) });

export function AuthForm({ redirectPath = "/" }: { redirectPath?: string }) {
  const [mode, setMode] = useState<"in" | "up">("in");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [msg, setMsg] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault(); setMsg(null);
    const p = authSchema.safeParse({ email, password });
    if (!p.success) { setMsg(p.error.issues[0]?.message ?? "Check the details"); return; }
    setBusy(true);
    if (mode === "in") {
      const { error } = await supabase.auth.signInWithPassword(p.data);
      if (error) setMsg(error.message);
    } else {
      const { data, error } = await supabase.auth.signUp({ ...p.data, options: { emailRedirectTo: `${window.location.origin}${redirectPath}` } });
      if (error) setMsg(error.message);
      else if (!data.session) setMsg("Check your email to confirm your account, then sign in here.");
    }
    setBusy(false);
  }

  return <form onSubmit={submit} className="mt-8 grid max-w-md gap-4 border border-border bg-surface p-6">
    <h2 className="text-lg font-extrabold">{mode === "in" ? "Sign in" : "Create account"}</h2>
    <div className="grid gap-2"><Label htmlFor="a-email">Email</Label><Input id="a-email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="email" /></div>
    <div className="grid gap-2"><Label htmlFor="a-pass">Password</Label><Input id="a-pass" type="password" value={password} onChange={(e) => setPassword(e.target.value)} autoComplete={mode === "in" ? "current-password" : "new-password"} /></div>
    {msg && <p role="status" className="text-sm text-muted-foreground">{msg}</p>}
    <Button type="submit" disabled={busy}>{busy ? "Please wait…" : mode === "in" ? "Sign in" : "Create account"}</Button>
    <button type="button" className="text-left text-xs text-primary" onClick={() => { setMode(mode === "in" ? "up" : "in"); setMsg(null); }}>{mode === "in" ? "No account yet? Create one" : "Already have an account? Sign in"}</button>
  </form>;
}
