export type ApiResponse<T> =
  | { success: true; data: T }
  | { success: false; error: string; details?: unknown };

export interface PaginationParams {
  page?: number;
  pageSize?: number;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export interface AnalyticsEventInput {
  tenantId: string;
  locationId?: string;
  menuId?: string;
  menuItemId?: string;
  qrCodeId?: string;
  eventType: string;
  language?: string;
  sessionId?: string;
}
