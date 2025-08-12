import { createContext, useState, useEffect, useContext } from 'react';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [authenticated, setAuthenticated] = useState(false);

  useEffect(() => {
    async function checkAuth() {
      const res = await fetch('http://localhost:51135/api/check-auth/', { // TODO: zamienić porty
        credentials: 'include',
      });
      setAuthenticated(res.ok);
    }
    checkAuth();
  }, []);

  const logout = async () => {
    await fetch('http://localhost:51135/api/auth/logout/', { // TODO: zamienić porty
      method: 'POST',
      credentials: 'include',
    });
    setAuthenticated(false);
  };

  return (
    <AuthContext.Provider value={{ authenticated, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
