#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Phase 1: Product Database Schema ==="

echo "1/3 Backing up..."
cp prisma/schema.prisma prisma/schema.prisma.bak
pg_dump "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" > /root/menucard-pre-products.sql

echo "2/3 Modifying Prisma schema..."

python3 << 'PYEOF'
import re

with open('prisma/schema.prisma', 'r') as f:
    content = f.read()

# 1. Add relations to Tenant (after "tags      Tag[]")
content = content.replace(
    '  tags      Tag[]\n}',
    '  tags      Tag[]\n  productGroups    ProductGroup[]\n  products         Product[]\n  priceLevels      PriceLevel[]\n  fillQuantities   FillQuantity[]\n  taxRates         TaxRate[]\n  suppliers        Supplier[]\n  customFieldDefs  CustomFieldDefinition[]\n}',
    1
)

# 2. Add placements to MenuSection (after "items        MenuItem[]")
content = content.replace(
    '  items        MenuItem[]\n\n  @@unique([menuId, slug])',
    '  items        MenuItem[]\n  placements       MenuPlacement[]\n\n  @@unique([menuId, slug])',
    1
)

# 3. Add productAllergens to Allergen (after first "menuItems    MenuItemAllergen[]")
content = content.replace(
    '  menuItems    MenuItemAllergen[]\n\n  @@unique([tenantId, code])\n}\n\nmodel AllergenTranslation',
    '  menuItems    MenuItemAllergen[]\n  productAllergens ProductAllergen[]\n\n  @@unique([tenantId, code])\n}\n\nmodel AllergenTranslation',
    1
)

# 4. Add productTags to Tag (after "menuItems    MenuItemTag[]")
content = content.replace(
    '  menuItems    MenuItemTag[]\n\n  @@unique([tenantId, slug])\n}\n\nmodel TagTranslation',
    '  menuItems    MenuItemTag[]\n  productTags      ProductTag[]\n\n  @@unique([tenantId, slug])\n}\n\nmodel TagTranslation',
    1
)

# 5. Add productMedia to Media (after "menuItems   MenuItemMedia[]")
content = content.replace(
    '  menuItems   MenuItemMedia[]\n}',
    '  menuItems   MenuItemMedia[]\n  productMedia     ProductMedia[]\n}',
    1
)

with open('prisma/schema.prisma', 'w') as f:
    f.write(content)

print("Relations added to existing models")
PYEOF

# Now append new models
cat >> prisma/schema.prisma << 'ENDSCHEMA'

// ============================================
// CENTRAL PRODUCT DATABASE
// ============================================

model ProductGroup {
  id               String   @id @default(cuid())
  tenantId         String
  tenant           Tenant   @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  parentId         String?
  parent           ProductGroup?  @relation("GroupTree", fields: [parentId], references: [id])
  children         ProductGroup[] @relation("GroupTree")
  slug             String
  icon             String?
  image            String?
  defaultTaxRateId String?
  defaultTaxRate   TaxRate? @relation("GroupDefaultTax", fields: [defaultTaxRateId], references: [id])
  sortOrder        Int      @default(0)
  isActive         Boolean  @default(true)
  createdAt        DateTime @default(now())
  updatedAt        DateTime @updatedAt
  translations     ProductGroupTranslation[]
  products         Product[]
  @@unique([tenantId, slug])
}

model ProductGroupTranslation {
  id              String       @id @default(cuid())
  productGroupId  String
  productGroup    ProductGroup @relation(fields: [productGroupId], references: [id], onDelete: Cascade)
  languageCode    String
  name            String
  description     String?
  @@unique([productGroupId, languageCode])
}

enum ProductType {
  WINE
  DRINK
  FOOD
  OTHER
}

enum ProductStatus {
  ACTIVE
  SOLD_OUT
  ARCHIVED
  DRAFT
}

model Product {
  id              String        @id @default(cuid())
  tenantId        String
  tenant          Tenant        @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  productGroupId  String?
  productGroup    ProductGroup? @relation(fields: [productGroupId], references: [id])
  sku             String?
  type            ProductType
  status          ProductStatus @default(ACTIVE)
  taxRateId       String?
  taxRate         TaxRate?      @relation("ProductTax", fields: [taxRateId], references: [id])
  supplierId      String?
  supplier        Supplier?     @relation(fields: [supplierId], references: [id])
  isHighlight     Boolean       @default(false)
  highlightType   HighlightType?
  sortOrder       Int           @default(0)
  customFields    Json?
  internalNotes   String?
  createdAt       DateTime      @default(now())
  updatedAt       DateTime      @updatedAt
  translations       ProductTranslation[]
  prices             ProductPrice[]
  productAllergens   ProductAllergen[]
  productTags        ProductTag[]
  productMedia       ProductMedia[]
  productWineProfile ProductWineProfile?
  productBevDetail   ProductBeverageDetail?
  placements         MenuPlacement[]
  customFieldValues  ProductCustomFieldValue[]
  pairingsFrom       ProductPairing[] @relation("ProdPairSource")
  pairingsTo         ProductPairing[] @relation("ProdPairTarget")
  @@unique([tenantId, sku])
}

model ProductTranslation {
  id                String  @id @default(cuid())
  productId         String
  product           Product @relation(fields: [productId], references: [id], onDelete: Cascade)
  languageCode      String
  name              String
  shortDescription  String?
  longDescription   String?
  servingSuggestion String?
  internalNotes     String?
  @@unique([productId, languageCode])
}

model PriceLevel {
  id               String   @id @default(cuid())
  tenantId         String
  tenant           Tenant   @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  name             String
  slug             String
  isInternal       Boolean  @default(false)
  surchargePercent Float?
  sortOrder        Int      @default(0)
  isActive         Boolean  @default(true)
  createdAt        DateTime @default(now())
  updatedAt        DateTime @updatedAt
  prices           ProductPrice[]
  placements       MenuPlacement[]
  @@unique([tenantId, slug])
}

model FillQuantity {
  id        String   @id @default(cuid())
  tenantId  String
  tenant    Tenant   @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  label     String
  volume    String?
  sortOrder Int      @default(0)
  isActive  Boolean  @default(true)
  prices     ProductPrice[]
  placements MenuPlacement[]
  @@unique([tenantId, label])
}

model ProductPrice {
  id             String       @id @default(cuid())
  productId      String
  product        Product      @relation(fields: [productId], references: [id], onDelete: Cascade)
  fillQuantityId String
  fillQuantity   FillQuantity @relation(fields: [fillQuantityId], references: [id])
  priceLevelId   String
  priceLevel     PriceLevel   @relation(fields: [priceLevelId], references: [id])
  price          Decimal      @db.Decimal(10, 2)
  purchasePrice  Decimal?     @db.Decimal(10, 2)
  fixedMarkup    Decimal?     @db.Decimal(10, 2)
  percentMarkup  Float?
  currency       String       @default("EUR")
  isDefault      Boolean      @default(false)
  sortOrder      Int          @default(0)
  @@unique([productId, fillQuantityId, priceLevelId])
}

model TaxRate {
  id        String   @id @default(cuid())
  tenantId  String
  tenant    Tenant   @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  name      String
  rate      Float
  isDefault Boolean  @default(false)
  isActive  Boolean  @default(true)
  productGroups ProductGroup[] @relation("GroupDefaultTax")
  products      Product[]      @relation("ProductTax")
  @@unique([tenantId, name])
}

model Supplier {
  id          String   @id @default(cuid())
  tenantId    String
  tenant      Tenant   @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  name        String
  slug        String
  contactName String?
  email       String?
  phone       String?
  website     String?
  address     String?
  notes       String?
  isActive    Boolean  @default(true)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  products    Product[]
  @@unique([tenantId, slug])
}

enum CustomFieldType {
  TEXT
  NUMBER
  BOOLEAN
  SELECT
  DATE
  URL
}

model CustomFieldDefinition {
  id             String          @id @default(cuid())
  tenantId       String
  tenant         Tenant          @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  fieldKey       String
  fieldType      CustomFieldType @default(TEXT)
  isPublic       Boolean         @default(false)
  isFilterable   Boolean         @default(false)
  isRequired     Boolean         @default(false)
  selectOptions  String[]
  appliesToType  ProductType?
  sortOrder      Int             @default(0)
  isActive       Boolean         @default(true)
  translations   CustomFieldTranslation[]
  values         ProductCustomFieldValue[]
  @@unique([tenantId, fieldKey])
}

model CustomFieldTranslation {
  id                      String                @id @default(cuid())
  customFieldDefinitionId String
  customFieldDefinition   CustomFieldDefinition @relation(fields: [customFieldDefinitionId], references: [id], onDelete: Cascade)
  languageCode            String
  label                   String
  placeholder             String?
  helpText                String?
  @@unique([customFieldDefinitionId, languageCode])
}

model ProductCustomFieldValue {
  id                      String                @id @default(cuid())
  productId               String
  product                 Product               @relation(fields: [productId], references: [id], onDelete: Cascade)
  customFieldDefinitionId String
  customFieldDefinition   CustomFieldDefinition @relation(fields: [customFieldDefinitionId], references: [id], onDelete: Cascade)
  value                   String
  @@unique([productId, customFieldDefinitionId])
}

enum ProductMediaType {
  LABEL
  BOTTLE
  SERVING
  AMBIANCE
  LOGO
  DOCUMENT
  OTHER
}

model ProductMedia {
  id        String           @id @default(cuid())
  productId String
  product   Product          @relation(fields: [productId], references: [id], onDelete: Cascade)
  mediaId   String?
  media     Media?           @relation(fields: [mediaId], references: [id])
  mediaType ProductMediaType @default(OTHER)
  url       String?
  alt       String?
  sortOrder Int              @default(0)
  isPrimary Boolean          @default(false)
}

model ProductAllergen {
  productId  String
  product    Product  @relation(fields: [productId], references: [id], onDelete: Cascade)
  allergenId String
  allergen   Allergen @relation(fields: [allergenId], references: [id], onDelete: Cascade)
  @@id([productId, allergenId])
}

model ProductTag {
  productId String
  product   Product @relation(fields: [productId], references: [id], onDelete: Cascade)
  tagId     String
  tag       Tag     @relation(fields: [tagId], references: [id], onDelete: Cascade)
  @@id([productId, tagId])
}

model ProductWineProfile {
  id              String        @id @default(cuid())
  productId       String        @unique
  product         Product       @relation(fields: [productId], references: [id], onDelete: Cascade)
  winery          String?
  vintage         Int?
  grapeVarieties  String[]
  region          String?
  country         String?
  appellation     String?
  style           WineStyle?
  body            WineBody?
  sweetness       WineSweetness?
  bottleSize      String?       @default("0.75l")
  alcoholContent  Float?
  servingTemp     String?
  tastingNotes    String?
  foodPairing     String?
  stockQuantity   Int?
  internalNotes   String?
}

model ProductBeverageDetail {
  id             String            @id @default(cuid())
  productId      String            @unique
  product        Product           @relation(fields: [productId], references: [id], onDelete: Cascade)
  brand          String?
  producer       String?
  category       BeverageCategory?
  alcoholContent Float?
  servingTemp    String?
  carbonated     Boolean           @default(false)
  origin         String?
}

model ProductPairing {
  id       String      @id @default(cuid())
  sourceId String
  source   Product     @relation("ProdPairSource", fields: [sourceId], references: [id], onDelete: Cascade)
  targetId String
  target   Product     @relation("ProdPairTarget", fields: [targetId], references: [id], onDelete: Cascade)
  type     PairingType @default(GOES_WELL)
  @@unique([sourceId, targetId])
}

model MenuPlacement {
  id             String        @id @default(cuid())
  menuSectionId  String
  menuSection    MenuSection   @relation(fields: [menuSectionId], references: [id], onDelete: Cascade)
  productId      String
  product        Product       @relation(fields: [productId], references: [id], onDelete: Cascade)
  priceLevelId   String?
  priceLevel     PriceLevel?   @relation(fields: [priceLevelId], references: [id])
  fillQuantityId String?
  fillQuantity   FillQuantity? @relation(fields: [fillQuantityId], references: [id])
  priceOverride  Decimal?      @db.Decimal(10, 2)
  sortOrder      Int           @default(0)
  isVisible      Boolean       @default(true)
  highlightType  HighlightType?
  notes          String?
  createdAt      DateTime      @default(now())
  updatedAt      DateTime      @updatedAt
  @@unique([menuSectionId, productId])
}
ENDSCHEMA

echo "3/3 Running Prisma..."
npx prisma generate
npx prisma db push

npm run build && pm2 restart menucard-pro

echo ""
echo "=== Schema deployed! ==="
echo "Nächster Schritt: psql ... -f seed-product-base.sql"
