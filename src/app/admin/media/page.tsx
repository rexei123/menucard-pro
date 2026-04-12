import { Metadata } from 'next';
import MediaArchive from '@/components/admin/media-archive';

export const metadata: Metadata = { title: 'Bildarchiv – Admin' };

export default function MediaPage() {
  return <MediaArchive />;
}
