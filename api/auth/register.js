const bcrypt = require('bcryptjs');
const { query, initDb } = require('../_db');
const { signToken, cors } = require('../_auth');

module.exports = async (req, res) => {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  try {
    await initDb();
    const { username, display_name, password } = req.body;

    if (!username || !display_name || !password) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    if (username.length < 3 || username.length > 50) {
      return res.status(400).json({ error: 'Username must be 3-50 chars' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 chars' });
    }

    const existing = await query('SELECT id FROM users WHERE username = $1', [username.toLowerCase()]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'Username already taken' });
    }

    const hash = await bcrypt.hash(password, 10);
    const result = await query(
      `INSERT INTO users (username, display_name, password_hash)
       VALUES ($1, $2, $3) RETURNING id, username, display_name, avatar_url, bio, is_online, last_seen, created_at`,
      [username.toLowerCase(), display_name, hash]
    );

    const user = result.rows[0];
    const token = signToken(user.id);

    return res.status(201).json({ token, user: formatUser(user) });
  } catch (err) {
    console.error('Register error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

function formatUser(u) {
  return {
    id: u.id,
    username: u.username,
    display_name: u.display_name,
    avatar_url: u.avatar_url,
    bio: u.bio,
    is_online: u.is_online,
    last_seen: u.last_seen,
  };
}
