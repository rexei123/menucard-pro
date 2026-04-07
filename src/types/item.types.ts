import type {
  MenuItem,
  MenuItemTranslation,
  PriceVariant,
  PriceVariantTranslation,
  WineProfile,
  BeverageDetail,
  MenuItemMedia,
  Media,
  Allergen,
  AllergenTranslation,
  Tag,
  TagTranslation,
} from '@prisma/client';

export type MenuItemWithDetails = MenuItem & {
  translations: MenuItemTranslation[];
  priceVariants: (PriceVariant & { translations: PriceVariantTranslation[] })[];
  allergens: {
    allergen: Allergen & { translations: AllergenTranslation[] };
  }[];
  tags: {
    tag: Tag & { translations: TagTranslation[] };
  }[];
  media: (MenuItemMedia & { media: Media })[];
  wineProfile: WineProfile | null;
  beverageDetail: BeverageDetail | null;
};

export type MenuItemListItem = MenuItem & {
  translations: MenuItemTranslation[];
  priceVariants: PriceVariant[];
  section: { translations: { name: string; languageCode: string }[] };
};

export type { MenuItem, MenuItemTranslation, PriceVariant, WineProfile, BeverageDetail } from '@prisma/client';
