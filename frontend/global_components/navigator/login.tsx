'use client';
import styles from '../page.module.css';
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
            href="/user"
            className={pathname === '/user/login' ? styles.active : ''}
          >
            Użytkownik
          </Link>
        </li>
        <li>
          <Link
            href="/admin"
            className={pathname === '/admin/login' ? styles.active : ''}
          >
            SKOS
          </Link>
        </li>
        <li>
          <Link
            href="/walet"
            className={pathname === '/walet/login' ? styles.active : ''}
          >
            Walet
          </Link>
        </li>
      </ul>
    </nav>
  );
}
