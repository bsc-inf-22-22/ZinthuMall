import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Setting } from './settings.entity';
import { UpdateSettingsDto } from './dto/update-settings.dto'

@Injectable()
export class SettingsService {
  constructor(
    @InjectRepository(Setting)
    private settingsRepo: Repository<Setting>,
  ) {}

  async get(): Promise<Setting> {
    let settings = await this.settingsRepo.findOne({ where: { id: 1 } });

    if (!settings) {
      settings = this.settingsRepo.create({ id: 1 });
      await this.settingsRepo.save(settings);
    }

    return settings;
  }

  async update(dto: UpdateSettingsDto): Promise<Setting> {
    const settings = await this.get();
    Object.assign(settings, dto);
    return this.settingsRepo.save(settings);
  }
}