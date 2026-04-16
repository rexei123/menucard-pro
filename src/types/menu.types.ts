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
  })[];
};

export type LocationWithMenus = Location & {
  translations: LocationTranslation[];
  menus: MenuWithTranslations[];
};

export type { Menu, MenuTranslation, MenuSection, MenuSectionTranslation } from '@prisma/client';
