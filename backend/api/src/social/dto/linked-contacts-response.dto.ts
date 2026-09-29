import type { LinkedContactsModel } from '../interface';

export class LinkedContactsResponseDto implements LinkedContactsModel {
  userId: string;

  phone: string | null;

  telegramUsername: string | null;

  email: string;

  preferredContactChannels: LinkedContactsModel['preferredContactChannels'];

  constructor(contacts: LinkedContactsModel) {
    this.userId = contacts.userId;
    this.phone = contacts.phone;
    this.telegramUsername = contacts.telegramUsername;
    this.email = contacts.email;
    this.preferredContactChannels = contacts.preferredContactChannels;
  }
}
