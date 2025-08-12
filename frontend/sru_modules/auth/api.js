export async function loginRequest(email, password) {
  const res = await fetch('http://localhost:51135/api/auth/token/', { // TODO: zamienić porty
    method: 'POST',
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    throw new Error('Login failed');
  }
  return res.json();
}
