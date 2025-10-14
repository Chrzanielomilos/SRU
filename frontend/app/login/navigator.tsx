'use client';
import styles from './page.module.css';
import { usePathname } from 'next/navigation';
import Link from 'next/link';

export default function Navigator() {
  const pathname = usePathname();
  console.log('Current path:', pathname);

  return (
    <nav>
      <ul className={styles.navList}>
        <li>
          <a
            href="https://regulamin.ds.pg.gda.pl"
            target="_blank"
            rel="noopener noreferrer"
          >
            Regulamin
          </a>
        </li>
        <li>
          <Link
            href="/login/user"
            className={pathname === '/login/user' ? styles.active : ''}
          >
            Użytkownik
          </Link>
        </li>
        <li>
          <Link
            href="/login/admin"
            className={pathname === '/login/admin' ? styles.active : ''}
          >
            SKOS
          </Link>
        </li>
        <li>
          <Link
            href="/login/walet"
            className={pathname === '/login/walet' ? styles.active : ''}
          >
            Walet
          </Link>
        </li>
      </ul>
    </nav>
  );
}
