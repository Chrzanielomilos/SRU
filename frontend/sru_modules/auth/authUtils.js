export function parseErrorMessage(error) {
  if (error.message.includes('failed')) return 'Nieprawidłowe dane logowania.';
  return 'Wystąpił błąd serwera. Spróbuj później.';
}