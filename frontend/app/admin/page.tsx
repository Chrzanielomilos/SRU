'use client';
import styles from '../../global_components/page.module.css';
import NavigatorAdmin from '@/global_components/navigator/admin';
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
{<NavigatorAdmin/>}
</header>
<main className={styles.container}>
</main>
</>
);
}