'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Login from './login/user/page';

export default function LoginPage() {
  const router = useRouter();

  const loggedIn:boolean=false;
  if(!loggedIn){
    useEffect(() => {
    router.push('/login/user');
  }, [router]);
  }

  return (
    <div>
      Hello
    </div>
  ); // optional: could also return null if you just want to redirect
}