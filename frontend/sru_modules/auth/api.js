export async function loginRequest(email, password) {
  const res = await fetch('http://localhost:8000/api/auth/token/', {
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
