import { createFileRoute } from "@tanstack/react-router";
import { RegistrationPage } from "@/components/registration/registration-page";
import { registrationConfigs } from "@/lib/registration-config";

export const Route = createFileRoute("/register/investor")({
  head: () => ({ meta: [
    { title: "Investor Registration | Riloyd" },
    { name: "description", content: "Register as a investor with Riloyd and access relevant expertise, connections and growth opportunities." },
    { property: "og:title", content: "Investor Registration | Riloyd" },
    { property: "og:description", content: "Join Riloyd's ecosystem as a investor." },
    { property: "og:type", content: "website" }, { name: "twitter:card", content: "summary_large_image" },
  ]}),
  component: () => <RegistrationPage config={registrationConfigs.investor} />,
});
