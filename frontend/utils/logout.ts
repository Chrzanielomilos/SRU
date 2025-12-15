import { setCookie, getCookie, deleteCookie } from "./cookieUtils";

export function logout(){
  if(window.location.pathname.startsWith("/user")){
    deleteCookie("token_user");
    window.location.href="/user/login";
  }else
  if(window.location.pathname.startsWith("/admin")){
    deleteCookie("token_admin");
    window.location.href="/admin/login";
  }else
  if(window.location.pathname.startsWith("/walet")){
    deleteCookie("token_walet");
    window.location.href="/walet/login";
  }
}