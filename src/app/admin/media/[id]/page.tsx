import MediaDetail from '@/components/admin/media-detail';

export default function MediaDetailPage({ params }: { params: { id: string } }) {
  return <MediaDetail mediaId={params.id} />;
}
