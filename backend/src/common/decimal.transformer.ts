import { ValueTransformer } from 'typeorm';

/**
 * Postgres returns DECIMAL columns as strings ("4500.00").
 * This converts them to numbers so the API returns 4500.
 */
export const decimalTransformer: ValueTransformer = {
  to: (value?: number | null) => value,
  from: (value?: string | null) =>
    value === null || value === undefined ? value : parseFloat(value),
};
