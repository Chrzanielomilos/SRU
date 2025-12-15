'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const router = useRouter();

  useEffect(() => {
    router.push('/user/login');
  }, [router]);

  return null; // optional: could also return null if you just want to redirect
}