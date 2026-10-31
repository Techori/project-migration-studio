CREATE TABLE public.profiles (id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE, display_name text NOT NULL DEFAULT '', avatar_url text NOT NULL DEFAULT '', preferences jsonb NOT NULL DEFAULT '{}'::jsonb);
GRANT SELECT, UPDATE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Read own account profile" ON public.profiles FOR SELECT TO authenticated USING (id = auth.uid());
CREATE POLICY "Update own account profile" ON public.profiles FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE FUNCTION public.create_account_profile() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$ BEGIN INSERT INTO public.profiles(id) VALUES (NEW.id) ON CONFLICT DO NOTHING; RETURN NEW; END; $$;
CREATE TRIGGER create_account_profile AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.create_account_profile();
INSERT INTO public.profiles(id) SELECT id FROM auth.users ON CONFLICT DO NOTHING;
CREATE FUNCTION public.claim_first_admin() RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE first_id uuid;
BEGIN
 PERFORM pg_advisory_xact_lock(761924);
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Sign in required'; END IF;
 IF EXISTS (SELECT 1 FROM public.user_roles WHERE role = 'admin') THEN RAISE EXCEPTION 'Admin setup is already complete'; END IF;
 SELECT id INTO first_id FROM auth.users ORDER BY created_at, id LIMIT 1;
 IF first_id IS DISTINCT FROM auth.uid() THEN RAISE EXCEPTION 'Only the first registered account can complete setup'; END IF;
 IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND email_confirmed_at IS NOT NULL AND email IS NOT NULL) THEN RAISE EXCEPTION 'Verify your email first'; END IF;
 INSERT INTO public.user_roles(user_id,role) VALUES(auth.uid(),'admin');
 RETURN true;
END; $$;
REVOKE ALL ON FUNCTION public.claim_first_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.claim_first_admin() TO authenticated;
GRANT INSERT ON public.contact_submissions, public.registration_applications, public.employees, public.prototype_submissions, public.young_innovators_registrations TO authenticated;
CREATE POLICY "Admin imports contacts" ON public.contact_submissions FOR INSERT TO authenticated WITH CHECK(public.has_role(auth.uid(),'admin'));
CREATE POLICY "Admin imports registrations" ON public.registration_applications FOR INSERT TO authenticated WITH CHECK(public.has_role(auth.uid(),'admin'));
CREATE POLICY "Admin imports employees" ON public.employees FOR INSERT TO authenticated WITH CHECK(public.has_role(auth.uid(),'admin'));
CREATE POLICY "Admin imports prototypes" ON public.prototype_submissions FOR INSERT TO authenticated WITH CHECK(public.has_role(auth.uid(),'admin'));
CREATE POLICY "Admin imports young registrations" ON public.young_innovators_registrations FOR INSERT TO authenticated WITH CHECK(public.has_role(auth.uid(),'admin'));
CREATE FUNCTION public.admin_import_records(_table text, _rows jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
DECLARE r jsonb; cols text; expressions text; inserted integer := 0; affected integer;
BEGIN
 IF NOT public.has_role(auth.uid(),'admin') THEN RAISE EXCEPTION 'Admin access required'; END IF;
 IF _table NOT IN ('contact_submissions','registration_applications','employees','people_profiles','country_logos','country_programme_fees','customer_reports','prototype_submissions','young_innovators_registrations') THEN RAISE EXCEPTION 'Unsupported import destination'; END IF;
 IF jsonb_typeof(_rows) <> 'array' OR jsonb_array_length(_rows) NOT BETWEEN 1 AND 1000 THEN RAISE EXCEPTION 'Import requires 1 to 1000 rows'; END IF;
 FOR r IN SELECT value FROM jsonb_array_elements(_rows) LOOP
  SELECT string_agg(format('%I',key),',' ORDER BY key), string_agg(format('x.%I',key),',' ORDER BY key) INTO cols, expressions FROM jsonb_object_keys(r) AS key;
  IF cols IS NULL THEN RAISE EXCEPTION 'Empty record'; END IF;
  EXECUTE format('INSERT INTO public.%I (%s) SELECT %s FROM jsonb_populate_record(NULL::public.%I, $1) x ON CONFLICT DO NOTHING', _table, cols, expressions, _table) USING r;
  GET DIAGNOSTICS affected = ROW_COUNT;
  inserted := inserted + affected;
 END LOOP;
 RETURN jsonb_build_object('inserted', inserted, 'skipped', jsonb_array_length(_rows)-inserted);
END; $$;
REVOKE ALL ON FUNCTION public.admin_import_records(text,jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_import_records(text,jsonb) TO authenticated;