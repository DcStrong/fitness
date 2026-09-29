/**
 * Platform example — request DTO с вложенной валидацией.
 */
export class CreateItemRequestDto implements Api.CreateItem.RequestBody {
  @IsString()
  name!: string;

  @IsOptional()
  @IsString()
  owner_key?: string;

  @ValidateNested()
  @Type(() => ItemPayloadDto)
  payload!: ItemPayloadDto;
}

class ItemPayloadDto {
  @IsDefined()
  @IsEnum(ItemType)
  type!: ItemType;
}
