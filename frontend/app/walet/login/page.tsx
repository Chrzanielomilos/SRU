'use client';
import { useState } from 'react';
import { loginRequest } from '../../../sru_modules/auth/api';
import { parseErrorMessage } from '../../../sru_modules/auth/authUtils';
import { useRouter } from 'next/navigation';
import styles from '../../../global_components/page.module.css';
import Information from '../../../global_components/information';
import Navigator from '../../../global_components/navigator/login';
import { setCookie, getCookie, deleteCookie } from "../../../utils/cookieUtils";

export default function LoginPage() {
const [email, setEmail] = useState('');
const [password, setPassword] = useState('');
const [errorMsg, setErrorMsg] = useState('');
const router = useRouter();

const handleSubmit = async (e: { preventDefault: () => void; }) => {
    e.preventDefault();
    try {
        await loginRequest(email, password);
        router.push('/dashboard');
    } catch (err) {
        //setErrorMsg(parseErrorMessage(err));
        // ===== TEMP =====
        setCookie("token_walet", "testowy-jwt-key", {
            maxAge: 3600,
            path: "/",
            sameSite: "Strict",
            secure: false,
        });
        window.location.href="/walet";
        // ================
    }
};

return (
<>
<header className={styles.header}>
<div className={styles.logo}>
    <img src="/logo.png" alt="" />
    SRU
</div>
{<Navigator/>}
</header>

<main className={styles.container}>
<section className={styles.infoSection}>
{<Information/>}
</section>

<section className={styles.formSection}>
<form onSubmit={handleSubmit} className={styles.form}>
<h2>Walet</h2>
<input
type="text"
placeholder="Login"
value={email}
onChange={(e) => setEmail(e.target.value)}
required
/>
<input
type="password"
placeholder="Hasło"
value={password}
onChange={(e) => setPassword(e.target.value)}
required
/>
<button type="submit">Zaloguj się</button>
{errorMsg && <p className={styles.errorMsg}>{errorMsg}</p>}
</form>
</section>
</main>
</>
);
}