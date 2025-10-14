'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Login from './user/page';

export default function LoginPage() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to /admin when the component mounts
    router.push('/login/user');
  }, [router]);

  return <Login />; // optional: could also return null if you just want to redirect
}