import sharp from 'sharp';
import { mkdir } from 'node:fs/promises';

await mkdir('frontend/public/assets', { recursive: true });
const source = sharp('assets/src/evidence-rail-hero.png');
await source.clone().resize(1280, 853, { fit: 'cover' }).webp({ quality: 76 }).toFile('frontend/public/assets/evidence-rail-hero.webp');
await source.clone().resize(768, 512, { fit: 'cover' }).webp({ quality: 72 }).toFile('frontend/public/assets/evidence-rail-hero-768.webp');
await source.clone().resize(1200, 630, { fit: 'cover', position: 'attention' }).webp({ quality: 78 }).toFile('frontend/public/assets/social-card.webp');
await source.clone().resize(180, 180, { fit: 'cover', position: 'attention' }).png({ quality: 90 }).toFile('frontend/public/apple-touch-icon.png');
