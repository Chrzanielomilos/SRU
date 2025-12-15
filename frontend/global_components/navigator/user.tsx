'use client';
import styles from '../page.module.css';
import { usePathname } from 'next/navigation';
import Link from 'next/link';
import { setCookie, getCookie, deleteCookie } from "../../utils/cookieUtils";
import {logout} from "../../utils/logout"

export default function NavigatorUser() {
  const pathname = usePathname();
  console.log('Current path:', pathname);

  return (
    <nav>
      <ul className={styles.navList}>
        <li>
          <Link
            href="/user"
            className={pathname === '/user' ? styles.active : ''}
          >
            Główna
          </Link>
        </li>
        <li>
          <Link
            href="/user/account"
            className={pathname === '/user/account' ? styles.active : ''}
          >
            Profil
          </Link>
        </li>
        <li>
          <Link
            href="/user/computers"
            className={pathname === '/user/computers' ? styles.active : ''}
          >
            Komputery
          </Link>
        </li>
        <li>
          <Link href="#" onClick={logout}>Wyloguj</Link>
        </li>
      </ul>
    </nav>
  );
}
