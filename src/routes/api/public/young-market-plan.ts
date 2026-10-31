import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/api/public/young-market-plan")({
  server: { handlers: { POST: async ({ request }) => {
    const { studentMarketPlan } = await import("@/lib/young-market.server");
    return studentMarketPlan(request);
  } } },
});