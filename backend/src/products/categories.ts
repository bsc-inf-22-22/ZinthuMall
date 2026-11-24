/** Category codes stored in the database. Must match the app's AppConstants. */
export const PRODUCT_CATEGORIES = [
  'mens_clothing',
  'womens_clothing',
  'domestics_home',
] as const;
export type ProductCategory = (typeof PRODUCT_CATEGORIES)[number];
