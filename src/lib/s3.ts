export function getMediaUrl(key: string): string {
  return `${process.env.S3_ENDPOINT}/${process.env.S3_BUCKET}/${key}`;
}
