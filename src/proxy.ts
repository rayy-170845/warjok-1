import { auth } from "@/server/auth";

export default auth.middleware({
  loginUrl: "/login",
  publicRoutes: [
    "/login",
    "/signup",
    "/forgot-password",
    "/reset-password",
    "/profile",
    "/api/health",
    "/api/business",
    "/api/demo/seed",
  ],
});

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)"],
};
