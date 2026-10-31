import { createServerFn } from '@tanstack/react-start';
import { requireSupabaseAuth } from '@/integrations/supabase/auth-middleware';

export const claimFirstAdmin = createServerFn({ method: 'POST' }).middleware([requireSupabaseAuth]).handler(async ({ context }) => {
  const { data: user, error: userError } = await context.supabase.auth.getUser();
  if (userError || !user.user?.email_confirmed_at) throw new Error('Verify your email before completing setup.');
  const { error } = await context.supabase.rpc('claim_first_admin');
  if (error) throw new Error('Setup is unavailable: only the first registered, verified account may claim admin access, and only before an admin exists.');
  return { ok: true };
});