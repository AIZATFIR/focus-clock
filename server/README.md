# Focus Clock Backend Server (Aura AI - OpenRouter)

Backend server Express.js untuk menangani Fallback Mode (Mode 2) AI Time Secretary **Aura** melalui OpenRouter API.

## Cara menjalankan:
1. Pindah ke direktori `server`:
   ```bash
   cd server
   ```
2. Install dependensi:
   ```bash
   npm install
   ```
3. Buat file `.env` dari `.env.example`:
   ```bash
   cp .env.example .env
   ```
4. Masukkan `OPENROUTER_API_KEY` Anda di file `.env`.
5. Jalankan server:
   ```bash
   npm start
   ```

Server akan aktif di `http://localhost:3000/api/chat/secretary` dan siap melayani request dari aplikasi Flutter Focus Clock.
