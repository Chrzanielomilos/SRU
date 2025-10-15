'use client';
import styles from '../page.module.css';
import { usePathname } from 'next/navigation';
import Link from 'next/link';
import { setCookie, getCookie, deleteCookie } from "../../utils/cookieUtils";
import {logout} from "../../utils/logout"

export default function NavigatorWalet() {
  const pathname = usePathname();
  console.log('Current path:', pathname);

  return (
    <nav>
      <ul className={styles.navList}>
        <li>
          <Link href="#" onClick={logout}>Wyloguj</Link>
        </li>
      </ul>
    </nav>
  );
}
