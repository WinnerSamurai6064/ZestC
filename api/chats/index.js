const { query } = require('../_db');
const { requireAuth, cors } = require('../_auth');

module.exports = async (req, res) => {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();

  const userId = requireAuth(req, res);
  if (!userId) return;

  // GET /api/chats - list all chats for current user
  if (req.method === 'GET') {
    try {
      const result = await query(
        `SELECT
           c.id,
           c.updated_at,
           (
             SELECT json_build_object(
               'id', m.id, 'chat_id', m.chat_id, 'sender_id', m.sender_id,
               'content', m.content, 'image_url', m.image_url,
               'status', m.status, 'is_deleted', m.is_deleted,
               'created_at', m.created_at
             )
             FROM messages m WHERE m.chat_id = c.id
             ORDER BY m.created_at DESC LIMIT 1
           ) AS last_message,
           (
             SELECT COUNT(*) FROM messages m
             WHERE m.chat_id = c.id
               AND m.created_at > cp.last_read_at
               AND m.sender_id != $1
           ) AS unread_count,
           (
             SELECT json_agg(json_build_object(
               'id', u.id, 'username', u.username,
               'display_name', u.display_name, 'avatar_url', u.avatar_url,
               'is_online', u.is_online, 'last_seen', u.last_seen
             ))
             FROM users u
             JOIN chat_participants cp2 ON cp2.user_id = u.id AND cp2.chat_id = c.id
           ) AS participants
         FROM chats c
         JOIN chat_participants cp ON cp.chat_id = c.id AND cp.user_id = $1
         ORDER BY c.updated_at DESC`,
        [userId]
      );
      return res.status(200).json(result.rows);
    } catch (err) {
      console.error(err);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  // POST /api/chats - create or get DM
  if (req.method === 'POST') {
    try {
      const { participant_id } = req.body;
      if (!participant_id) return res.status(400).json({ error: 'participant_id required' });

      // Check if chat already exists between these two users
      const existing = await query(
        `SELECT c.id FROM chats c
         JOIN chat_participants cp1 ON cp1.chat_id = c.id AND cp1.user_id = $1
         JOIN chat_participants cp2 ON cp2.chat_id = c.id AND cp2.user_id = $2
         LIMIT 1`,
        [userId, participant_id]
      );

      let chatId;
      if (existing.rows.length > 0) {
        chatId = existing.rows[0].id;
      } else {
        const newChat = await query(
          'INSERT INTO chats DEFAULT VALUES RETURNING id'
        );
        chatId = newChat.rows[0].id;
        await query(
          'INSERT INTO chat_participants (chat_id, user_id) VALUES ($1, $2), ($1, $3)',
          [chatId, userId, participant_id]
        );
      }

      // Return the chat
      const chat = await query(
        `SELECT
           c.id, c.updated_at,
           (
             SELECT json_agg(json_build_object(
               'id', u.id, 'username', u.username,
               'display_name', u.display_name, 'avatar_url', u.avatar_url,
               'is_online', u.is_online, 'last_seen', u.last_seen
             ))
             FROM users u
             JOIN chat_participants cp2 ON cp2.user_id = u.id AND cp2.chat_id = c.id
           ) AS participants
         FROM chats c WHERE c.id = $1`,
        [chatId]
      );

      return res.status(existing.rows.length > 0 ? 200 : 201).json({
        ...chat.rows[0],
        last_message: null,
        unread_count: 0,
      });
    } catch (err) {
      console.error(err);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
};
