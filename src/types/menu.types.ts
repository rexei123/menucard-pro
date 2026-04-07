import type {
  Menu,
  MenuTranslation,
  MenuSection,
  MenuSectionTranslation,
  Location,
  LocationTranslation,
} from '@prisma/client';

export type MenuWithTranslations = Menu & {
  translations: MenuTranslation[];
};

export type MenuWithSections = MenuWithTranslations & {
  sections: (MenuSection & {
    translations: MenuSectionTranslation[];
    items: MenuItemWithDetails[];
  })[];
};

export type LocationWithMenus = Location & {
  translations: LocationTranslation[];
  menus: MenuWithTranslations[];
};

// Re-export for convenience
export type { Menu, MenuTranslation, MenuSection, MenuSectionTranslation } from '@prisma/client';

// Import from item types to avoid circular deps
import type { MenuItemWithDetails } from './item.types';
