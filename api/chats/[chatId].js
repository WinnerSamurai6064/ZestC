const { query } = require('../../_db');
const { requireAuth, cors } = require('../../_auth');

module.exports = async (req, res) => {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();

  const userId = requireAuth(req, res);
  if (!userId) return;

  const { chatId } = req.query;

  // Verify membership
  const member = await query(
    'SELECT 1 FROM chat_participants WHERE chat_id = $1 AND user_id = $2',
    [chatId, userId]
  );
  if (member.rows.length === 0) {
    return res.status(403).json({ error: 'Not a participant' });
  }

  // GET messages
  if (req.method === 'GET') {
    const page = parseInt(req.query.page || '1');
    const limit = parseInt(req.query.limit || '50');
    const offset = (page - 1) * limit;
    try {
      const result = await query(
        `SELECT id, chat_id, sender_id, content, image_url, status, is_deleted, created_at
         FROM messages WHERE chat_id = $1
         ORDER BY created_at ASC
         LIMIT $2 OFFSET $3`,
        [chatId, limit, offset]
      );
      return res.status(200).json(result.rows);
    } catch (err) {
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  // POST send message
  if (req.method === 'POST') {
    const { content, image_url } = req.body;
    if (!content && !image_url) {
      return res.status(400).json({ error: 'content or image_url required' });
    }
    try {
      const result = await query(
        `INSERT INTO messages (chat_id, sender_id, content, image_url, status)
         VALUES ($1, $2, $3, $4, 'sent')
         RETURNING id, chat_id, sender_id, content, image_url, status, is_deleted, created_at`,
        [chatId, userId, content || null, image_url || null]
      );
      // Update chat updated_at
      await query('UPDATE chats SET updated_at = NOW() WHERE id = $1', [chatId]);
      return res.status(201).json(result.rows[0]);
    } catch (err) {
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  // PATCH /api/chats/[chatId]/read
  if (req.method === 'PATCH') {
    try {
      await query(
        'UPDATE chat_participants SET last_read_at = NOW() WHERE chat_id = $1 AND user_id = $2',
        [chatId, userId]
      );
      // Mark messages as read
      await query(
        `UPDATE messages SET status = 'read'
         WHERE chat_id = $1 AND sender_id != $2 AND status != 'read'`,
        [chatId, userId]
      );
      return res.status(200).json({ ok: true });
    } catch (err) {
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
};
