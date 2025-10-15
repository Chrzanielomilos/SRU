'use client';
import styles from '../page.module.css';
import { usePathname } from 'next/navigation';
import Link from 'next/link';
import { setCookie, getCookie, deleteCookie } from "../../utils/cookieUtils";
import {logout} from "../../utils/logout"

export default function NavigatorAdmin() {
  const pathname = usePathname();
  console.log('Current path:', pathname);

  return (
    <nav>
      <ul className={styles.navList}>
        <li>
          <Link
            href="/admin"
            className={pathname === '/search' ? styles.active : ''}
          >
            Wyszukiwanie
          </Link>
        </li>
        <li>
          <Link
            href="/admin/tasks"
            className={pathname === '/admin/tasks' ? styles.active : ''}
          >
            Zadania
          </Link>
        </li>
        <li>
          <Link
            href="/admin/penalties"
            className={pathname === '/admin/penalties' ? styles.active : ''}
          >
            Kary
          </Link>
        </li>
        <li>
          <Link
            href="/admin/dorms"
            className={pathname === '/admin/dorms' ? styles.active : ''}
          >
            Akademiki
          </Link>
        </li>
        <li>
          <Link
            href="/admin/stats"
            className={pathname === '/admin/stats' ? styles.active : ''}
          >
            Statystyki
          </Link>
        </li>
        <li>
          <Link
            href="/admin/admins"
            className={pathname === '/admin/admins' ? styles.active : ''}
          >
            Administratorzy
          </Link>
        </li>
        <li>
          <Link href="#" onClick={logout}>Wyloguj</Link>
        </li>
      </ul>
    </nav>
  );
}
