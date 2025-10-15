// cookieUtils.ts
// TypeScript helpery do testów (frontend)

type CookieOptions = {
  path?: string;
  domain?: string;
  expires?: Date | number; // Date object or seconds from now
  maxAge?: number; // seconds
  secure?: boolean;
  sameSite?: "Strict" | "Lax" | "None";
};

function serializeOptions(opts: CookieOptions = {}) {
  const parts: string[] = [];

  if (opts.path) parts.push(`Path=${opts.path}`);
  if (opts.domain) parts.push(`Domain=${opts.domain}`);

  if (opts.expires) {
    const d = opts.expires instanceof Date
      ? opts.expires
      : new Date(Date.now() + (typeof opts.expires === "number" ? opts.expires * 1000 : 0));
    parts.push(`Expires=${d.toUTCString()}`);
  }

  if (typeof opts.maxAge === "number") parts.push(`Max-Age=${Math.floor(opts.maxAge)}`);

  if (opts.secure) parts.push("Secure");

  if (opts.sameSite) parts.push(`SameSite=${opts.sameSite}`);

  return parts.length ? "; " + parts.join("; ") : "";
}

/**
 * Ustaw cookie (frontend)
 * @param name nazwa
 * @param value wartość (automatycznie enkodowane)
 * @param opts opcje (path, domain, expires, maxAge, secure, sameSite)
 */
export function setCookie(name: string, value: string, opts?: CookieOptions) {
  const encoded = encodeURIComponent(value);
  const options = serializeOptions(opts);
  // document.cookie dopisuje cookie; format podobny do Set-Cookie ale HttpOnly nie da się ustawić
  document.cookie = `${encodeURIComponent(name)}=${encoded}${options}`;
}

/**
 * Pobierz cookie
 */
export function getCookie(name: string): string | null {
  const encodedName = encodeURIComponent(name) + "=";
  const cookies = document.cookie ? document.cookie.split("; ") : [];
  for (const c of cookies) {
    if (c.startsWith(encodedName)) {
      return decodeURIComponent(c.substring(encodedName.length));
    }
  }
  return null;
}

/**
 * Usuń cookie (ustawiamy expires na przeszłą datę oraz Max-Age=0)
 */
export function deleteCookie(name: string, opts?: { path?: string; domain?: string }) {
  const options: CookieOptions = {
    path: opts?.path ?? "/",
    domain: opts?.domain,
    // ustawiamy datę w przeszłości
    expires: new Date(0),
    maxAge: 0,
  };
  // nadpisujemy cookie aby je usunąć
  setCookie(name, "", options);
}

/**
 * Opcjonalnie: usuń wszystkie cookies (używaj ostrożnie)
 */
export function clearCookies() {
  const cookies = document.cookie ? document.cookie.split("; ") : [];
  for (const c of cookies) {
    const eq = c.indexOf("=");
    const name = eq > -1 ? c.substring(0, eq) : c;
    deleteCookie(decodeURIComponent(name));
  }
}
