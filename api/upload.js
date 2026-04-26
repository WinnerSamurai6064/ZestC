const { requireAuth, cors } = require('../_auth');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { IncomingForm } = require('formidable');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Disable body parsing so formidable can handle it
export const config = { api: { bodyParser: false } };

const s3 = new S3Client({
  region: 'auto',
  endpoint: process.env.STORAGE_ENDPOINT,
  credentials: {
    accessKeyId: process.env.STORAGE_KEY,
    secretAccessKey: process.env.STORAGE_SECRET,
  },
});

module.exports = async (req, res) => {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const userId = requireAuth(req, res);
  if (!userId) return;

  try {
    const form = new IncomingForm({ maxFileSize: 10 * 1024 * 1024 });
    const [, files] = await new Promise((resolve, reject) => {
      form.parse(req, (err, fields, files) => {
        if (err) reject(err);
        else resolve([fields, files]);
      });
    });

    const file = Array.isArray(files.file) ? files.file[0] : files.file;
    if (!file) return res.status(400).json({ error: 'No file uploaded' });

    const ext = path.extname(file.originalFilename || '.jpg');
    const key = `uploads/${userId}/${uuidv4()}${ext}`;
    const fileBuffer = fs.readFileSync(file.filepath);

    await s3.send(new PutObjectCommand({
      Bucket: process.env.STORAGE_BUCKET,
      Key: key,
      Body: fileBuffer,
      ContentType: file.mimetype || 'image/jpeg',
      ACL: 'public-read',
    }));

    const url = `${process.env.STORAGE_ENDPOINT}/${process.env.STORAGE_BUCKET}/${key}`;
    return res.status(200).json({ url });
  } catch (err) {
    console.error('Upload error:', err);
    return res.status(500).json({ error: 'Upload failed' });
  }
};
