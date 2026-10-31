CREATE UNIQUE INDEX IF NOT EXISTS people_profiles_source_application_unique ON public.people_profiles(source_application_id) WHERE source_application_id IS NOT NULL;
CREATE OR REPLACE FUNCTION public.sync_approved_application_profile() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE group_name text;
BEGIN
 IF TG_OP = 'DELETE' THEN DELETE FROM public.people_profiles WHERE source_application_id = OLD.id; RETURN OLD; END IF;
 group_name := CASE NEW.category WHEN 'investor' THEN 'investors' WHEN 'mentor' THEN 'mentors' WHEN 'startup' THEN 'startups' WHEN 'business' THEN 'businesses' ELSE NULL END;
 IF NEW.status <> 'approved' OR group_name IS NULL THEN DELETE FROM public.people_profiles WHERE source_application_id = NEW.id; RETURN NEW; END IF;
 INSERT INTO public.people_profiles(person_group,slug,name,source_application_id)
 VALUES(group_name, 'application-' || NEW.id::text, NEW.full_name, NEW.id)
 ON CONFLICT (source_application_id) WHERE source_application_id IS NOT NULL
 DO UPDATE SET person_group = EXCLUDED.person_group, name = EXCLUDED.name;
 RETURN NEW;
END; $$;
REVOKE ALL ON FUNCTION public.sync_approved_application_profile() FROM PUBLIC, anon, authenticated;
CREATE TRIGGER sync_approved_application_profile AFTER INSERT OR UPDATE OR DELETE ON public.registration_applications FOR EACH ROW EXECUTE FUNCTION public.sync_approved_application_profile();
INSERT INTO public.people_profiles(person_group,slug,name,source_application_id)
SELECT CASE category WHEN 'investor' THEN 'investors' WHEN 'mentor' THEN 'mentors' WHEN 'startup' THEN 'startups' WHEN 'business' THEN 'businesses' END, 'application-' || id::text, full_name, id FROM public.registration_applications WHERE status='approved' AND category IN ('investor','mentor','startup','business')
ON CONFLICT (source_application_id) WHERE source_application_id IS NOT NULL DO UPDATE SET person_group=EXCLUDED.person_group,name=EXCLUDED.name;
CREATE OR REPLACE FUNCTION public.first_admin_setup_status() RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE first_id uuid;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Sign in required'; END IF;
 IF EXISTS(SELECT 1 FROM public.user_roles WHERE role='admin') THEN RETURN 'closed'; END IF;
 SELECT id INTO first_id FROM auth.users ORDER BY created_at,id LIMIT 1;
 IF first_id IS DISTINCT FROM auth.uid() THEN RETURN 'ineligible'; END IF;
 IF NOT EXISTS(SELECT 1 FROM auth.users WHERE id=auth.uid() AND email_confirmed_at IS NOT NULL) THEN RETURN 'unverified'; END IF;
 RETURN 'eligible';
END; $$;
REVOKE ALL ON FUNCTION public.first_admin_setup_status() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.first_admin_setup_status() TO authenticated;
CREATE OR REPLACE FUNCTION public.admin_setup_metadata() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = public AS $$
BEGIN
 IF NOT public.has_role(auth.uid(),'admin') THEN RAISE EXCEPTION 'Admin access required'; END IF;
 RETURN jsonb_build_object(
 'tables',coalesce((SELECT jsonb_agg(jsonb_build_object('name',c.relname,'rls',c.relrowsecurity,'columns',(SELECT jsonb_agg(jsonb_build_object('name',a.attname,'type',format_type(a.atttypid,a.atttypmod),'nullable',NOT a.attnotnull) ORDER BY a.attnum) FROM pg_attribute a WHERE a.attrelid=c.oid AND a.attnum>0 AND NOT a.attisdropped))) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relkind='r'),'[]'::jsonb),
 'functions',coalesce((SELECT jsonb_agg(DISTINCT p.proname) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public'),'[]'::jsonb),
 'triggers',coalesce((SELECT jsonb_agg(t.tgname) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','auth') AND NOT t.tgisinternal),'[]'::jsonb));
END; $$;
REVOKE ALL ON FUNCTION public.admin_setup_metadata() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_setup_metadata() TO authenticated;