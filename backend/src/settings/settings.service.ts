import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Setting } from './setting.entity';
import { UpdateSettingsDto } from './dto/update-settings.dto';

@Injectable()
export class SettingsService {
  constructor(
    @InjectRepository(Setting) private readonly repo: Repository<Setting>,
  ) {}

  async get(): Promise<Setting> {
    const existing = await this.repo.findOne({ where: { id: 1 } });
    if (existing) return existing;
    await this.repo
      .createQueryBuilder()
      .insert()
      .values({ id: 1 })
      .orIgnore()
      .execute();
    return this.repo.findOneOrFail({ where: { id: 1 } });
  }

  async update(dto: UpdateSettingsDto): Promise<Setting> {
    const settings = await this.get();
    Object.assign(settings, dto);
    return this.repo.save(settings);
  }
}
