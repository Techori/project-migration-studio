CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE TYPE public.app_role AS ENUM ('admin','moderator','user');

CREATE TABLE public.user_roles (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, role public.app_role NOT NULL, UNIQUE(user_id, role));
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$ SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role) $$;
CREATE POLICY "Users read own roles" ON public.user_roles FOR SELECT TO authenticated USING (user_id = auth.uid() OR public.has_role(auth.uid(),'admin'));

CREATE TABLE public.contact_submissions (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL, email text NOT NULL, phone text NOT NULL DEFAULT '', service text NOT NULL DEFAULT '', industry text NOT NULL DEFAULT '', message text NOT NULL DEFAULT '', status text NOT NULL DEFAULT 'new', admin_notes text NOT NULL DEFAULT '', created_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT, UPDATE ON public.contact_submissions TO authenticated;
GRANT ALL ON public.contact_submissions TO service_role;
ALTER TABLE public.contact_submissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins read contacts" ON public.contact_submissions FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin'));
CREATE POLICY "Admins update contacts" ON public.contact_submissions FOR UPDATE TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE TABLE public.registration_applications (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), application_code text NOT NULL UNIQUE, category text NOT NULL, full_name text NOT NULL, email text NOT NULL, phone text NOT NULL DEFAULT '', details jsonb NOT NULL DEFAULT '{}'::jsonb, document_path text, document_name text, status text NOT NULL DEFAULT 'new', admin_notes text NOT NULL DEFAULT '', created_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT, UPDATE ON public.registration_applications TO authenticated;
GRANT ALL ON public.registration_applications TO service_role;
ALTER TABLE public.registration_applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins read applications" ON public.registration_applications FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin'));
CREATE POLICY "Admins update applications" ON public.registration_applications FOR UPDATE TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE TABLE public.country_logos (country text NOT NULL, theme text NOT NULL, file_path text NOT NULL, updated_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY (country, theme));
GRANT SELECT ON public.country_logos TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.country_logos TO authenticated;
GRANT ALL ON public.country_logos TO service_role;
ALTER TABLE public.country_logos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads logos" ON public.country_logos FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Admins manage logos" ON public.country_logos FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE TABLE public.country_programme_fees (country text PRIMARY KEY, currency text NOT NULL, amount integer, updated_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT ON public.country_programme_fees TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.country_programme_fees TO authenticated;
GRANT ALL ON public.country_programme_fees TO service_role;
ALTER TABLE public.country_programme_fees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads fees" ON public.country_programme_fees FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Admins manage fees" ON public.country_programme_fees FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
INSERT INTO public.country_programme_fees (country, currency, amount) VALUES ('usa','USD',169);

CREATE TABLE public.customer_reports (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), report_number text NOT NULL UNIQUE, publish_date date NOT NULL, title text NOT NULL, category text NOT NULL DEFAULT '', file_path text NOT NULL, file_name text NOT NULL, file_size integer NOT NULL DEFAULT 0, active boolean NOT NULL DEFAULT true, created_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT, INSERT, UPDATE, DELETE ON public.customer_reports TO authenticated;
GRANT ALL ON public.customer_reports TO service_role;
ALTER TABLE public.customer_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins manage reports" ON public.customer_reports FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE TABLE public.employees (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), employee_id text NOT NULL UNIQUE, code_hash text NOT NULL, full_name text NOT NULL, photo_url text, designation text NOT NULL DEFAULT '', department text NOT NULL DEFAULT '', status text NOT NULL DEFAULT 'active', valid_until date, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now());
GRANT DELETE ON public.employees TO authenticated;
GRANT SELECT (id, employee_id, full_name, photo_url, designation, department, status, valid_until, created_at, updated_at) ON public.employees TO authenticated;
GRANT ALL ON public.employees TO service_role;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins read employees" ON public.employees FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin'));
CREATE POLICY "Admins delete employees" ON public.employees FOR DELETE TO authenticated USING (public.has_role(auth.uid(),'admin'));

CREATE TABLE public.employee_verification_attempts (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, employee_id text NOT NULL, success boolean NOT NULL, created_at timestamptz NOT NULL DEFAULT now());
GRANT ALL ON public.employee_verification_attempts TO service_role;
ALTER TABLE public.employee_verification_attempts ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.form_submission_limits (key_hash text PRIMARY KEY, window_started_at timestamptz NOT NULL DEFAULT now(), attempts integer NOT NULL DEFAULT 0);
GRANT ALL ON public.form_submission_limits TO service_role;
ALTER TABLE public.form_submission_limits ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.people_profiles (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), person_group text NOT NULL, slug text NOT NULL UNIQUE, name text NOT NULL, role text NOT NULL DEFAULT '', location text NOT NULL DEFAULT '', focus text[] NOT NULL DEFAULT '{}', summary text NOT NULL DEFAULT '', bio text NOT NULL DEFAULT '', photo_url text, sort_order integer NOT NULL DEFAULT 0, source_application_id uuid, created_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT ON public.people_profiles TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.people_profiles TO authenticated;
GRANT ALL ON public.people_profiles TO service_role;
ALTER TABLE public.people_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads profiles" ON public.people_profiles FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Admins manage profiles" ON public.people_profiles FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE TABLE public.prototype_ai_access_state (model_id text PRIMARY KEY, status_code integer NOT NULL, message text NOT NULL DEFAULT '', blocked_at timestamptz NOT NULL DEFAULT now());
GRANT ALL ON public.prototype_ai_access_state TO service_role;
ALTER TABLE public.prototype_ai_access_state ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.prototype_submissions (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), idea text NOT NULL, prototype text NOT NULL, funding_goal text NOT NULL DEFAULT '', eligibility_context text NOT NULL DEFAULT '', ai_output text NOT NULL DEFAULT '', created_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT ON public.prototype_submissions TO authenticated;
GRANT ALL ON public.prototype_submissions TO service_role;
ALTER TABLE public.prototype_submissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins read prototype submissions" ON public.prototype_submissions FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin'));

CREATE TABLE public.young_innovators_registrations (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), application_code text NOT NULL UNIQUE, student_name text NOT NULL,
 school_class integer NOT NULL CHECK (school_class BETWEEN 6 AND 12), city text NOT NULL, guardian_name text NOT NULL,
 guardian_email text NOT NULL, guardian_phone text NOT NULL, idea_title text NOT NULL, idea text NOT NULL,
 guardian_consent boolean NOT NULL CHECK (guardian_consent = true), consent_at timestamptz NOT NULL DEFAULT now(),
 fee_amount integer NOT NULL, gst_percent integer NOT NULL DEFAULT 18, status text NOT NULL DEFAULT 'new', created_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT ON public.young_innovators_registrations TO authenticated;
GRANT ALL ON public.young_innovators_registrations TO service_role;
ALTER TABLE public.young_innovators_registrations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins read student registrations" ON public.young_innovators_registrations FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin'));

CREATE OR REPLACE FUNCTION public.consume_form_submission_limit(_key_hash text) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE r public.form_submission_limits;
BEGIN
  INSERT INTO public.form_submission_limits AS l (key_hash, window_started_at, attempts) VALUES (_key_hash, now(), 1)
  ON CONFLICT (key_hash) DO UPDATE SET
    attempts = CASE WHEN l.window_started_at < now() - interval '15 minutes' THEN 1 ELSE l.attempts + 1 END,
    window_started_at = CASE WHEN l.window_started_at < now() - interval '15 minutes' THEN now() ELSE l.window_started_at END
  RETURNING * INTO r;
  RETURN r.attempts <= 5;
END $$;
REVOKE EXECUTE ON FUNCTION public.consume_form_submission_limit(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.consume_form_submission_limit(text) TO service_role;

CREATE OR REPLACE FUNCTION public.admin_save_employee(_employee_id text, _code text, _full_name text, _photo_url text, _designation text, _department text, _status text, _valid_until date) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'Admin access required'; END IF;
  IF EXISTS (SELECT 1 FROM public.employees WHERE employee_id = _employee_id) THEN
    UPDATE public.employees SET full_name=_full_name, photo_url=NULLIF(_photo_url,''), designation=_designation, department=_department, status=_status, valid_until=_valid_until, updated_at=now(),
      code_hash = CASE WHEN coalesce(_code,'') = '' THEN code_hash ELSE crypt(_code, gen_salt('bf')) END
    WHERE employee_id = _employee_id;
  ELSE
    IF length(coalesce(_code,'')) < 6 THEN RAISE EXCEPTION 'Code too short'; END IF;
    INSERT INTO public.employees (employee_id, code_hash, full_name, photo_url, designation, department, status, valid_until)
    VALUES (_employee_id, crypt(_code, gen_salt('bf')), _full_name, NULLIF(_photo_url,''), _designation, _department, _status, _valid_until);
  END IF;
END $$;
REVOKE EXECUTE ON FUNCTION public.admin_save_employee(text,text,text,text,text,text,text,date) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_save_employee(text,text,text,text,text,text,text,date) TO authenticated;

CREATE OR REPLACE FUNCTION public.verify_employee(_employee_id text, _code text) RETURNS TABLE(employee_id text, full_name text, photo_url text, designation text, department text, status text, valid_until text) LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE ok boolean;
BEGIN
  IF (SELECT count(*) FROM public.employee_verification_attempts a WHERE a.employee_id = _employee_id AND NOT a.success AND a.created_at > now() - interval '15 minutes') >= 5 THEN RETURN; END IF;
  SELECT EXISTS (SELECT 1 FROM public.employees e WHERE e.employee_id = _employee_id AND e.code_hash = crypt(_code, e.code_hash)) INTO ok;
  INSERT INTO public.employee_verification_attempts (employee_id, success) VALUES (_employee_id, ok);
  IF ok THEN
    RETURN QUERY SELECT e.employee_id, e.full_name, coalesce(e.photo_url,''), e.designation, e.department, e.status, coalesce(e.valid_until::text,'') FROM public.employees e WHERE e.employee_id = _employee_id;
  END IF;
END $$;
GRANT EXECUTE ON FUNCTION public.verify_employee(text,text) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.admin_setup_metadata() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'Admin access required'; END IF;
  RETURN jsonb_build_object(
    'tables', coalesce((SELECT jsonb_agg(jsonb_build_object('name', c.relname, 'rls', c.relrowsecurity,
      'columns', (SELECT jsonb_agg(jsonb_build_object('name', a.attname, 'type', format_type(a.atttypid, a.atttypmod), 'nullable', NOT a.attnotnull) ORDER BY a.attnum) FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped)))
      FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relkind = 'r'), '[]'::jsonb),
    'functions', coalesce((SELECT jsonb_agg(DISTINCT p.proname) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public'), '[]'::jsonb));
END $$;
REVOKE EXECUTE ON FUNCTION public.admin_setup_metadata() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_setup_metadata() TO authenticated;

CREATE POLICY "Admins manage private files" ON storage.objects FOR ALL TO authenticated
 USING (bucket_id IN ('registration-documents','customer-reports','country-logos') AND public.has_role(auth.uid(),'admin'))
 WITH CHECK (bucket_id IN ('registration-documents','customer-reports','country-logos') AND public.has_role(auth.uid(),'admin'));
CREATE POLICY "Anyone can sign logo links" ON storage.objects FOR SELECT TO anon USING (bucket_id = 'country-logos');