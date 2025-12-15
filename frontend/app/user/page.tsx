'use client';
import styles from '../../global_components/page.module.css';
import NavigatorUser from '@/global_components/navigator/user';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function UserMain() {

const router = useRouter();

return (
<>
<header className={styles.header}>
<div className={styles.logo}>
    <img src="/logo.png" alt="" />
    SRU
</div>
{<NavigatorUser/>}
</header>
<main className={styles.container}>
</main>
</>
);
}