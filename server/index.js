import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import fetch from 'node-fetch';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY || '';
const OPENROUTER_MODEL = process.env.OPENROUTER_MODEL || 'google/gemini-2.0-flash-exp:free';

app.use(cors());
app.use(express.json());

// Health Check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Focus Clock AI Time Secretary (Aura)',
    openRouterConfigured: OPENROUTER_API_KEY.length > 0,
    timestamp: new Date().toISOString(),
  });
});

// AI Secretary Chat Endpoint
app.post('/api/chat/secretary', async (req, res) => {
  try {
    const { messages, userMessage } = req.body;

    if (!OPENROUTER_API_KEY) {
      return res.json({
        reply: 'Server Backend OpenRouter siap! Silakan tambahkan OPENROUTER_API_KEY pada file .env di server.',
        mode: 'server_pending_key',
      });
    }

    const currentDatetime = new Date().toLocaleString('id-ID', { timeZoneName: 'short' });

    // Persona "Aura" System Prompt
    const systemPrompt = `Kamu adalah "Aura", seorang AI Time Secretary yang sangat empatik, hangat, efisien, dan ramah.

ATURAN PERILAKU:
1. Bersikap profesional namun hangat seperti sekretaris pribadi manusia sungguhan.
2. Selalu sadar konteks waktu pengguna saat ini: ${currentDatetime}.
3. Buat respon yang ringkas, jelas, dan langsung pada poin utama (maksimal 2-3 kalimat).
4. Proaktif memberikan perhatian kecil terkait manajemen waktu, jam istirahat, atau pengingat jadwal jika diperlukan.`;

    const requestMessages = messages && messages.length > 0
      ? messages
      : [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userMessage || 'Halo Aura' },
        ];

    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'HTTP-Referer': 'https://focusclock.app',
        'X-Title': 'Focus Clock Aura AI',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: OPENROUTER_MODEL,
        messages: requestMessages,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      return res.status(response.status).json({ error: `OpenRouter Error: ${errText}` });
    }

    const data = await response.json();
    const reply = data.choices?.[0]?.message?.content || 'Aura siap mendampingi waktu Anda.';

    return res.json({
      reply,
      mode: 'server_openrouter',
    });
  } catch (error) {
    console.error('Server error:', error);
    return res.status(500).json({ error: error.message || 'Internal Server Error' });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Focus Clock Backend Server (Aura AI) running on port ${PORT}`);
  console.log(`👉 Endpoint: http://localhost:${PORT}/api/chat/secretary`);
});
