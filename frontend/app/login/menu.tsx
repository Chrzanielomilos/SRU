import styles from './page.module.css';

export default function Navigator() {
return (
<nav>
<ul className={styles.navList}>
<li><a href="#">Regulamin</a></li>
<li><a href="#">Użytkownik</a></li>
<li><a href="#">SKOS</a></li>
<li><a href="walet">Walet</a></li>
</ul>
</nav>
);
}