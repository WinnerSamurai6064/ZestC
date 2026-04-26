const { query } = require('../_db');
const { requireAuth, cors } = require('../_auth');

module.exports = async (req, res) => {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();

  const userId = requireAuth(req, res);
  if (!userId) return;

  // PATCH /api/users/me
  if (req.method === 'PATCH') {
    try {
      const { display_name, bio, avatar_url } = req.body;
      const result = await query(
        `UPDATE users SET
          display_name = COALESCE($1, display_name),
          bio = COALESCE($2, bio),
          avatar_url = COALESCE($3, avatar_url)
         WHERE id = $4
         RETURNING id, username, display_name, avatar_url, bio, is_online, last_seen`,
        [display_name || null, bio || null, avatar_url || null, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });
      return res.status(200).json(formatUser(result.rows[0]));
    } catch (err) {
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  // GET /api/users/search?q=
  if (req.method === 'GET') {
    const q = req.query?.q || '';
    if (!q || q.length < 1) return res.status(200).json([]);
    try {
      const result = await query(
        `SELECT id, username, display_name, avatar_url, bio, is_online, last_seen
         FROM users
         WHERE (username ILIKE $1 OR display_name ILIKE $1)
           AND id != $2
         LIMIT 20`,
        [`%${q}%`, userId]
      );
      return res.status(200).json(result.rows.map(formatUser));
    } catch (err) {
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
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
