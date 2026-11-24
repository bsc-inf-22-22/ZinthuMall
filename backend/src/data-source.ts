// Used only by the TypeORM CLI (npm run migration:generate / migration:run).
import 'dotenv/config';
import { DataSource } from 'typeorm';
import { buildDataSourceOptions } from './config/database.config';

export default new DataSource(buildDataSourceOptions());
