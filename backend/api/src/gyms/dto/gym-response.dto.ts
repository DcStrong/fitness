import type { GymModel } from '../interface';

export class GymResponseDto {
  id: string;

  name: string;

  address: string;

  city: string;

  district: string | null;

  constructor(gym: GymModel) {
    this.id = gym.id;
    this.name = gym.name;
    this.address = gym.address;
    this.city = gym.city;
    this.district = gym.district;
  }
}
