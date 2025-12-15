// !!! TUTAJ TRZEBA DODAĆ WERYFIKOWANEI TOKENA Z BACKENDEM
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(req: NextRequest) {
  const url = req.nextUrl.clone();
  const path = url.pathname;

  // 🔓 Ścieżki publiczne (loginy)
  const publicPaths = ["/user/login", "/admin/login", "/walet/login", "/logo.png"];

  // 🔐 Dobierz token w zależności od sekcji
  let tokenName = "";
  if (path.startsWith("/admin")) tokenName = "token_admin";
  else if (path.startsWith("/walet")) tokenName = "token_walet";
  else if (path.startsWith("/user")) tokenName = "token_user";

  const token = tokenName ? req.cookies.get(tokenName)?.value : undefined;

  // ✅ Jeśli użytkownik jest zalogowany i wchodzi na public path — przekieruj na główną stronę sekcji
  if (token && publicPaths.some((p) => path.startsWith(p))) {
    if (path.startsWith("/admin/login")) url.pathname = "/admin";
    else if (path.startsWith("/walet/login")) url.pathname = "/walet";
    else if (path.startsWith("/user/login")) url.pathname = "/user";
    return NextResponse.redirect(url);
  }

  // ✅ Jeśli ścieżka jest publiczna i brak tokena — przepuść
  if (publicPaths.some((p) => path.startsWith(p))) {
    return NextResponse.next();
  }

  // ❌ Jeśli ścieżka chroniona i brak odpowiedniego tokena — przekieruj do loginu danej sekcji
  if (!token) {
    if (path.startsWith("/admin")) url.pathname = "/admin/login";
    else if (path.startsWith("/walet")) url.pathname = "/walet/login";
    else if (path.startsWith("/user")) url.pathname = "/user/login";
    else url.pathname = "/user/login"; // domyślnie dla innych
    return NextResponse.redirect(url);
  }

  // ✅ Inne przypadki (token poprawny, ścieżka chroniona) — przepuść
  return NextResponse.next();
}

// ⚙️ Middleware działa dla wszystkich ścieżek oprócz zasobów statycznych
export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
