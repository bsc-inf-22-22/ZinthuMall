import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { SettingsService } from './settings.service';
import { UpdateSettingsDto } from './dto/update-settings.dto';
import { AdminGuard } from '../auth/guards';

@Controller()
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  /** Public: the app reads delivery fee, threshold and store contact details. */
  @Get('settings')
  getPublic() {
    return this.settingsService.get();
  }

  @UseGuards(AdminGuard)
  @Get('admin/settings')
  get() {
    return this.settingsService.get();
  }

  @UseGuards(AdminGuard)
  @Patch('admin/settings')
  update(@Body() dto: UpdateSettingsDto) {
    return this.settingsService.update(dto);
  }
}
