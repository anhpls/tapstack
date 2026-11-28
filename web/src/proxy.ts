import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

export async function proxy(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          // hand the fresh session to the page we're about to render...
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          // ...and to the browser so it sticks around
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  // this is what refreshes the session. keep it right after createServerClient
  const { data } = await supabase.auth.getClaims();
  const signedIn = !!data?.claims;

  const onLogin = request.nextUrl.pathname.startsWith("/login");

  if (!signedIn && !onLogin) return redirectTo("/login", request, response);
  if (signedIn && onLogin) return redirectTo("/", request, response);

  return response;
}

// redirect but keep any refreshed session cookies
function redirectTo(path: string, request: NextRequest, from: NextResponse) {
  const url = request.nextUrl.clone();
  url.pathname = path;
  const redirect = NextResponse.redirect(url);
  from.cookies.getAll().forEach((cookie) => redirect.cookies.set(cookie));
  return redirect;
}

// skip next's own files and images, run on everything else
export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)"],
};
